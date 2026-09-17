import re

NON_MEDICAL_PATTERNS = [
    r"\bhello\b",
    r"\bshopping list\b",
    r"\bmathematics\b",
    r"\bmath\b",
    r"\bhomework\b",
    r"\bproject report\b",
    r"\bassignment\b",
    r"\bclass note\b",
    r"\bstudent\b",
    r"\btodo list\b",
    r"\bgrocery\b",
    r"\bmenu\b",
    r"\brecipe\b",
    r"\balgebra\b",
    r"\bcalculus\b",
    r"\bequation\b"
]

def check_non_medical_content(ocr_text: str) -> dict:
    """
    Phase 11: Scans OCR text for non-medical patterns like student notes, shopping lists, homework, math, etc.
    """
    if not ocr_text:
        return {"is_non_medical": True, "reason": "Empty document"}

    lowered = ocr_text.lower()

    for pattern in NON_MEDICAL_PATTERNS:
        if re.search(pattern, lowered):
            return {
                "is_non_medical": True,
                "reason": "This does not appear to be a medical prescription."
            }

    # Medical terminology / pattern sanity check
    medical_keywords = [
        "rx", "tab", "tablet", "cap", "capsule", "syrup", "inj", "injection",
        "mg", "ml", "mcg", "gm", "g", "dose", "daily", "after food", "before food", "dr", "doctor",
        "patient", "hospital", "clinic", "diagnosis", "report", "test", "blood", "take", "given",
        "1-0-1", "0-0-1", "1-0-0", "0-1-0", "1-1-1", "od", "bd", "tds", "hs", "sos", "stat", "mf", "m.f"
    ]

    has_medical_term = any(term in lowered for term in medical_keywords) or len(lowered.split()) >= 3
    
    if not has_medical_term:
        return {
            "is_non_medical": True,
            "reason": "This does not appear to be a medical prescription."
        }

    return {
        "is_non_medical": False,
        "reason": None
    }
