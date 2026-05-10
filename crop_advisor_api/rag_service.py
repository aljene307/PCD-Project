"""
rag_service.py — RAG context builder for the crop advisor chatbot.

Two sources:
  1. crop_knowledge.db  — notes, ecology, climate, cultivation per crop
  2. GAEZ_CHUNKS        — curated static paragraphs from the PyAEZ / GAEZ v3/v4
                          documentation, injected when relevant topics appear in
                          the conversation or analysis.
"""

import os
import sqlite3
from typing import Optional

DB_PATH      = os.path.join(os.path.dirname(os.path.abspath(__file__)), "crop_knowledge.db")
DOCS_DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "docs.db")


# ─── Keyword map for doc chunk retrieval ─────────────────────────────────────
# Maps topic tags (used by callers) to search keywords for querying doc_chunks.

TOPIC_KEYWORDS = {
    "suitability_classes":   ["suitability", "S1", "S2", "S3", "yield class", "not suitable", "very suitable"],
    "lgp":                   ["length of growing period", "LGP", "growing period", "ETa", "ETm"],
    "soil_constraints":      ["soil quality", "SQ1", "SQ2", "nutrient", "rooting", "drainage", "HWSD", "fc4"],
    "thermal_screening":     ["thermal screening", "TSUM", "temperature summation", "fc1", "thermal climate"],
    "rainfall_moisture":     ["rainfall", "moisture", "evapotranspiration", "water deficit", "fc2", "rain-fed"],
    "aez_framework":         ["agro-ecological", "AEZ", "PyAEZ", "FAO", "IIASA", "module"],
    "crop_cycle":            ["crop cycle", "cycle length", "planting date", "LGPt5", "perennial"],
    "intercropping_companion": ["intercropping", "companion", "alley cropping", "nitrogen fixation"],
}


# ─── DB helpers ───────────────────────────────────────────────────────────────

def _get_crop_context(crop_name: str) -> Optional[dict]:
    """
    Query crop_knowledge.db for a single crop by common_name.
    Returns a dict with keys: crop, ecology, climate, cultivation.
    Returns None if not found.
    """
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()

        row = c.execute(
            "SELECT * FROM crops WHERE LOWER(common_name) = LOWER(?)", (crop_name,)
        ).fetchone()

        if not row:
            # fuzzy fallback: contains match
            row = c.execute(
                "SELECT * FROM crops WHERE LOWER(common_name) LIKE LOWER(?)",
                (f"%{crop_name}%",)
            ).fetchone()

        if not row:
            conn.close()
            return None

        crop_id = row["id"]
        crop_dict = dict(row)

        eco = c.execute(
            "SELECT * FROM crop_ecology WHERE crop_id = ?", (crop_id,)
        ).fetchone()

        cli = c.execute(
            "SELECT * FROM crop_climate WHERE crop_id = ?", (crop_id,)
        ).fetchone()

        cult = c.execute(
            "SELECT * FROM crop_cultivation WHERE crop_id = ?", (crop_id,)
        ).fetchone()

        conn.close()

        return {
            "crop":        crop_dict,
            "ecology":     dict(eco)   if eco   else {},
            "climate":     dict(cli)   if cli   else {},
            "cultivation": dict(cult)  if cult  else {},
        }

    except Exception as e:
        return None


