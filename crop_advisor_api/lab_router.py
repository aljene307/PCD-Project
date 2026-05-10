from dotenv import load_dotenv
load_dotenv()

import os
import io
import re
import json
from typing import Optional, List, Tuple
from fastapi import APIRouter, HTTPException, UploadFile, File
from pydantic import BaseModel
from sqlalchemy import select
from llm_client import chat_completion
from database import AsyncSessionLocal, SoilAnalysis, SoilMeasurement

router = APIRouter(prefix="/lab", tags=["Lab Report"])

OCR_SPACE_KEY  = os.getenv("OCR_SPACE_KEY", "helloworld")   # register free at ocr.space/ocrapi

# If PyMuPDF extracts fewer than this many characters the PDF is probably scanned
# → hand off to OCR.space instead of trusting the empty text.
DIGITAL_PDF_MIN_CHARS = 80

# Minimum rows the regex parser must find before we skip Groq entirely.
REGEX_MIN_HITS = 3


# ─── Output Models ────────────────────────────────────────────────────────────

class MeasurementOut(BaseModel):
    attribute:  str
    iso_method: Optional[str] = None
    unit:       Optional[str] = None
    value:      Optional[float] = None


class LabExtractResponse(BaseModel):
    analysis_id:   int
    report_ref:    Optional[str]
    measurements:  List[MeasurementOut]
    parse_method:  str   # "regex" | "llm" | "regex+partial"


# ─── Step 1 – OCR / text extraction ──────────────────────────────────────────
#
# Priority chain:
#   PDF  → PyMuPDF (digital text) → OCR.space if text is blank/tiny
#   Image→ OCR.space → Tesseract (local, offline fallback)

import httpx as _httpx


async def _ocr_space(file_bytes: bytes, filename: str) -> str:
    """
    Send file to OCR.space free API and return the extracted text.
    Raises RuntimeError on API error so callers can fall through to the next option.
    """
    async with _httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            "https://api.ocr.space/parse/image",
            data={
                "apikey":            OCR_SPACE_KEY,
                "language":          "fre",        # French lab reports
                "isOverlayRequired": "false",
                "detectOrientation": "true",
                "scale":             "true",        # upscale low-res images
                "OCREngine":         "2",           # Engine 2 handles tables better
            },
            files={"file": (filename, file_bytes)},
        )
    resp.raise_for_status()
    data = resp.json()
    if data.get("IsErroredOnProcessing"):
        raise RuntimeError(data.get("ErrorMessage", ["OCR.space error"])[0])
    return "\n".join(
        r.get("ParsedText", "") for r in data.get("ParsedResults", [])
    ).strip()


def _tesseract_fallback(file_bytes: bytes) -> str:
    """Local offline OCR — used only when OCR.space is unreachable."""
    try:
        import pytesseract
        from PIL import Image
        img = Image.open(io.BytesIO(file_bytes))
        return pytesseract.image_to_string(img, config="--psm 6 -l fra")
    except ImportError:
        return ""   # tesseract not installed — caller will handle empty string


async def extract_text(file_bytes: bytes, filename: str, content_type: str) -> str:
    """
    Return raw text from a PDF or image using the best available method.
    Never raises — returns empty string as worst case so the pipeline can decide.
    """
    is_pdf = "pdf" in content_type or filename.lower().endswith(".pdf")

    if is_pdf:
        # Try PyMuPDF first (instant, no network, perfect for digital PDFs)
        try:
            import fitz
            doc = fitz.open(stream=file_bytes, filetype="pdf")
            text = "\n".join(page.get_text() for page in doc).strip()
            if len(text) >= DIGITAL_PDF_MIN_CHARS:
                return text
            # Fall through: PDF is scanned / image-based
        except Exception:
            pass

    # For images and scanned PDFs → OCR.space
    try:
        return await _ocr_space(file_bytes, filename)
    except Exception:
        pass

    # OCR.space failed (network, quota, etc.) → Tesseract offline
    return _tesseract_fallback(file_bytes)


# ─── Step 2a – Primary: regex template parser ────────────────────────────────
#
# The French soil lab report follows a fixed layout:
#
#   Référence rapport : 20260406-R-HM
#   ...
#   Paramètre                     | Méthode ISO           | Unité  | Résultat
#   pH (eau)                      | NF EN ISO 10390 (2022)| ---    | 7.20
#   Conductivité électrique (CE)  | NF EN 27888 (1993)    | mS/cm  | 0.45
#   ...
#
# Columns are separated by pipe characters OR by 2+ spaces / tabs.

_REF_PATTERN = re.compile(
    r"(?:r[ée]f[ée]rence\s*(?:rapport|du rapport)\s*[:\-]?\s*|ref\s*[:\-]\s*)"
    r"([A-Z0-9]{6,}-[A-Z]+-[A-Z0-9]+)",
    re.IGNORECASE,
)

