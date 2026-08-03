from fastapi import APIRouter, UploadFile, File, Form
from typing import Optional
from app.services.skin_analysis import analyze_skin
from app.services.supabase_client import save_analysis_history

router = APIRouter(prefix="/api")

@router.post("/skin")
async def analyze_skin_image(
    file: UploadFile = File(...), 
    lang: str = Form("en"),
    user_id: Optional[str] = Form(None)
):

    image_bytes = await file.read()

    result = analyze_skin(image_bytes, language=lang)

    if user_id:
        await save_analysis_history(user_id, "skin", result)

    return {
        "success": True,
        "analysis": result
    }