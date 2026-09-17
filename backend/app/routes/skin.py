import time
from fastapi import APIRouter, UploadFile, File, Form
from typing import Optional
from app.services.input_validator import validate_input_file
from app.services.quality_analyzer import analyze_image_quality
from app.services.skin_analysis import analyze_skin
from app.services.supabase_client import save_analysis_history
from app.services.structured_logger import log_audit_event

router = APIRouter(prefix="/api")

@router.post("/skin")
async def analyze_skin_image(
    file: UploadFile = File(...), 
    lang: str = Form("en"),
    user_id: Optional[str] = Form(None)
):
    start_time = time.time()
    filename = file.filename or ""

    image_bytes = await file.read()
    input_val = validate_input_file(image_bytes, filename)
    if not input_val["valid"]:
        return {
            "success": False,
            "analysis": input_val["error"]
        }

    quality_val = analyze_image_quality(image_bytes)
    if not quality_val["pass_quality"]:
        return {
            "success": False,
            "analysis": quality_val["message"]
        }

    try:
        result = analyze_skin(image_bytes, language=lang)
        if user_id:
            await save_analysis_history(user_id, "skin", result)
            
        log_audit_event("skin_analysis", time.time() - start_time, status="SUCCESS")
        return {
            "success": True,
            "analysis": result
        }
    except Exception as e:
        log_audit_event("skin_failed", time.time() - start_time, status="FAILURE")
        return {
            "success": False,
            "analysis": "Could not analyze skin image. Please capture a clearer photo."
        }