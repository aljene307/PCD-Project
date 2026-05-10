from dotenv import load_dotenv
load_dotenv()

import json
from rag_service import build_full_rag_context
from llm_client import chat_completion

SYSTEM_PROMPT = """You are an expert agronomist assistant. The user has received a crop recommendation analysis for their land and is asking you questions about it.

You have deep knowledge of crop science, soil science, and agro-ecological zoning. Use this knowledge naturally in your answers — speak as a confident expert, not as someone reading from a document.

Rules:
- Keep answers concise and practical. Use plain language — the user may be a farmer, not a scientist.
- Use specific numbers naturally in your answers (e.g. "arabica coffee grows best between 14–28°C and your field averages 20°C, which is a great match").
- Compare the user's field measurements to crop requirements naturally without explaining where those numbers come from.
- Never mention PyAEZ, GAEZ, FAO, IIASA, "the documentation", "the knowledge base", "the context", or any source by name.
- Never say phrases like "according to the provided data", "based on the knowledge base", "the documentation states", or anything similar.
- Just answer as an expert agronomist would in a conversation — direct, helpful, and grounded in facts.

--- AGRONOMIC KNOWLEDGE (use naturally, never cite) ---
{rag_context}
--- END ---

--- USER'S ANALYSIS RESULTS ---
{analysis_json}
--- END ---
"""


async def get_chat_response(
    enriched_json: dict,
    history: list[dict],
    user_message: str,
) -> str:
    # ── 1. Extract recommended crop names from the enriched analysis ──────────
    crop_names = []
    try:
        recs = enriched_json.get("recommendations", [])
        crop_names = [r["crop"] for r in recs if "crop" in r]
    except Exception:
        pass

    # ── 2. Build RAG context ──────────────────────────────────────────────────
    gaez_topics = [
        "suitability_classes",
        "lgp",
        "soil_constraints",
        "thermal_screening",
        "rainfall_moisture",
        "aez_framework",
        "crop_cycle",
        "intercropping_companion",
    ]
    rag_context = build_full_rag_context(
        crop_names=crop_names,
        gaez_topics=gaez_topics,
    )

    # ── 3. Build system prompt ────────────────────────────────────────────────
    system = SYSTEM_PROMPT.format(
        rag_context=rag_context,
        analysis_json=json.dumps(enriched_json, indent=2),
    )

    # ── 4. Call LLM (Groq + Gemini in parallel) ───────────────────────────────
    messages = history + [{"role": "user", "content": user_message}]
    return await chat_completion(system, messages, max_tokens=1024, temperature=0.5)