"""
populate_db.py — Clean crop_knowledge.db and ingest all JSONs from json_files/

Usage:
    python3 populate_db.py

Place this script inside the crop_advisor_api/ folder, next to crop_knowledge.db.
It will read every .json file from crop_advisor_api/json_files/.
"""

import json
import os
import sqlite3
from datetime import datetime, timezone

BASE_DIR  = os.path.dirname(os.path.abspath(__file__))
DB_PATH   = os.path.join(BASE_DIR, "crop_knowledge.db")
JSON_DIR  = os.path.join(BASE_DIR, "json_files")


# ─── Helpers ──────────────────────────────────────────────────────────────────

def safe_float(val):
    if val is None:
        return None
    if isinstance(val, (int, float)):
        return float(val)
    s = str(val).strip()
    if s in ("---", "-", "", "no input"):
        return None
    try:
        return float(s)
    except ValueError:
        return None


def safe_int(val):
    f = safe_float(val)
    return int(f) if f is not None else None


def safe_str(val):
    if val is None:
        return None
    s = str(val).strip()
    return s if s and s not in ("---", "-", "no input") else None


# ─── Clean ────────────────────────────────────────────────────────────────────

def clean_db(conn):
    c = conn.cursor()
    for table in ["crop_cultivation", "crop_climate", "crop_ecology", "crops"]:
        c.execute(f"DELETE FROM {table}")
        print(f"  cleared {table}")
    conn.commit()


# ─── Parse ────────────────────────────────────────────────────────────────────

