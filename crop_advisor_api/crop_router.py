import json
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from sqlalchemy import select, delete
from database import (
    AsyncSessionLocal, Crop, CropEcology, CropClimate, CropCultivation
)

router = APIRouter(prefix="/crops", tags=["Crop Knowledge Base"])


# ─── Input Models (mirrors the arabica JSON format) ───────────────────────────

class DescriptionInput(BaseModel):
    life_form:        Optional[str] = None
    physiology:       Optional[str] = None
    habit:            Optional[str] = None
    category:         Optional[str] = None
    life_span:        Optional[str] = None
    plant_attributes: Optional[str] = None


class TemperatureInput(BaseModel):
    opt_min: Optional[str] = None
    opt_max: Optional[str] = None
    abs_min: Optional[str] = None
    abs_max: Optional[str] = None


class RainfallInput(BaseModel):
    opt_min: Optional[str] = None
    opt_max: Optional[str] = None
    abs_min: Optional[str] = None
    abs_max: Optional[str] = None


class SoilPhInput(BaseModel):
    opt_min: Optional[str] = None
    opt_max: Optional[str] = None
    abs_min: Optional[str] = None
    abs_max: Optional[str] = None


class AltitudeInput(BaseModel):
    abs_min: Optional[str] = None
    abs_max: Optional[str] = None


class LatitudeInput(BaseModel):
    abs_min: Optional[str] = None
    abs_max: Optional[str] = None


class SoilPropertyInput(BaseModel):
    optimal:  Optional[str] = None
    absolute: Optional[str] = None


class EcologyInput(BaseModel):
    temperature:      Optional[TemperatureInput]   = None
    rainfall_annual:  Optional[RainfallInput]      = None
    soil_ph:          Optional[SoilPhInput]        = None
    altitude:         Optional[AltitudeInput]      = None
    latitude:         Optional[LatitudeInput]      = None
    soil_texture:     Optional[SoilPropertyInput]  = None
    soil_depth:       Optional[SoilPropertyInput]  = None
    soil_fertility:   Optional[SoilPropertyInput]  = None
    soil_drainage:    Optional[SoilPropertyInput]  = None
    soil_salinity:    Optional[SoilPropertyInput]  = None
    light_intensity:  Optional[SoilPropertyInput]  = None


class ClimateInput(BaseModel):
    climate_zone:             Optional[str] = None
    photoperiod:              Optional[str] = None
    killing_temp_during_rest: Optional[str] = None
    killing_temp_early_growth:Optional[str] = None
    abiotic_tolerance:        Optional[str] = None
    abiotic_susceptibility:   Optional[str] = None
    introduction_risks:       Optional[str] = None


class CultivationInput(BaseModel):
    production_system:   Optional[str] = None
    crop_cycle_min:      Optional[str] = None
    crop_cycle_max:      Optional[str] = None
    cropping_system:     Optional[str] = None
    subsystem:           Optional[str] = None
    companion_species:   Optional[str] = None
    mechanization_level: Optional[str] = None
    labour_intensity:    Optional[str] = None


class CropIngestInput(BaseModel):
    common_name:     str
    scientific_name: Optional[str] = None
    description:     Optional[DescriptionInput]  = None
    ecology:         Optional[EcologyInput]      = None
    climate:         Optional[ClimateInput]      = None
    cultivation:     Optional[CultivationInput]  = None
    notes:           Optional[str]               = None


# ─── Helper: safely parse float from messy strings like "---", "", "14" ──────

def safe_float(val: Optional[str]) -> Optional[float]:
    if not val or val.strip() in ("---", "-", "", "no input"):
        return None
    try:
        return float(val.strip())
    except ValueError:
        return None


