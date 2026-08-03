from fastapi import APIRouter
from app.services.model_info import get_custom_ocr_info

router = APIRouter(prefix="/api")

@router.get("/model-info")
async def model_info():
    return get_custom_ocr_info()