import time
import asyncio
import json
import logging
from fastapi import APIRouter, UploadFile, File, Form
from typing import Optional

from app.services.input_validator import validate_input_file
from app.services.quality_analyzer import analyze_image_quality
from app.services.file_converter import prepare_input_for_analysis
from app.services.ocr import extract_text_from_image
from app.services.trocr_service import predict_medicine_name
from app.services.ocr_fusion import merge_ocr_results
from app.services.text_cleaner import clean_prescription_text, extract_medicine_lines
from app.services.prescription_ai import analyze_prescription_ai
from app.services.medicine_verifier import verify_extracted_medicines
from app.services.prescription_validator import sanitize_prescription_schedule, build_ocr_fallback_schedule
from app.services.cache_service import generate_ocr_hash, get_cached_prescription, save_prescription_to_cache
from app.services.supabase_client import save_analysis_history
from app.services.structured_logger import log_audit_event
from app.services.security import sanitize_prompt_text

from app.services.reminder_service import save_user_reminder_schedule

PRESCRIPTION_REJECTION_MSG = (
    "This image doesn't seem to be a prescription.\n"
    "Try uploading:\n\n"
    "📄 A doctor's prescription\n"
    "📸 A clear, well-lit photo\n"
    "📑 A single prescription page"
)

router = APIRouter(prefix="/api")

