from fastapi import APIRouter, UploadFile, File, Form
from typing import Optional
from app.services.ocr import extract_text_from_image
from app.services.prescription_explainer import explain_prescription
from app.services.text_cleaner import clean_prescription_text
from app.services.supabase_client import save_analysis_history
from app.services.medicine_verifier import verify_medicine_names
from app.services.medicine_validator import extract_possible_medicines
from app.services.medicine_extractor import extract_medicine_schedule
from app.services.reminder_service import generate_reminder_times

router = APIRouter(prefix="/api")


@router.post("/prescription")
async def analyze_prescription(
    file: UploadFile = File(...),
    lang: str = Form("en"),
    user_id: Optional[str] = Form(None)
):

    image_bytes = await file.read()

    extracted_text = await extract_text_from_image(
        image_bytes
    )

    if len(extracted_text.strip()) < 20:
        return {
            "success": False,
            "message": "Could not read prescription clearly"
        }

    detected_medicines = extract_possible_medicines(
        extracted_text
    )

    verified_text = await verify_medicine_names(
        extracted_text
    )

    cleaned = clean_prescription_text(
        verified_text
    )

    schedule_data = await extract_medicine_schedule(
        cleaned
    )

    for medicine in schedule_data:

        dosage = medicine.get(
            "dosage",
            ""
        )

        medicine["reminder_times"] = (
            generate_reminder_times(
                dosage
            )
        )

    explanation = await explain_prescription(
        cleaned,
        language=lang
    )

    if user_id:
        await save_analysis_history(
            user_id,
            "prescription",
            explanation
        )

    return {
        "success": True,
        "extracted_text": extracted_text,
        "detected_medicines": detected_medicines,
        "schedule": schedule_data,
        "explanation": explanation
    }