# Also accept bare date-prefixed refs like "20260406-R-HM" anywhere on a line
_BARE_REF = re.compile(r"\b(\d{8}-[A-Z]+-[A-Z0-9]+)\b")

# Separator: pipe, tab, or 2+ spaces
_SEP = r"(?:\s*\|\s*|\t|\s{2,})"

# Generic multi-column row: 3 or 4 cells separated by _SEP, last cell is a number
# Covers: pipe-delimited, tab-delimited, and multi-space-delimited layouts
_ROW = re.compile(
    r"^(.+?)"           + _SEP +   # attribute
    r"(.*?)"            + _SEP +   # ISO method (optional)
    r"([^\t|]*?)"       + _SEP +   # unit
    r"([+\-]?\d[\d ]*(?:[.,]\d+)?)\s*$"  # numeric value
)


def _parse_float(s: str) -> Optional[float]:
    s = s.strip().replace(" ", "").replace(",", ".")
    try:
        return float(s)
    except ValueError:
        return None


def parse_with_regex(raw_text: str) -> Tuple[Optional[str], list]:
    lines = raw_text.splitlines()
    report_ref: Optional[str] = None
    measurements: list = []

    for line in lines:
        line = line.strip()
        if not line:
            continue

        # --- report ref ---
        if report_ref is None:
            m = _REF_PATTERN.search(line)
            if m:
                report_ref = m.group(1)
            else:
                m = _BARE_REF.search(line)
                if m:
                    report_ref = m.group(1)

        # --- any delimited row (pipe / tab / multi-space) ---
        m = _ROW.match(line)
        if m:
            attr, method, unit, val_str = [c.strip() for c in m.groups()]
            _SKIP = ("param", "analys", "résultat", "result", "method", "unité", "unit")
            if any(h in attr.lower() for h in _SKIP):
                continue
            val = _parse_float(val_str)
            measurements.append({
                "attribute": attr,
                "iso_method": method or None,
                "unit": unit or None,
                "value": val,
            })

    return report_ref, measurements


# ─── Step 2b – Fallback: Groq LLM parser ─────────────────────────────────────

def _extract_json_block(text: str) -> dict:
    """
    Robustly pull the first {...} block out of an LLM response,
    even when the model wraps it in markdown fences or adds commentary.
    """
    # Strip markdown fences
    text = re.sub(r"```(?:json)?", "", text).strip()
    # Find the outermost {...}
    start = text.find("{")
    if start == -1:
        raise ValueError("No JSON object found in LLM response")
    depth, end = 0, -1
    for i, ch in enumerate(text[start:], start):
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                end = i
                break
    if end == -1:
        raise ValueError("Unterminated JSON object in LLM response")
    return json.loads(text[start : end + 1])


async def parse_with_llm(raw_text: str) -> Tuple[Optional[str], list]:
    system = (
        "You are a soil laboratory data extraction assistant. "
        "Respond ONLY with a raw JSON object — no markdown, no explanation, no code fences."
    )
    user_msg = (
        "Extract from this French soil analysis report:\n"
        "1. The report reference (e.g. \"20260406-R-HM\") — look for \"Référence\" or a date-prefixed code.\n"
        "2. Every measurement row from the results table.\n\n"
        "Return ONLY this JSON structure:\n"
        '{"report_ref": "<ref or null>", "measurements": ['
        '{"attribute": "<name>", "iso_method": "<ISO ref or null>", "unit": "<unit or null>", "value": <number or null>}'
        "]}\n\n"
        "Rules: keep French names exactly as written; unit '---' stays '---'; null for missing values.\n\n"
        f"--- RAW TEXT ---\n{raw_text}\n--- END ---"
    )

    response_text = await chat_completion(
        system,
        [{"role": "user", "content": user_msg}],
        max_tokens=2048,
        temperature=0.1,
    )
    data = _extract_json_block(response_text)
    return data.get("report_ref"), data.get("measurements", [])


# ─── Step 2 – Orchestrator: regex → LLM fallback ─────────────────────────────

async def extract_measurements(raw_text: str) -> Tuple[Optional[str], list, str]:
    """
    Returns (report_ref, measurements, method_used).
    method_used is one of: "regex" | "llm" | "regex+partial"
    """
    report_ref, measurements = parse_with_regex(raw_text)

    if len(measurements) >= REGEX_MIN_HITS:
        return report_ref, measurements, "regex"

    # Regex didn't get enough — try LLM (Groq + Gemini in parallel)
    try:
        llm_ref, llm_measurements = await parse_with_llm(raw_text)
        return llm_ref or report_ref, llm_measurements, "llm"

    except HTTPException:
        # Re-raise HTTP errors from llm_client (rate-limit 429, config 500, etc.)
        # so they reach the client cleanly instead of being swallowed.
        if measurements:
            # We have partial regex results — return them rather than erroring
            return report_ref, measurements, "regex+partial"
        raise

    except Exception:
        # LLM returned unparseable content — fall back to partial regex
        if measurements:
            return report_ref, measurements, "regex+partial"
        raise HTTPException(
            status_code=422,
            detail=(
                "Could not parse the report automatically. "
                "Please submit measurements manually via /lab/extract/json."
            ),
        )