def safe_int(val: Optional[str]) -> Optional[int]:
    if not val or val.strip() in ("---", "-", "", "no input"):
        return None
    try:
        return int(val.strip())
    except ValueError:
        return None


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.post("/ingest", summary="Ingest a crop knowledge JSON into the database")
async def ingest_crop(payload: CropIngestInput):
    """
    Receives an arabica-style crop JSON and saves/updates it in SQLite.
    If the crop already exists (matched by common_name), it is fully updated.
    """
    async with AsyncSessionLocal() as db:

        # ── 1. Upsert the main crop row ────────────────────────────────────
        result = await db.execute(
            select(Crop).where(Crop.common_name == payload.common_name)
        )
        crop = result.scalar_one_or_none()

        if not crop:
            crop = Crop(common_name=payload.common_name)
            db.add(crop)

        crop.scientific_name  = payload.scientific_name
        crop.notes            = payload.notes

        if payload.description:
            crop.life_form        = payload.description.life_form
            crop.physiology       = payload.description.physiology
            crop.habit            = payload.description.habit
            crop.category         = payload.description.category
            crop.life_span        = payload.description.life_span
            crop.plant_attributes = payload.description.plant_attributes

        await db.flush()  # get crop.id before inserting children

        # ── 2. Upsert ecology ──────────────────────────────────────────────
        if payload.ecology:
            eco_result = await db.execute(
                select(CropEcology).where(CropEcology.crop_id == crop.id)
            )
            ecology = eco_result.scalar_one_or_none()
            if not ecology:
                ecology = CropEcology(crop_id=crop.id)
                db.add(ecology)

            e = payload.ecology
            if e.temperature:
                ecology.temp_opt_min = safe_float(e.temperature.opt_min)
                ecology.temp_opt_max = safe_float(e.temperature.opt_max)
                ecology.temp_abs_min = safe_float(e.temperature.abs_min)
                ecology.temp_abs_max = safe_float(e.temperature.abs_max)
            if e.rainfall_annual:
                ecology.rainfall_opt_min = safe_float(e.rainfall_annual.opt_min)
                ecology.rainfall_opt_max = safe_float(e.rainfall_annual.opt_max)
                ecology.rainfall_abs_min = safe_float(e.rainfall_annual.abs_min)
                ecology.rainfall_abs_max = safe_float(e.rainfall_annual.abs_max)
            if e.soil_ph:
                ecology.soil_ph_opt_min = safe_float(e.soil_ph.opt_min)
                ecology.soil_ph_opt_max = safe_float(e.soil_ph.opt_max)
                ecology.soil_ph_abs_min = safe_float(e.soil_ph.abs_min)
                ecology.soil_ph_abs_max = safe_float(e.soil_ph.abs_max)
            if e.altitude:
                ecology.altitude_abs_min = safe_float(e.altitude.abs_min)
                ecology.altitude_abs_max = safe_float(e.altitude.abs_max)
            if e.latitude:
                ecology.latitude_abs_min = safe_float(e.latitude.abs_min)
                ecology.latitude_abs_max = safe_float(e.latitude.abs_max)
            if e.soil_texture:
                ecology.soil_texture_optimal  = e.soil_texture.optimal
                ecology.soil_texture_absolute = e.soil_texture.absolute
            if e.soil_depth:
                ecology.soil_depth_optimal  = e.soil_depth.optimal
                ecology.soil_depth_absolute = e.soil_depth.absolute
            if e.soil_fertility:
                ecology.soil_fertility_optimal  = e.soil_fertility.optimal
                ecology.soil_fertility_absolute = e.soil_fertility.absolute
            if e.soil_drainage:
                ecology.soil_drainage_optimal  = e.soil_drainage.optimal
                ecology.soil_drainage_absolute = e.soil_drainage.absolute
            if e.soil_salinity:
                ecology.soil_salinity_optimal  = e.soil_salinity.optimal
                ecology.soil_salinity_absolute = e.soil_salinity.absolute
            if e.light_intensity:
                ecology.light_intensity_optimal  = e.light_intensity.optimal
                ecology.light_intensity_absolute = e.light_intensity.absolute

        # ── 3. Upsert climate ──────────────────────────────────────────────
        if payload.climate:
            cli_result = await db.execute(
                select(CropClimate).where(CropClimate.crop_id == crop.id)
            )
            climate = cli_result.scalar_one_or_none()
            if not climate:
                climate = CropClimate(crop_id=crop.id)
                db.add(climate)

            c = payload.climate
            climate.climate_zone           = c.climate_zone
            climate.photoperiod            = c.photoperiod
            climate.killing_temp_rest      = c.killing_temp_during_rest
            climate.killing_temp_growth    = c.killing_temp_early_growth
            climate.abiotic_tolerance      = c.abiotic_tolerance
            climate.abiotic_susceptibility = c.abiotic_susceptibility
            climate.introduction_risks     = c.introduction_risks

        # ── 4. Upsert cultivation ──────────────────────────────────────────
        if payload.cultivation:
            cul_result = await db.execute(
                select(CropCultivation).where(CropCultivation.crop_id == crop.id)
            )
            cultivation = cul_result.scalar_one_or_none()
            if not cultivation:
                cultivation = CropCultivation(crop_id=crop.id)
                db.add(cultivation)

            cv = payload.cultivation
            cultivation.production_system   = cv.production_system
            cultivation.crop_cycle_min      = safe_int(cv.crop_cycle_min)
            cultivation.crop_cycle_max      = safe_int(cv.crop_cycle_max)
            cultivation.cropping_system     = cv.cropping_system
            cultivation.subsystem           = cv.subsystem
            cultivation.companion_species   = cv.companion_species
            cultivation.mechanization_level = cv.mechanization_level
            cultivation.labour_intensity    = cv.labour_intensity

        await db.commit()

    return {
        "status": "ok",
        "message": f"Crop '{payload.common_name}' ingested successfully.",
        "crop_id": crop.id,
    }


