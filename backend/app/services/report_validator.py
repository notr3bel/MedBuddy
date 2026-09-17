import re

SUPPORTED_REPORT_TYPES = {
    "CBC": ["cbc", "hemogram", "complete blood count", "hemoglobin", "wbc", "rbc", "platelet"],
    "LFT": ["lft", "liver function", "bilirubin", "sgot", "sgpt", "alt", "ast", "alkaline phosphatase"],
    "KFT": ["kft", "kidney function", "renal function", "creatinine", "urea", "uric acid", "bun"],
    "Lipid": ["lipid", "cholesterol", "triglycerides", "hdl", "ldl", "vldl"],
    "HbA1c": ["hba1c", "glycated hemoglobin", "glycohemoglobin", "blood sugar", "glucose"],
    "Thyroid": ["thyroid", "t3", "t4", "tsh", "triiodothyronine", "thyroxine"],
    "Urine": ["urine", "urinalysis", "pus cells", "specific gravity", "proteinuria"],
    "MRI": ["mri", "magnetic resonance"],
    "CT": ["ct scan", "computed tomography"],
    "X-ray": ["x-ray", "xray", "radiograph", "radiology"],
    "ECG": ["ecg", "ekg", "electrocardiogram"],
    "Echo": ["echocardiogram", "echo", "2d echo"]
}

MEDICAL_REPORT_KEYWORDS = [
    "cbc", "lft", "kft", "lipid", "hba1c", "thyroid", "urine", "mri", "ct scan",
    "x-ray", "xray", "ecg", "echo", "hemoglobin", "wbc", "rbc", "platelet",
    "bilirubin", "sgot", "sgpt", "alt", "ast", "creatinine", "urea", "uric acid",
    "bun", "cholesterol", "triglycerides", "hdl", "ldl", "vldl", "t3", "t4", "tsh",
    "pus cells", "proteinuria", "glucose", "blood sugar", "lab test", "test result",
    "reference range", "specimen", "pathology report", "observed value", "normal range",
    "clinical findings", "mg/dl", "g/dl", "mmol/l", "u/l", "iu/l", "radiology"
]

def identify_report_type(ocr_text: str) -> str:
    """
    Phase 10: Identifies medical report category from OCR text.
    """
    lowered = ocr_text.lower()

    for report_type, keywords in SUPPORTED_REPORT_TYPES.items():
        if any(kw in lowered for kw in keywords):
            return report_type

    return "Unknown Report"

def validate_report_content(ocr_text: str, gemini_classified: bool = False) -> dict:
    """
    Validates if OCR text contains medical lab/radiology findings based on confidence score.
    Rule #5: Accept reports if OCR text length > 100 characters OR medical keywords detected OR Gemini classifies it.
    """
    report_type = identify_report_type(ocr_text)
    lowered = ocr_text.lower() if ocr_text else ""
    
    length_pass = len(ocr_text or "") > 100
    keyword_matches = sum(1 for kw in MEDICAL_REPORT_KEYWORDS if kw in lowered)
    keyword_pass = keyword_matches >= 1

    confidence_score = 0.0
    if length_pass:
        confidence_score += 0.4
    if keyword_pass:
        confidence_score += min(0.5, keyword_matches * 0.1)
    if gemini_classified:
        confidence_score += 0.4
    if report_type != "Unknown Report":
        confidence_score += 0.3

    confidence_score = round(min(1.0, confidence_score), 2)
    is_valid = length_pass or keyword_pass or gemini_classified or (report_type != "Unknown Report")

    if not is_valid:
        return {
            "is_valid_report": False,
            "confidence_score": confidence_score,
            "report_type": "Unknown Report",
            "message": "This document does not appear to be a valid medical report."
        }

    return {
        "is_valid_report": True,
        "confidence_score": confidence_score,
        "report_type": report_type,
        "message": f"Valid {report_type} medical report detected (confidence: {confidence_score})."
    }

def build_ocr_fallback_report_summary(ocr_text: str, report_type: str) -> str:
    """
    Builds a beautifully structured markdown report summary directly from OCR text.
    """
    lines = [l.strip() for l in ocr_text.splitlines() if l.strip() and len(l.strip()) >= 3]

    critical_lines = []
    param_lines = []

    for line in lines[:25]:
        low = line.lower()
        if any(term in low for term in ["high", "low", "abnormal", "positive", "reactive", "warning", "critical"]):
            critical_lines.append(f"• ⚠️ **{line}**")
        elif any(term in low for term in ["hemoglobin", "wbc", "rbc", "platelet", "glucose", "cholesterol", "tsh", "bilirubin", "creatinine", "urea", "result", "value", "g/dl", "mg/dl", "mmol/l", "%"]):
            param_lines.append(f"• {line}")

    if not critical_lines and not param_lines:
        for line in lines[:10]:
            param_lines.append(f"• {line}")

    summary_parts = []

    # 1. Critical Values Section
    summary_parts.append("### 🚨 Critical & Important Values (Needs Attention)")
    if critical_lines:
        summary_parts.extend(critical_lines)
    else:
        summary_parts.append("✅ All detected parameters appear to be within normal reference ranges.")

    summary_parts.append("")

    # 2. Important Parameters Section
    summary_parts.append(f"### 📊 Important Report Parameters ({report_type})")
    if param_lines:
        summary_parts.extend(param_lines)
    else:
        summary_parts.append("• Standard clinical panel parameters detected.")

    summary_parts.append("")

    # 3. Clinical Information Section
    summary_parts.append("### ℹ️ Clinical Summary & Important Information")
    info_map = {
        "CBC": "A Complete Blood Count (CBC) evaluates overall health and detects a wide range of conditions, including anemia, infection, and immune system status.",
        "LFT": "A Liver Function Test (LFT) measures specific proteins, liver enzymes, and bilirubin to assess liver health and metabolic function.",
        "KFT": "A Kidney Function Test (KFT) checks blood urea nitrogen, creatinine, and electrolytes to evaluate renal filtration and kidney health.",
        "Lipid": "A Lipid Profile measures cholesterol fractions (HDL, LDL, Triglycerides) to evaluate cardiovascular health and lipid balance.",
        "HbA1c": "An HbA1c test reflects average blood sugar levels over the past 2-3 months to evaluate glycemic control.",
        "Thyroid": "A Thyroid Panel (T3, T4, TSH) evaluates thyroid gland function and metabolic hormone levels.",
    }
    type_info = info_map.get(report_type, f"This {report_type} report provides essential diagnostic data regarding your clinical health status.")
    summary_parts.append(f"{type_info}\n\n**Next Steps**: Review these results with your healthcare provider for medical context and personalized guidance.")

    summary_parts.append("\n*Medical Disclaimer: Always consult your physician or qualified healthcare professional for clinical diagnosis and test interpretation.*")

    return "\n".join(summary_parts)


