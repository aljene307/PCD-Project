from dotenv import load_dotenv
load_dotenv()

import json
from llm_client import chat_completion

# Abbreviation legend injected once into the system prompt so the LLM can
# interpret the raw field codes from the GAEZ soil data.
SOIL_LEGEND = """
SOIL LAYER FIELD GUIDE (layers D1=topsoil … D7=deepest horizon):
  smu_id  : Soil Mapping Unit identifier
  DRG     : Drainage class  — VP=Very Poor, P=Poor, I=Imperfect, MW=Moderately Well, W=Well, E=Excessive
  GYP     : Calcium sulphate (gypsum) content  [%]
  GRC     : Coarse fragments / gravel content  [%]
  CEC_clay: Cation Exchange Capacity of the clay fraction  [cmol(+)/kg]
  CEC_soil: Cation Exchange Capacity of the bulk soil      [cmol(+)/kg]
  OSD     : Gelic (permafrost-influenced) soil properties   [0=absent, 1=present]
  SPR     : Soil Property Rating — hardpan / impervious layer [0=none, 1=present]
  VSP     : Vertic (shrink-swell clay) soil properties       [0=absent, 1=present]
  TXT     : Soil texture class (e.g. "clay loam", "silt loam")
  SPH     : Soil phase — describes physical obstacles to roots
  RSD     : Rooting system depth  [cm]
  OC      : Organic carbon content  [% weight]
  pH      : Soil reaction (pH)
  EC      : Electrical conductivity — salinity proxy  [dS/m]
  CCB     : Calcium carbonate (lime) content  [%]
  TEB     : Total Exchangeable Bases  [cmol(+)/kg]
  BS      : Base saturation  [%]
  ESP     : Exchangeable Sodium Percentage — sodicity indicator  [%]

CROP REQUIREMENTS FIELDS:
  climate_needs / temperature : temp_opt_min/max  (optimal growing range °C)
                                temp_abs_min/max  (survival limits °C)
  climate_needs / rainfall    : rainfall_opt_min/max  [mm/year]
                                rainfall_abs_min/max  [mm/year]
  terrain_needs / altitude    : altitude_abs_min/max  [m a.s.l.]
  terrain_needs / latitude    : latitude_abs_min/max  [decimal degrees]
  soil_needs / ph             : soil_ph_opt_min/max, soil_ph_abs_min/max
  soil_needs / soil_texture   : optimal and absolute acceptable textures
  soil_needs / soil_depth     : depth class strings (shallow / medium / deep)
  soil_needs / soil_fertility : fertility class strings
  soil_needs / soil_drainage  : drainage class strings
  soil_needs / soil_salinity  : salinity class strings
  Numeric soil need entries   : {"opt": <value>, "abs": <value>, "uni": "<unit>"}
                                 opt = optimal threshold, abs = absolute tolerance limit
""".strip()

SYSTEM_PROMPT_TEMPLATE = """You are an expert agronomist assistant. The user has submitted soil profile data (multiple depth layers) and crop requirement data for a set of candidate crops. Your job is to help them understand their soil, how well each crop matches it, and what agronomic decisions they should consider.

Speak as a confident, practical agronomist — concise, specific, and using real numbers. Never mention GAEZ, PyAEZ, FAO, IIASA, "the documentation", "the knowledge base", or any data source by name.

{legend}

--- USER SOIL PROFILE (depth layers) ---
{soil_json}
--- END SOIL PROFILE ---

--- CROP REQUIREMENTS ---
{crops_json}
--- END CROP REQUIREMENTS ---

When comparing soil data to crop requirements:
- Use the D1 layer (topsoil) as the primary reference for crops with shallow roots; consider deeper layers for root crops or perennials.
- Flag any soil properties that exceed the absolute tolerance of a crop as a hard constraint.
- Flag any property outside the optimal range (but within absolute) as a manageable limitation.
- Suggest practical corrective measures where relevant (liming, drainage, organic matter addition, etc.).
- If the user asks about a crop not listed in the requirements data, draw on your general agronomic knowledge.
"""


def _strip_nulls(obj):
    """Recursively remove None values to shrink the JSON payload."""
    if isinstance(obj, dict):
        return {k: _strip_nulls(v) for k, v in obj.items() if v is not None}
    if isinstance(obj, list):
        return [_strip_nulls(i) for i in obj]
    return obj


def _build_system_prompt(context: dict) -> str:
    soil_layers = _strip_nulls(context.get("soil_layers", {}))
    crop_requirements = _strip_nulls(context.get("crop_requirements", {}))

    soil_trimmed = {"D1": soil_layers.get("D1", {})}

    # Limit to 3 crops
    crop_keys = list(crop_requirements.keys())[:3]
    crops_trimmed = {k: crop_requirements[k] for k in crop_keys}

    return (
        SYSTEM_PROMPT_TEMPLATE
        .replace("{legend}",    "")  # drop the legend to save tokens
        .replace("{soil_json}", json.dumps(soil_trimmed,  separators=(",", ":")))
        .replace("{crops_json}",json.dumps(crops_trimmed, separators=(",", ":")))
    )


async def get_advisor_response(
    context: dict,
    history: list[dict],
    user_message: str,
) -> str:
    system = _build_system_prompt(context)
    messages = history[-4:] + [{"role": "user", "content": user_message}]
    return await chat_completion(system, messages, max_tokens=1024, temperature=0.5)