def _format_crop_context(ctx: dict) -> str:
    """Render a crop context dict into a readable text block for the LLM."""
    crop  = ctx["crop"]
    eco   = ctx["ecology"]
    cli   = ctx["climate"]
    cult  = ctx["cultivation"]

    parts = []

    # Header
    parts.append(
        f"### {crop.get('common_name', '').title()} ({crop.get('scientific_name', '')})"
    )
    parts.append(f"Life form: {crop.get('life_form', 'N/A')} | "
                 f"Category: {crop.get('category', 'N/A')} | "
                 f"Life span: {crop.get('life_span', 'N/A')}")

    # Notes (most important for RAG)
    if crop.get("notes"):
        parts.append(f"\nBotanical & agronomic notes:\n{crop['notes']}")

    # Ecology
    if eco:
        parts.append("\nEcological requirements:")
        parts.append(
            f"  Temperature (°C): optimal {eco.get('temp_opt_min')}–{eco.get('temp_opt_max')}, "
            f"absolute {eco.get('temp_abs_min')}–{eco.get('temp_abs_max')}"
        )
        parts.append(
            f"  Annual rainfall (mm): optimal {eco.get('rainfall_opt_min')}–{eco.get('rainfall_opt_max')}, "
            f"absolute {eco.get('rainfall_abs_min')}–{eco.get('rainfall_abs_max')}"
        )
        parts.append(
            f"  Soil pH: optimal {eco.get('soil_ph_opt_min')}–{eco.get('soil_ph_opt_max')}, "
            f"absolute {eco.get('soil_ph_abs_min')}–{eco.get('soil_ph_abs_max')}"
        )
        parts.append(
            f"  Altitude (m): {eco.get('altitude_abs_min')}–{eco.get('altitude_abs_max')}"
        )
        parts.append(
            f"  Soil texture (optimal): {eco.get('soil_texture_optimal')} | "
            f"Drainage: {eco.get('soil_drainage_optimal')} | "
            f"Fertility: {eco.get('soil_fertility_optimal')} | "
            f"Salinity: {eco.get('soil_salinity_optimal')}"
        )

    # Climate
    if cli:
        parts.append("\nClimate:")
        if cli.get("climate_zone"):
            parts.append(f"  Zones: {cli['climate_zone']}")
        if cli.get("photoperiod"):
            parts.append(f"  Photoperiod: {cli['photoperiod']}")
        if cli.get("abiotic_tolerance"):
            parts.append(f"  Tolerates: {cli['abiotic_tolerance']}")
        if cli.get("abiotic_susceptibility"):
            parts.append(f"  Susceptible to: {cli['abiotic_susceptibility']}")
        if cli.get("introduction_risks"):
            parts.append(f"  Introduction risks: {cli['introduction_risks']}")

    # Cultivation
    if cult:
        parts.append("\nCultivation:")
        if cult.get("crop_cycle_min") and cult.get("crop_cycle_max"):
            parts.append(
                f"  Crop cycle: {cult['crop_cycle_min']}–{cult['crop_cycle_max']} days"
            )
        if cult.get("production_system"):
            parts.append(f"  Production system: {cult['production_system']}")
        if cult.get("companion_species"):
            parts.append(f"  Companion species: {cult['companion_species']}")
        if cult.get("subsystem"):
            parts.append(f"  Subsystem: {cult['subsystem']}")

    return "\n".join(parts)


# ─── Public API ───────────────────────────────────────────────────────────────

def build_crop_rag_context(crop_names: list[str]) -> str:
    """
    Given a list of crop names (from ML recommendations),
    return a formatted RAG context string with DB knowledge for each crop.
    """
    blocks = []
    for name in crop_names:
        ctx = _get_crop_context(name)
        if ctx:
            blocks.append(_format_crop_context(ctx))
        else:
            blocks.append(f"### {name}\n(No detailed record found in crop knowledge base.)")

    return "\n\n---\n\n".join(blocks)


def build_gaez_rag_context(topics: Optional[list[str]] = None, max_chunks_per_topic: int = 3) -> str:
    """
    Query doc_chunks table in crop_knowledge.db for chunks relevant to the
    requested topics. Falls back to a broad keyword search if topics is None.

    Each topic maps to a list of keywords; we do a simple LIKE search and
    take the top N chunks per keyword, deduplicated.
    """
    try:
        conn = sqlite3.connect(DOCS_DB_PATH)
        c    = conn.cursor()

        # Check table exists
        exists = c.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='doc_chunks'"
        ).fetchone()
        if not exists:
            conn.close()
            return "(Documentation not yet ingested — run ingest_docs.py first.)"

        selected_topics = topics if topics else list(TOPIC_KEYWORDS.keys())
        result_blocks   = []
        seen_ids        = set()

        for topic in selected_topics:
            keywords = TOPIC_KEYWORDS.get(topic, [topic])
            topic_chunks = []

            for kw in keywords:
                rows = c.execute(
                    "SELECT id, source, page_num, text FROM doc_chunks "
                    "WHERE text LIKE ? LIMIT ?",
                    (f"%{kw}%", max_chunks_per_topic),
                ).fetchall()

                for row_id, source, page_num, text in rows:
                    if row_id not in seen_ids:
                        seen_ids.add(row_id)
                        topic_chunks.append((source, page_num, text))

                if len(topic_chunks) >= max_chunks_per_topic:
                    break  # enough for this topic

            for source, page_num, text in topic_chunks[:max_chunks_per_topic]:
                result_blocks.append(
                    f"[{source} — p.{page_num} — {topic}]\n{text}"
                )

        conn.close()
        return "\n\n".join(result_blocks) if result_blocks else "(No matching documentation found.)"

    except Exception as e:
        return f"(Documentation retrieval error: {e})"


def build_full_rag_context(
    crop_names: list[str],
    gaez_topics: Optional[list[str]] = None,
) -> str:
    """
    Convenience function: combines crop DB context + GAEZ doc chunks.
    Used by both llm_service.py (enrich) and chat_service.py (chat).
    """
    crop_ctx  = build_crop_rag_context(crop_names)
    gaez_ctx  = build_gaez_rag_context(gaez_topics)

    return (
        "=== CROP KNOWLEDGE BASE ===\n\n"
        + crop_ctx
        + "\n\n=== AEZ / GAEZ METHODOLOGY REFERENCE ===\n\n"
        + gaez_ctx
    )