def parse_and_insert(conn, data: dict):
    desc = data.get("description") or {}
    eco  = data.get("ecology")     or {}
    cli  = data.get("climate")     or {}
    cult = data.get("cultivation") or {}
    now  = datetime.now(timezone.utc).isoformat()

    c = conn.cursor()

    # ── crops ─────────────────────────────────────────────────────────────────
    c.execute("""
        INSERT INTO crops
        (common_name, scientific_name, life_form, physiology, habit, category,
         life_span, plant_attributes, notes, created_at, updated_at)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)
    """, (
        data.get("common_name"),
        safe_str(data.get("scientific_name")),
        safe_str(desc.get("life_form")),
        safe_str(desc.get("physiology")),
        safe_str(desc.get("habit")),
        safe_str(desc.get("category")),
        safe_str(desc.get("life_span")),
        safe_str(desc.get("plant_attributes")),
        safe_str(data.get("notes")),
        now, now,
    ))
    crop_id = c.lastrowid

    # ── crop_ecology ──────────────────────────────────────────────────────────
    temp     = eco.get("temperature")     or {}
    rain     = eco.get("rainfall_annual") or {}
    ph       = eco.get("soil_ph")         or {}
    alt      = eco.get("altitude")        or {}
    lat      = eco.get("latitude")        or {}
    texture  = eco.get("soil_texture")    or {}
    depth    = eco.get("soil_depth")      or {}
    fert     = eco.get("soil_fertility")  or {}
    drainage = eco.get("soil_drainage")   or {}
    salinity = eco.get("soil_salinity")   or {}
    light    = eco.get("light_intensity") or {}

    c.execute("""
        INSERT INTO crop_ecology
        (crop_id,
         temp_opt_min, temp_opt_max, temp_abs_min, temp_abs_max,
         rainfall_opt_min, rainfall_opt_max, rainfall_abs_min, rainfall_abs_max,
         soil_ph_opt_min, soil_ph_opt_max, soil_ph_abs_min, soil_ph_abs_max,
         altitude_abs_min, altitude_abs_max,
         latitude_abs_min, latitude_abs_max,
         soil_texture_optimal, soil_texture_absolute,
         soil_depth_optimal, soil_depth_absolute,
         soil_fertility_optimal, soil_fertility_absolute,
         soil_drainage_optimal, soil_drainage_absolute,
         soil_salinity_optimal, soil_salinity_absolute,
         light_intensity_optimal, light_intensity_absolute)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    """, (
        crop_id,
        safe_float(temp.get("opt_min")), safe_float(temp.get("opt_max")),
        safe_float(temp.get("abs_min")), safe_float(temp.get("abs_max")),
        safe_float(rain.get("opt_min")), safe_float(rain.get("opt_max")),
        safe_float(rain.get("abs_min")), safe_float(rain.get("abs_max")),
        safe_float(ph.get("opt_min")),   safe_float(ph.get("opt_max")),
        safe_float(ph.get("abs_min")),   safe_float(ph.get("abs_max")),
        safe_float(alt.get("abs_min")),  safe_float(alt.get("abs_max")),
        safe_float(lat.get("abs_min")),  safe_float(lat.get("abs_max")),
        safe_str(texture.get("optimal")),  safe_str(texture.get("absolute")),
        safe_str(depth.get("optimal")),    safe_str(depth.get("absolute")),
        safe_str(fert.get("optimal")),     safe_str(fert.get("absolute")),
        safe_str(drainage.get("optimal")), safe_str(drainage.get("absolute")),
        safe_str(salinity.get("optimal")), safe_str(salinity.get("absolute")),
        safe_str(light.get("opt_min") or light.get("optimal")),
        safe_str(light.get("abs_max") or light.get("absolute")),
    ))

    # ── crop_climate ──────────────────────────────────────────────────────────
    c.execute("""
        INSERT INTO crop_climate
        (crop_id, climate_zone, photoperiod,
         killing_temp_rest, killing_temp_growth,
         abiotic_tolerance, abiotic_susceptibility, introduction_risks)
        VALUES (?,?,?,?,?,?,?,?)
    """, (
        crop_id,
        safe_str(cli.get("climate_zone")),
        safe_str(cli.get("photoperiod")),
        safe_str(cli.get("killing_temp_during_rest")),
        safe_str(cli.get("killing_temp_early_growth")),
        safe_str(cli.get("abiotic_tolerance")),
        safe_str(cli.get("abiotic_susceptibility")),
        safe_str(cli.get("introduction_risks")),
    ))

    # ── crop_cultivation ──────────────────────────────────────────────────────
    c.execute("""
        INSERT INTO crop_cultivation
        (crop_id, production_system,
         crop_cycle_min, crop_cycle_max,
         cropping_system, subsystem,
         companion_species, mechanization_level, labour_intensity)
        VALUES (?,?,?,?,?,?,?,?,?)
    """, (
        crop_id,
        safe_str(cult.get("production_system")),
        safe_int(cult.get("crop_cycle_min")),
        safe_int(cult.get("crop_cycle_max")),
        safe_str(cult.get("cropping_system")),
        safe_str(cult.get("subsystem")),
        safe_str(cult.get("companion_species")),
        safe_str(cult.get("mechanization_level")),
        safe_str(cult.get("labour_intensity")),
    ))

    return crop_id


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    if not os.path.exists(DB_PATH):
        print(f"ERROR: database not found at {DB_PATH}")
        return

    if not os.path.exists(JSON_DIR):
        print(f"ERROR: json_files folder not found at {JSON_DIR}")
        return

    json_files = sorted([f for f in os.listdir(JSON_DIR) if f.endswith(".json")])
    if not json_files:
        print(f"No .json files found in {JSON_DIR}")
        return

    conn = sqlite3.connect(DB_PATH)

    # Step 1: Clean
    print("Cleaning database...")
    clean_db(conn)

    # Step 2: Parse & insert
    print(f"\nInserting {len(json_files)} crop(s) from {JSON_DIR}...")
    ok, failed = 0, []

    for filename in json_files:
        path = os.path.join(JSON_DIR, filename)
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)

            # Support both a single object and a list
            entries = data if isinstance(data, list) else [data]
            for entry in entries:
                crop_id = parse_and_insert(conn, entry)
                print(f"  ✓ {entry.get('common_name')} (id={crop_id})")
                ok += 1

        except Exception as e:
            print(f"  ✗ {filename}: {e}")
            failed.append(filename)
            conn.rollback()
            continue

        conn.commit()

    conn.close()

    # Step 3: Summary
    print(f"\nDone — {ok} crop(s) inserted, {len(failed)} failed.")
    if failed:
        print("Failed files:", failed)


if __name__ == "__main__":
    main()
