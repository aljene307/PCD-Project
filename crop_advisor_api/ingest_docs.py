"""
ingest_docs.py — Extract text from GAEZ/PyAEZ PDFs, chunk it, and store in
                 the doc_chunks table of crop_knowledge.db.

Usage:
    python3 ingest_docs.py

Place this script inside crop_advisor_api/ alongside crop_knowledge.db.
The three PDFs must also be in crop_advisor_api/docs/:
    docs/pyAEZv2_2-documentation.pdf
    docs/GAEZ-v3.pdf
    docs/GAEZ-v4.pdf

Run once (or re-run to refresh — it clears and rebuilds the table each time).
"""

import os
import re
import sqlite3
from pypdf import PdfReader

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH  = os.path.join(BASE_DIR, "docs.db")
DOCS_DIR = os.path.join(BASE_DIR, "docs")

# PDF sources: (source_tag, filename)
PDFS = [
    ("pyaez_v2.2",  "pyAEZv2_2-documentation.pdf"),
    ("gaez_v3",     "GAEZ-v3.pdf"),
    ("gaez_v4",     "GAEZ-v4.pdf"),
]

# ── Chunking parameters ───────────────────────────────────────────────────────
CHUNK_SIZE    = 800   # target characters per chunk
CHUNK_OVERLAP = 150  # overlap between consecutive chunks


# ─── Schema ───────────────────────────────────────────────────────────────────

def ensure_table(conn):
    conn.execute("""
        CREATE TABLE IF NOT EXISTS doc_chunks (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            source      TEXT NOT NULL,       -- e.g. 'pyaez_v2.2', 'gaez_v3', 'gaez_v4'
            page_num    INTEGER,
            chunk_index INTEGER,
            text        TEXT NOT NULL
        )
    """)
    conn.execute("CREATE INDEX IF NOT EXISTS idx_doc_chunks_source ON doc_chunks(source)")
    conn.commit()


def clear_table(conn):
    conn.execute("DELETE FROM doc_chunks")
    conn.commit()


# ─── Text extraction ──────────────────────────────────────────────────────────

def extract_pages(pdf_path: str) -> list[tuple[int, str]]:
    """Returns list of (page_number, page_text) — 1-indexed."""
    reader = PdfReader(pdf_path)
    pages  = []
    for i, page in enumerate(reader.pages, start=1):
        text = page.extract_text() or ""
        text = clean_text(text)
        if text.strip():
            pages.append((i, text))
    return pages


def clean_text(text: str) -> str:
    """Basic cleanup: collapse whitespace, remove header/footer noise."""
    # Collapse multiple blank lines
    text = re.sub(r"\n{3,}", "\n\n", text)
    # Collapse multiple spaces
    text = re.sub(r" {2,}", " ", text)
    # Remove lone page numbers (lines that are just a number)
    text = re.sub(r"(?m)^\s*\d+\s*$", "", text)
    return text.strip()


# ─── Chunking ─────────────────────────────────────────────────────────────────

def chunk_text(text: str, size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> list[str]:
    """
    Split text into overlapping chunks, trying to break at sentence boundaries.
    """
    chunks  = []
    start   = 0
    length  = len(text)

    while start < length:
        end = min(start + size, length)

        # Try to end at a sentence boundary (. or \n) within last 200 chars
        if end < length:
            boundary = max(
                text.rfind(".", start, end),
                text.rfind("\n", start, end),
            )
            if boundary > start + size // 2:
                end = boundary + 1

        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)

        start = end - overlap if end - overlap > start else end

    return chunks


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    # Create docs.db if it doesn't exist yet
    conn = sqlite3.connect(DB_PATH)

    if not os.path.exists(DOCS_DIR):
        print(f"ERROR: docs/ folder not found at {DOCS_DIR}")
        print("       Create crop_advisor_api/docs/ and place the three PDFs inside.")
        conn.close()
        return
    ensure_table(conn)

    print("Clearing existing doc_chunks...")
    clear_table(conn)

    total_chunks = 0

    for source_tag, filename in PDFS:
        pdf_path = os.path.join(DOCS_DIR, filename)

        if not os.path.exists(pdf_path):
            print(f"  ✗ Missing: {pdf_path}  — skipping.")
            continue

        print(f"\nProcessing {filename}...")
        pages = extract_pages(pdf_path)
        print(f"  Extracted {len(pages)} non-empty pages.")

        file_chunks = 0
        for page_num, page_text in pages:
            chunks = chunk_text(page_text)
            for idx, chunk in enumerate(chunks):
                conn.execute(
                    "INSERT INTO doc_chunks (source, page_num, chunk_index, text) VALUES (?,?,?,?)",
                    (source_tag, page_num, idx, chunk),
                )
                file_chunks += 1

        conn.commit()
        print(f"  ✓ {file_chunks} chunks stored for {source_tag}.")
        total_chunks += file_chunks

    conn.close()
    print(f"\nDone — {total_chunks} total chunks in doc_chunks table.")
    print("\nNext step: update rag_service.py to query doc_chunks instead of GAEZ_CHUNKS.")


if __name__ == "__main__":
    main()
