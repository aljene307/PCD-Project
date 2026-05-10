from pydantic import BaseModel, Field
from typing import List, Optional, Literal, Dict, Any


# ─── Input Models (mirrors the ML model JSON protocol) ───────────────────────

class InputFeatures(BaseModel):
    # Soil
    ph: float
    nitrogen_ppm: float
    phosphorus_ppm: float
    potassium_ppm: float
    organic_matter_pct: float
    texture_class: str
    # Climate
    annual_rainfall_mm: float
    avg_temp_c: float
    growing_season_days: int
    # Terrain
    slope_pct: float
    elevation_m: float


class TopFeature(BaseModel):
    label: str
    value: float
    impact: Literal["positive", "negative", "neutral"]
    importance: float  # 0.0 – 1.0


class CounterfactualChange(BaseModel):
    from_: float = Field(..., alias="from")
    to: float

    class Config:
        populate_by_name = True


class Counterfactual(BaseModel):
    label: str
    changes: dict  # e.g. {"nitrogen_ppm": {"from": 140, "to": 180}}
    new_confidence: float


class Recommendation(BaseModel):
    rank: int
    crop: str
    confidence: float  # 0.0 – 1.0
    suitability_class: Literal["S1", "S2", "S3", "N"]
    summary: str  # original model summary (short)
    top_features: List[TopFeature]
    counterfactuals: List[Counterfactual]


class Warning(BaseModel):
    message: str
    severity: Literal["low", "medium", "high"]


class CropRecommendationInput(BaseModel):
    request_id: str
    input_features: InputFeatures
    recommendations: List[Recommendation]
    warnings: List[Warning] = []


# ─── Output Models (what Flutter receives) ───────────────────────────────────

class EnrichedFeature(BaseModel):
    label: str
    value: float
    impact: str
    importance: float
    explanation: str  # LLM-generated plain English explanation of this feature's role


class EnrichedCounterfactual(BaseModel):
    label: str
    changes: dict
    new_confidence: float
    explanation: str  # LLM-generated plain English


class EnrichedRecommendation(BaseModel):
    rank: int
    crop: str
    confidence: float
    confidence_label: str        # e.g. "High", "Moderate", "Low"
    suitability_class: str
    suitability_label: str       # e.g. "Highly Suitable"
    short_summary: str           # 1–2 sentences for the card/preview
    detailed_explanation: str    # full LLM paragraph for the detail page
    top_features: List[EnrichedFeature]
    counterfactuals: List[EnrichedCounterfactual]


class EnrichedWarning(BaseModel):
    message: str
    severity: str
    advice: str  # LLM-generated actionable advice


class SoilProfile(BaseModel):
    headline: str        # e.g. "Moderately fertile clay-loam soil"
    description: str     # LLM 2–3 sentence plain-language soil overview


class ClimateProfile(BaseModel):
    headline: str
    description: str


class EnrichedResponse(BaseModel):
    request_id: str
    overall_narrative: str           # 1 paragraph executive summary for the home screen
    soil_profile: SoilProfile
    climate_profile: ClimateProfile
    recommendations: List[EnrichedRecommendation]
    warnings: List[EnrichedWarning]
    raw_input: InputFeatures         # pass-through so Flutter can render charts


# ─── Advisor Session Models (new frontend contract) ───────────────────────────

class SoilLayer(BaseModel):
    """One depth layer (D1=topsoil … D7=deepest) from the GAEZ soil data."""
    smu_id:   Optional[int]   = None   # Soil Mapping Unit ID
    DRG:      Optional[str]   = None   # Drainage class (VP/P/I/MW/W/E)
    GYP:      Optional[float] = None   # Gypsum %
    GRC:      Optional[float] = None   # Coarse fragments / gravel %
    CEC_clay: Optional[float] = None   # CEC of clay cmol(+)/kg
    CEC_soil: Optional[float] = None   # CEC of soil cmol(+)/kg
    OSD:      Optional[int]   = None   # Gelic soil properties (0/1)
    SPR:      Optional[int]   = None   # Soil property rating (0/1)
    VSP:      Optional[int]   = None   # Vertic soil properties (0/1)
    TXT:      Optional[str]   = None   # Texture (e.g. "clay loam")
    SPH:      Optional[str]   = None   # Soil phase description
    RSD:      Optional[float] = None   # Rooting system depth cm
    OC:       Optional[float] = None   # Organic carbon % weight
    pH:       Optional[float] = None
    EC:       Optional[float] = None   # Electrical conductivity dS/m
    CCB:      Optional[float] = None   # Calcium carbonate %
    TEB:      Optional[float] = None   # Total exchangeable bases cmol(+)/kg
    BS:       Optional[float] = None   # Base saturation %
    ESP:      Optional[float] = None   # Exchangeable sodium percentage %

    class Config:
        extra = "allow"  # accept any additional fields silently


class AdvisorSessionRequest(BaseModel):
    """
    JSON body sent by the frontend to initialise a chat session.
    soil_layers: {"D1": {...}, "D2": {...}, ...}
    crop_requirements: {"wheat": {"climate_needs": {...}, "soil_needs": {...}}, ...}
    """
    user_id:           str
    soil_layers:       Dict[str, SoilLayer]
    crop_requirements: Dict[str, Any]   # flexible – keys are crop names


class AdvisorSessionResponse(BaseModel):
    session_id: str
    user_id:    str
    message:    str


class AdvisorChatRequest(BaseModel):
    session_id: str
    message:    str


class AdvisorChatResponse(BaseModel):
    session_id: str
    reply:      str
    history:    List[Dict[str, str]]
