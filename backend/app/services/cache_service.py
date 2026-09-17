import hashlib
import logging
from app.services.supabase_client import supabase
import asyncio

def generate_ocr_hash(text: str) -> str:
    """
    Generate a SHA256 hash of the cleaned, merged OCR text.
    """
    cleaned = "".join(text.split()).strip().lower()
    return hashlib.sha256(cleaned.encode("utf-8")).hexdigest()

async def get_cached_prescription(ocr_hash: str) -> dict | None:
    """
    Retrieve cached prescription analysis from Supabase.
    """
    try:
        def _get():
            response = supabase.table("prescription_cache").select("analysis_json").eq("ocr_hash", ocr_hash).execute()
            if response.data and len(response.data) > 0:
                return response.data[0]["analysis_json"]
            return None
        return await asyncio.to_thread(_get)
    except Exception as e:
        logging.error(f"Supabase Cache Get Error: {e}")
        return None

async def save_prescription_to_cache(ocr_hash: str, ocr_text: str, analysis_json: dict) -> None:
    """
    Save new prescription analysis to the Supabase cache table.
    """
    try:
        data = {
            "ocr_hash": ocr_hash,
            "ocr_text": ocr_text,
            "analysis_json": analysis_json
        }
        def _save():
            supabase.table("prescription_cache").insert(data).execute()
        await asyncio.to_thread(_save)
    except Exception as e:
        logging.error(f"Supabase Cache Save Error: {e}")
