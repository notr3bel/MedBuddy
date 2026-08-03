from fastapi import APIRouter, UploadFile, File, Form
from typing import Optional
from app.services.ocr import extract_text_from_image
from app.services.report_summarizer import summarize_medical_report
from app.services.supabase_client import save_analysis_history
import json

router = APIRouter(prefix="/api")

@router.post("/report")
async def analyze_report(
    file: UploadFile = File(...), 
    lang: str = Form("en"),
    user_id: Optional[str] = Form(None)
):

    report_bytes = await file.read()

    extracted_text = await extract_text_from_image(report_bytes)

    if len(extracted_text.strip()) < 50:
        return {
            "success": False,
            "message": "Could not read the medical report clearly."
        }

    result = await summarize_medical_report(extracted_text, language=lang)
    summary_text = result.get("summary", "")

    if user_id:
        await save_analysis_history(user_id, "report", summary_text)

    return {
        "success": True,
        "summary": summary_text,
        "abnormal_count": result.get("abnormal_count", 0)
    }