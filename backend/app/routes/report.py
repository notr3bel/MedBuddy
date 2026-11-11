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
from app.services.report_validator import validate_report_content, build_ocr_fallback_report_summary
from app.services.report_summarizer import summarize_medical_report
from app.services.supabase_client import save_analysis_history
from app.services.structured_logger import log_audit_event
from app.services.security import sanitize_prompt_text

REPORT_REJECTION_MSG = (
    "This image doesn't seem to be a report.\n"
    "Try uploading:\n\n"
    "📄 A doctor's report\n"
    "📸 A clear, well-lit photo\n"
    "📑 A single report page"
)

router = APIRouter(prefix="/api")

@router.post("/report")
async def analyze_report(
    file: UploadFile = File(...), 
    lang: str = Form("en"),
    user_id: Optional[str] = Form(None)
):
    total_start = time.time()
    filename = file.filename or ""

    # 1. Input Validation
    raw_bytes = await file.read()
    input_val = validate_input_file(raw_bytes, filename)
    if not input_val["valid"]:
        log_audit_event("report_rejected", time.time() - total_start, status="REJECTED_INPUT", warnings=[input_val["error"]])
        print("\nReason for rejection:\n-------------------\n" + str(input_val["error"]) + "\n-------------------\n")
        return {
            "success": False,
            "message": REPORT_REJECTION_MSG
        }

    # Rule #4: Image quality should NEVER immediately reject. It returns QUALITY_WARNING and continues OCR.
    quality_res = analyze_image_quality(raw_bytes)
    if not quality_res.get("pass_quality", True):
        print(f"\nQUALITY_WARNING: {quality_res.get('message')}. Continuing OCR...\n")

    # Normalize file into standard JPEG image bytes + multi-page images + native PDF text
    prepared = prepare_input_for_analysis(raw_bytes, filename)
    report_bytes = prepared["image_bytes"]
    page_images = prepared.get("page_images") or ([report_bytes] if report_bytes else [])
    pdf_native_text = prepared["pdf_native_text"]
    file_type = prepared.get("file_type", "image")

    # 2. Azure OCR Execution (supports multi-page PDFs)
    ocr_start = time.time()
    extracted_text = ""
    if file_type == "pdf" and len(pdf_native_text.strip()) >= 100:
        # Native digital PDF: pypdf already extracted full multi-page text cleanly
        extracted_text = pdf_native_text
    else:
        try:
            if len(page_images) > 1:
                ocr_pages = await asyncio.gather(
                    *(extract_text_from_image(p) for p in page_images),
                    return_exceptions=True
                )
                parts = []
                for idx, p_res in enumerate(ocr_pages):
                    if isinstance(p_res, str) and p_res.strip():
                        parts.append(f"--- Page {idx + 1} ---\n{p_res.strip()}")
                extracted_text = "\n\n".join(parts)
            else:
                extracted_text = await extract_text_from_image(report_bytes)
        except Exception as err:
            logging.warning(f"OCR extraction failed: {err}")
            extracted_text = ""

        if pdf_native_text and pdf_native_text not in (extracted_text or ""):
            extracted_text = pdf_native_text + "\n" + (extracted_text or "")

    ocr_sec = time.time() - ocr_start

    sanitized_text = sanitize_prompt_text(extracted_text or "")

    # Rule #2 & #9 Logging: OCR extracted
    print("\nOCR extracted:\n-------------------")
    print(sanitized_text or "[EMPTY OCR TEXT]")
    print("-------------------\n")

    # 3. Rule #5: Report validation via Confidence Score
    val_res = validate_report_content(sanitized_text)

    # Rule #2 & #9 Logging: Validation Result
    print("Validation Result:\n-------------------")
    print(f"Confidence Score: {val_res.get('confidence_score', 0.0)}")
    print(f"Report Type Identified: {val_res.get('report_type')}")
    print(f"Validation Message: {val_res.get('message')}")
    print("-------------------\n")

    # Rule #2 & #9 Logging: Gemini Input
    print("Gemini Input:\n-------------------")
    print(f"Language: {lang}")
    print(f"OCR Text Snippet: {sanitized_text[:300]}...")
    print("-------------------\n")

    # 4. Direct Gemini Multimodal AI Vision + OCR Report Summarization (Rule #6)
    gemini_start = time.time()
    try:
        result = await summarize_medical_report(
            sanitized_text,
            language=lang,
            image_bytes=report_bytes,
            page_images=page_images,
        )
    except Exception as e:
        log_audit_event("report_failed", time.time() - total_start, status="GEMINI_FAILURE")
        print("[FALLBACK ACTIVATED] Gemini analysis exception. Preserving OCR report results.")
        result = {
            "is_valid_report": True,
            "summary": "OCR processing completed.",
            "abnormal_count": 0,
            "report_type": val_res.get("report_type", "Medical Report"),
            "fallback_activated": True
        }
    gemini_sec = time.time() - gemini_start

    # Rule #2 & #9 Logging: Gemini Output
    print("Gemini Output:\n-------------------")
    try:
        print(json.dumps(result, indent=2))
    except Exception:
        print(str(result))
    print("-------------------\n")

    gemini_is_valid = result.get("is_valid_report", True) if isinstance(result, dict) else True
    is_valid = gemini_is_valid and bool(
        (isinstance(result, dict) and result.get("is_valid_report", False)) or 
        val_res.get("is_valid_report", False)
    )

    raw_report_type = result.get("report_type") if (isinstance(result, dict) and result.get("report_type") and result.get("report_type") != "Unknown Report") else val_res.get("report_type", "Medical Report")
    report_type: str = str(raw_report_type) if raw_report_type else "Medical Report"

    raw_summary = result.get("summary", "") if isinstance(result, dict) and is_valid else REPORT_REJECTION_MSG
    summary_text: str = str(raw_summary) if raw_summary else REPORT_REJECTION_MSG

    if is_valid:
        is_fallback = bool(isinstance(result, dict) and result.get("fallback_activated"))
        if not summary_text or "doesn't seem to be a report" in summary_text or is_fallback or "temporarily unavailable" in summary_text:
            summary_text = build_ocr_fallback_report_summary(sanitized_text, report_type)

    abnormal_count = result.get("abnormal_count", 0) if isinstance(result, dict) and is_valid else 0

    if is_valid:
        print(f"Reason for acceptance:\n-------------------\nAccepted {report_type} medical report.\n-------------------\n")
    else:
        print("Reason for rejection:\n-------------------\nDocument does not contain medical report content.\n-------------------\n")

    # Save to user history in Supabase
    user_id_clean = user_id if isinstance(user_id, str) and user_id.strip() else None
    if user_id_clean and summary_text and is_valid:
        await save_analysis_history(user_id_clean, "report", summary_text)

    total_sec = time.time() - total_start

    log_audit_event(
        event_type="report_analysis",
        processing_time_sec=total_sec,
        ocr_duration_sec=ocr_sec,
        gemini_duration_sec=gemini_sec,
        doc_type=report_type,
        confidence_score=float(val_res.get("confidence_score", 1.0) or 1.0),
        medicine_count=0,
        status="SUCCESS" if is_valid else "REJECTED_REPORT"
    )

    if not is_valid:
        return {
            "success": False,
            "message": REPORT_REJECTION_MSG
        }

    return {
        "success": True,
        "summary": summary_text,
        "abnormal_count": abnormal_count,
        "report_type": report_type
    }