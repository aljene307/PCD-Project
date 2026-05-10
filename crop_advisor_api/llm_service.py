from dotenv import load_dotenv
load_dotenv()

import os
import json
from groq import AsyncGroq
from models import (
    CropRecommendationInput,
    EnrichedResponse,
    EnrichedRecommendation,
    EnrichedFeature,
    EnrichedCounterfactual,
    EnrichedWarning,
    SoilProfile,
    ClimateProfile,
)
from rag_service import build_full_rag_context

GROQ_API_KEY = "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"
MODEL = "llama-3.3-70b-versatile"

SUITABILITY_LABELS = {
    "S1": "Highly Suitable",
    "S2": "Moderately Suitable",
    "S3": "Marginally Suitable",
    "N":  "Unsuitable",
}

def confidence_label(score: float) -> str:
    if score >= 0.80:
        return "High"
    elif score >= 0.60:
        return "Moderate"
    else:
        return "Low"


def build_prompt(payload: CropRecommendationInput, rag_context: str) -> str:
    f    = payload.input_features
    recs = payload.recommendations
    warns = payload.warnings

    return f"""
You are an expert agronomist assistant trained on AEZ/GAEZ methodology and crop science.
Use the KNOWLEDGE BASE below to ground your explanations in real agronomic facts.
Do NOT invent facts — if the knowledge base covers a crop, cite specific figures from it.

{rag_context}

=== ML MODEL OUTPUT TO EXPLAIN ===

## Input Features (measured at the field)
- Soil pH: {f.ph}
- Nitrogen: {f.nitrogen_ppm} ppm
- Phosphorus: {f.phosphorus_ppm} ppm
- Potassium: {f.potassium_ppm} ppm
- Organic Matter: {f.organic_matter_pct}%
- Soil Texture: {f.texture_class}
- Annual Rainfall: {f.annual_rainfall_mm} mm
- Average Temperature: {f.avg_temp_c}°C
- Growing Season: {f.growing_season_days} days
- Slope: {f.slope_pct}%
- Elevation: {f.elevation_m} m

## Top Recommendations
{json.dumps([r.model_dump() for r in recs], indent=2)}

## Warnings
{json.dumps([w.model_dump() for w in warns], indent=2)}

---

Using BOTH the knowledge base above AND the ML output, respond ONLY with a valid JSON object
(no markdown, no backticks, no extra text) with this exact structure:

{{
  "overall_narrative": "<1 concise paragraph, 3-4 sentences — reference specific crop requirements from the knowledge base>",
  "soil_profile": {{
    "headline": "<5-8 word headline>",
    "description": "<2-3 sentences — compare measured soil values to optimal ranges from the knowledge base>"
  }},
  "climate_profile": {{
    "headline": "<5-8 word headline>",
    "description": "<2-3 sentences — compare measured climate values to crop requirements from the knowledge base>"
  }},
  "recommendations": [
    {{
      "rank": <int>,
      "short_summary": "<1-2 sentence summary — include 1 specific fact from the knowledge base>",
      "detailed_explanation": "<2-3 paragraphs — explain WHY this crop fits or doesn't fit using knowledge base figures for temperature, rainfall, pH, cycle length, and notes>",
      "top_features": [
        {{"label": "<exact label from input>", "explanation": "<1 sentence referencing knowledge base optimal range>"}}
      ],
      "counterfactuals": [
        {{"label": "<exact label from input>", "explanation": "<1 sentence on what changing this value would mean for the crop>"}}
      ]
    }}
  ],
  "warnings": [
    {{"message": "<exact message from input>", "advice": "<1-2 sentence actionable advice grounded in crop science>"}}
  ]
}}
"""


def merge_enrichment(payload: CropRecommendationInput, llm_data: dict) -> EnrichedResponse:
    llm_recs_by_rank    = {r["rank"]: r for r in llm_data["recommendations"]}
    llm_warnings_by_msg = {w["message"]: w for w in llm_data.get("warnings", [])}

    enriched_recs = []
    for rec in payload.recommendations:
        lr = llm_recs_by_rank.get(rec.rank, {})
        llm_features_by_label = {f["label"]: f for f in lr.get("top_features", [])}
        llm_cf_by_label       = {c["label"]: c for c in lr.get("counterfactuals", [])}

        enriched_features = [
            EnrichedFeature(
                label=tf.label,
                value=tf.value,
                impact=tf.impact,
                importance=tf.importance,
                explanation=llm_features_by_label.get(tf.label, {}).get("explanation", ""),
            )
            for tf in rec.top_features
        ]

        enriched_cfs = [
            EnrichedCounterfactual(
                label=cf.label,
                changes=cf.changes,
                new_confidence=cf.new_confidence,
                explanation=llm_cf_by_label.get(cf.label, {}).get("explanation", ""),
            )
            for cf in rec.counterfactuals
        ]

        enriched_recs.append(
            EnrichedRecommendation(
                rank=rec.rank,
                crop=rec.crop,
                confidence=rec.confidence,
                confidence_label=confidence_label(rec.confidence),
                suitability_class=rec.suitability_class,
                suitability_label=SUITABILITY_LABELS.get(rec.suitability_class, rec.suitability_class),
                short_summary=lr.get("short_summary", rec.summary),
                detailed_explanation=lr.get("detailed_explanation", rec.summary),
                top_features=enriched_features,
                counterfactuals=enriched_cfs,
            )
        )

    enriched_warnings = []
    for w in payload.warnings:
        lw = llm_warnings_by_msg.get(w.message, {})
        enriched_warnings.append(
            EnrichedWarning(message=w.message, severity=w.severity, advice=lw.get("advice", ""))
        )

    return EnrichedResponse(
        request_id=payload.request_id,
        overall_narrative=llm_data["overall_narrative"],
        soil_profile=SoilProfile(**llm_data["soil_profile"]),
        climate_profile=ClimateProfile(**llm_data["climate_profile"]),
        recommendations=enriched_recs,
        warnings=enriched_warnings,
        raw_input=payload.input_features,
    )


async def enrich_with_llm(payload: CropRecommendationInput) -> EnrichedResponse:
    # ── 1. Build RAG context from DB + GAEZ docs ──────────────────────────────
    crop_names = [r.crop for r in payload.recommendations]
    rag_context = build_full_rag_context(
        crop_names=crop_names,
        gaez_topics=["suitability_classes", "lgp", "soil_constraints",
                     "thermal_screening", "rainfall_moisture", "aez_framework", "crop_cycle"],
    )

    # ── 2. Build prompt with RAG injected ─────────────────────────────────────
    prompt = build_prompt(payload, rag_context)

    # ── 3. Call Groq ──────────────────────────────────────────────────────────
    client = AsyncGroq(api_key=GROQ_API_KEY)

    response = await client.chat.completions.create(
        model=MODEL,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=4096,
        temperature=0.3,
    )

    raw_text = response.choices[0].message.content.strip()
    if raw_text.startswith("```"):
        raw_text = raw_text.split("```")[1]
        if raw_text.startswith("json"):
            raw_text = raw_text[4:]
    raw_text = raw_text.strip()

    llm_data = json.loads(raw_text)
    return merge_enrichment(payload, llm_data)