@router.get("/list", summary="List all crops in the knowledge base")
async def list_crops():
    """Returns all crops stored in the database."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Crop))
        crops = result.scalars().all()
    return [
        {
            "id": c.id,
            "common_name": c.common_name,
            "scientific_name": c.scientific_name,
            "life_form": c.life_form,
            "has_notes": bool(c.notes),
        }
        for c in crops
    ]


@router.get("/{crop_id}", summary="Get full crop details by ID")
async def get_crop(crop_id: int):
    """Returns the full crop record including ecology, climate, and cultivation."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Crop).where(Crop.id == crop_id))
        crop = result.scalar_one_or_none()
        if not crop:
            raise HTTPException(status_code=404, detail="Crop not found.")

        eco = (await db.execute(select(CropEcology).where(CropEcology.crop_id == crop_id))).scalar_one_or_none()
        cli = (await db.execute(select(CropClimate).where(CropClimate.crop_id == crop_id))).scalar_one_or_none()
        cul = (await db.execute(select(CropCultivation).where(CropCultivation.crop_id == crop_id))).scalar_one_or_none()

    return {
        "id": crop.id,
        "common_name": crop.common_name,
        "scientific_name": crop.scientific_name,
        "life_form": crop.life_form,
        "physiology": crop.physiology,
        "habit": crop.habit,
        "category": crop.category,
        "life_span": crop.life_span,
        "plant_attributes": crop.plant_attributes,
        "notes": crop.notes,
        "ecology": {
            "temp_opt_min": eco.temp_opt_min if eco else None,
            "temp_opt_max": eco.temp_opt_max if eco else None,
            "temp_abs_min": eco.temp_abs_min if eco else None,
            "temp_abs_max": eco.temp_abs_max if eco else None,
            "rainfall_opt_min": eco.rainfall_opt_min if eco else None,
            "rainfall_opt_max": eco.rainfall_opt_max if eco else None,
            "rainfall_abs_min": eco.rainfall_abs_min if eco else None,
            "rainfall_abs_max": eco.rainfall_abs_max if eco else None,
            "soil_ph_opt_min": eco.soil_ph_opt_min if eco else None,
            "soil_ph_opt_max": eco.soil_ph_opt_max if eco else None,
            "soil_ph_abs_min": eco.soil_ph_abs_min if eco else None,
            "soil_ph_abs_max": eco.soil_ph_abs_max if eco else None,
            "soil_texture_optimal": eco.soil_texture_optimal if eco else None,
            "soil_texture_absolute": eco.soil_texture_absolute if eco else None,
            "soil_depth_optimal": eco.soil_depth_optimal if eco else None,
            "soil_drainage_optimal": eco.soil_drainage_optimal if eco else None,
        } if eco else None,
        "climate": {
            "climate_zone": cli.climate_zone if cli else None,
            "photoperiod": cli.photoperiod if cli else None,
            "killing_temp_rest": cli.killing_temp_rest if cli else None,
            "introduction_risks": cli.introduction_risks if cli else None,
        } if cli else None,
        "cultivation": {
            "production_system": cul.production_system if cul else None,
            "crop_cycle_min": cul.crop_cycle_min if cul else None,
            "crop_cycle_max": cul.crop_cycle_max if cul else None,
            "companion_species": cul.companion_species if cul else None,
        } if cul else None,
    }


@router.delete("/{crop_id}", summary="Delete a crop from the knowledge base")
async def delete_crop(crop_id: int):
    """Deletes a crop and all its related data (cascade)."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Crop).where(Crop.id == crop_id))
        crop = result.scalar_one_or_none()
        if not crop:
            raise HTTPException(status_code=404, detail="Crop not found.")
        await db.delete(crop)
        await db.commit()
    return {"status": "ok", "message": f"Crop {crop_id} deleted."}