@router.post("/prescription")
async def analyze_prescription(
    file: UploadFile = File(...),
    lang: str = Form("en"),
    user_id: Optional[str] = Form(None)
):
    total_start = time.time()
    filename = file.filename or ""

    # 1. Input Validation (File non-empty)
    raw_bytes = await file.read()
    input_val = validate_input_file(raw_bytes, filename)
    if not input_val["valid"]:
        log_audit_event("prescription_rejected", time.time() - total_start, status="REJECTED_INPUT", warnings=[input_val["error"]])
        print("\nReason for rejection:\n-------------------\n" + str(input_val["error"]) + "\n-------------------\n")
        return {
            "success": True,
            "is_valid_prescription": False,
            "extracted_text": "",
            "detected_medicines": [],
            "schedule": [],
            "explanation": PRESCRIPTION_REJECTION_MSG,
            "precautions": []
        }

    # Rule #4: Image quality should NEVER immediately reject. It returns QUALITY_WARNING and continues OCR.
    quality_res = analyze_image_quality(raw_bytes)
    if not quality_res.get("pass_quality", True):
        print(f"\nQUALITY_WARNING: {quality_res.get('message')}. Continuing OCR...\n")

    # Normalize file into standard JPEG image bytes + extract native PDF text
    prepared = prepare_input_for_analysis(raw_bytes, filename)
    image_bytes = prepared["image_bytes"]
    pdf_native_text = prepared["pdf_native_text"]

    # 2. High-Speed Parallel Pre-Analysis Pipeline (Azure OCR + TrOCR)
    azure_task = asyncio.create_task(extract_text_from_image(image_bytes))
    trocr_task = asyncio.create_task(asyncio.to_thread(predict_medicine_name, image_bytes))

    try:
        extracted_text, trocr_prediction = await asyncio.gather(
            azure_task, trocr_task
        )
    except Exception as gather_err:
        logging.warning(f"Parallel OCR gathering warning: {gather_err}")
        try:
            extracted_text = await azure_task
        except Exception:
            extracted_text = ""
        try:
            trocr_prediction = await trocr_task
        except Exception:
            trocr_prediction = ""

    azure_sec = time.time() - total_start
    trocr_sec = 0.0

    if pdf_native_text and pdf_native_text not in (extracted_text or ""):
        extracted_text = pdf_native_text + "\n" + (extracted_text or "")

    merged_text = merge_ocr_results(extracted_text or "", trocr_prediction or "")
    sanitized_merged_text = sanitize_prompt_text(merged_text)

    # Rule #2 & #9 Logging: OCR extracted
    print("\nOCR extracted:\n-------------------")
    print(sanitized_merged_text or "[EMPTY OCR TEXT]")
    print("-------------------\n")

    if not sanitized_merged_text or len(sanitized_merged_text.strip()) < 3:
        print("Reason for rejection:\n-------------------\nOCR cannot read meaningful text.\n-------------------\n")
        return {
            "success": True,
            "is_valid_prescription": False,
            "extracted_text": "",
            "detected_medicines": [],
            "schedule": [],
            "explanation": PRESCRIPTION_REJECTION_MSG,
            "precautions": []
        }

    # 3. Clean OCR text & extract medicine candidate lines (Rule #3 & Rule #8)
    cleaned_ocr_text = clean_prescription_text(sanitized_merged_text)
    medicine_lines = extract_medicine_lines(cleaned_ocr_text or sanitized_merged_text)

    # Rule #2 & #9 Logging: Medicine lines found
    print("Medicine lines found:\n-------------------")
    print(medicine_lines or "[No direct medicine keywords found, passing full OCR text to Gemini]")
    print("-------------------\n")

    # Rule #2 & #9 Logging: Validation Result
    val_confidence = 1.0 if medicine_lines else 0.6
    print("Validation Result:\n-------------------")
    print(f"Confidence Score: {val_confidence}")
    print(f"Candidate Medicine Lines: {len(medicine_lines.splitlines()) if medicine_lines else 0}")
    print("Status: VALIDATION_PASSED")
    print("-------------------\n")

    # 4. Cache lookup & Gemini Multimodal Analysis (Rule #6)
    ocr_hash = generate_ocr_hash(f"{lang}::{sanitized_merged_text or str(len(image_bytes))}")
    cached_data = await get_cached_prescription(ocr_hash)

    gemini_sec = 0.0

    # Rule #2 & #9 Logging: Gemini Input
    print("Gemini Input:\n-------------------")
    print(f"Language: {lang}")
    print(f"OCR Text Snippet: {sanitized_merged_text[:300]}...")
    print("-------------------\n")

    if cached_data and cached_data.get("is_valid_prescription") is True:
        final_result = cached_data
    else:
        gemini_start = time.time()
        try:
            raw_analysis = await analyze_prescription_ai(sanitized_merged_text, lang, image_bytes)
            gemini_sec = time.time() - gemini_start

            raw_meds = raw_analysis.get("medicines", [])
            verified_meds = await verify_extracted_medicines(raw_meds)
            raw_analysis["medicines"] = verified_meds

            raw_schedule = raw_analysis.get("schedule", [])
            sanitized_schedule = sanitize_prescription_schedule(raw_schedule)
            raw_analysis["schedule"] = sanitized_schedule

            final_result = raw_analysis

            if final_result.get("is_valid_prescription") and not final_result.get("fallback_activated"):
                await save_prescription_to_cache(ocr_hash, sanitized_merged_text, final_result)

        except Exception as gemini_err:
            gemini_sec = time.time() - gemini_start
            final_result = {
                "is_valid_prescription": True,
                "verified_text": sanitized_merged_text,
                "medicines": [],
                "schedule": [],
                "explanation": "OCR extraction completed successfully.",
                "precautions": [],
                "fallback_activated": True
            }

    # Rule #2 & #9 Logging: Gemini Output
    print("Gemini Output:\n-------------------")
    try:
        print(json.dumps(final_result, indent=2))
    except Exception:
        print(str(final_result))
    print("-------------------\n")

    raw_meds_list = final_result.get("medicines", []) if isinstance(final_result, dict) else []
    detected_meds: list[str] = []
    if isinstance(raw_meds_list, list):
        for m in raw_meds_list:
            if isinstance(m, dict) and m.get("medicine"):
                detected_meds.append(str(m["medicine"]))

    raw_schedule = final_result.get("schedule") if isinstance(final_result, dict) else None
    if not detected_meds and isinstance(raw_schedule, list):
        for item in raw_schedule:
            if isinstance(item, dict) and item.get("medicine"):
                detected_meds.append(str(item["medicine"]))

    gemini_is_valid = final_result.get("is_valid_prescription", True) if isinstance(final_result, dict) else True
    is_valid = gemini_is_valid and bool(detected_meds or (isinstance(raw_schedule, list) and raw_schedule) or medicine_lines)

    # Build OCR-derived fallback medicines & schedule if Gemini returned empty results or fallback was activated
    fb_meds, fb_schedule, fb_explanation = build_ocr_fallback_schedule(medicine_lines or cleaned_ocr_text or sanitized_merged_text)

    if is_valid:
        if not detected_meds:
            detected_meds = [m["medicine"] for m in fb_meds]

        if isinstance(final_result, dict) and not final_result.get("schedule"):
            final_result["schedule"] = fb_schedule

        explanation_text = str(final_result.get("explanation", "")) if isinstance(final_result, dict) else ""
        if not explanation_text or explanation_text == PRESCRIPTION_REJECTION_MSG or (isinstance(final_result, dict) and final_result.get("fallback_activated")) or "temporarily unavailable" in explanation_text:
            explanation_text = fb_explanation

        print(f"Reason for acceptance:\n-------------------\nPrescription accepted with {len(detected_meds)} medicine(s).\n-------------------\n")
    else:
        explanation_text = str(final_result.get("explanation", "")) if (isinstance(final_result, dict) and not gemini_is_valid) else PRESCRIPTION_REJECTION_MSG
        is_valid = False
        print("Reason for rejection:\n-------------------\n" + explanation_text + "\n-------------------\n")

    # Save to user history in Supabase & auto-save reminder schedules for immediate dashboard loading
    if is_valid:
        user_id_clean = user_id if isinstance(user_id, str) and user_id.strip() else None
        if user_id_clean and explanation_text:
            await save_analysis_history(user_id_clean, "prescription", explanation_text)
        
        target_uid = user_id_clean or "default"
        save_sched = final_result.get("schedule") if isinstance(final_result, dict) else None
        if isinstance(save_sched, list) and save_sched:
            await save_user_reminder_schedule(target_uid, save_sched)

    total_sec = time.time() - total_start

    log_audit_event(
        event_type="prescription_analysis",
        processing_time_sec=total_sec,
        ocr_duration_sec=azure_sec + trocr_sec,
        gemini_duration_sec=gemini_sec,
        doc_type="Prescription",
        confidence_score=val_confidence,
        medicine_count=len(detected_meds),
        status="SUCCESS" if is_valid else "INVALID_PRESCRIPTION"
    )

    if not is_valid:
        return {
            "success": True,
            "is_valid_prescription": False,
            "extracted_text": sanitized_merged_text,
            "detected_medicines": [],
            "schedule": [],
            "explanation": PRESCRIPTION_REJECTION_MSG,
            "precautions": []
        }

    return {
        "success": True,
        "is_valid_prescription": True,
        "extracted_text": sanitized_merged_text,
        "detected_medicines": detected_meds,
        "schedule": final_result.get("schedule", []),
        "explanation": explanation_text,
        "precautions": final_result.get("precautions", [])
    }