# ─── Step 3 – Persist to SQLite ──────────────────────────────────────────────

async def save_to_db(report_ref: Optional[str], measurements: list, source: str) -> int:
    async with AsyncSessionLocal() as db:
        analysis = SoilAnalysis(report_ref=report_ref, source=source)
        db.add(analysis)
        await db.flush()

        for m in measurements:
            db.add(SoilMeasurement(
                analysis_id=analysis.id,
                attribute=m.get("attribute", ""),
                iso_method=m.get("iso_method"),
                unit=m.get("unit"),
                value=m.get("value"),
            ))
        await db.commit()
        return analysis.id


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.post("/extract/file", response_model=LabExtractResponse,
             summary="Upload a PDF or image lab report and extract measurements")
async def extract_from_file(file: UploadFile = File(...)):
    """
    Accepts a PDF or image (jpg/png/tiff) of a soil lab report.

    OCR chain (in order, never blocks):
      1. PyMuPDF          — for digital PDFs (instant, no network)
      2. OCR.space        — for scanned PDFs and all images (free online OCR)
      3. Tesseract        — local offline fallback if OCR.space is unreachable

    Parsing chain (applied to the extracted text):
      1. Regex template parser  — instant, zero external calls
      2. Groq LLM              — only if regex finds < 3 rows
      3. Partial regex result  — returned as-is if Groq is also rate-limited
    """
    file_bytes = await file.read()
    content_type = file.content_type or ""
    filename = file.filename or "upload"

    supported = ("pdf", "image", "jpeg", "jpg", "png", "tiff", "tif", "webp")
    if not any(x in content_type for x in supported) and not any(
        filename.lower().endswith(f".{x}") for x in ("pdf", "jpg", "jpeg", "png", "tiff", "tif", "webp")
    ):
        raise HTTPException(status_code=400, detail="Unsupported file type. Send a PDF or image.")

    raw_text = await extract_text(file_bytes, filename, content_type)

    if not raw_text.strip():
        raise HTTPException(
            status_code=422,
            detail="Could not extract any text from the file. Try a clearer scan or submit via /lab/extract/json.",
        )

    report_ref, measurements, method = await extract_measurements(raw_text)

    analysis_id = await save_to_db(report_ref, measurements, source="upload")

    return LabExtractResponse(
        analysis_id=analysis_id,
        report_ref=report_ref,
        measurements=[MeasurementOut(**m) for m in measurements],
        parse_method=method,
    )


@router.post("/extract/json", response_model=LabExtractResponse,
             summary="Submit pre-parsed measurements directly as JSON")
async def extract_from_json(
    measurements: List[MeasurementOut],
    report_ref: Optional[str] = None,
):
    """Submit measurements without OCR — useful when the report is already structured."""
    measurements_dicts = [m.model_dump() for m in measurements]
    analysis_id = await save_to_db(report_ref, measurements_dicts, source="json")

    return LabExtractResponse(
        analysis_id=analysis_id,
        report_ref=report_ref,
        measurements=measurements,
        parse_method="json",
    )


@router.get("/analyses", summary="List all saved soil analyses")
async def list_analyses():
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(SoilAnalysis))
        analyses = result.scalars().all()
    return [
        {"id": a.id, "report_ref": a.report_ref, "source": a.source, "created_at": a.created_at}
        for a in analyses
    ]


@router.get("/analyses/{analysis_id}", summary="Get full measurements for a soil analysis")
async def get_analysis(analysis_id: int):
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(SoilAnalysis).where(SoilAnalysis.id == analysis_id)
        )
        analysis = result.scalar_one_or_none()
        if not analysis:
            raise HTTPException(status_code=404, detail="Analysis not found.")

        result = await db.execute(
            select(SoilMeasurement).where(SoilMeasurement.analysis_id == analysis_id)
        )
        measurements = result.scalars().all()

    return {
        "id": analysis.id,
        "report_ref": analysis.report_ref,
        "source": analysis.source,
        "created_at": analysis.created_at,
        "measurements": [
            {"attribute": m.attribute, "iso_method": m.iso_method, "unit": m.unit, "value": m.value}
            for m in measurements
        ],
    }