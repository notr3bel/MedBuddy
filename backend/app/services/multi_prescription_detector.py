import re

def detect_multiple_prescriptions(ocr_text: str) -> dict:
    """
    Phase 8: Detects multiple prescription pages, two prescriptions in one image, multiple doctors, or multiple patients.
    Returns:
    {
        "multiple_detected": bool,
        "message": str | None
    }
    """
    if not ocr_text:
        return {"multiple_detected": False, "message": None}

    lowered = ocr_text.lower()

    # 1. Count occurrences of doctor indicators ("Dr", "Doctor", "MD", "MBBS")
    doctor_matches = len(re.findall(r"(?:dr\b|doctor\b|m\.d\.|mbbs\b)", lowered))

    # 2. Count occurrences of patient indicators ("Patient:", "Pt Name:", "Name:")
    patient_matches = len(re.findall(r"\b(patient name|pt name|patient id)\b", lowered))

    # 3. Count prescription headers ("Rx", "Prescription", "Date:")
    rx_header_matches = len(re.findall(r"\b(rx|prescription)\b", lowered))

    # 4. Check page indicators ("Page 1", "Page 2", "1 of 2")
    page_matches = len(re.findall(r"\b(page \d|sheet \d)\b", lowered))

    if doctor_matches >= 2 or patient_matches >= 2 or page_matches >= 2 or (rx_header_matches >= 2 and len(ocr_text) > 400):
        return {
            "multiple_detected": True,
            "message": "Multiple prescriptions detected. Please upload one prescription at a time."
        }

    return {
        "multiple_detected": False,
        "message": None
    }
