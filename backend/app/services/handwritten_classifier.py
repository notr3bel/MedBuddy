import logging
import re

def classify_handwritten_vs_printed(ocr_text: str, azure_lines_confidence: float = 0.8) -> str:
    """
    Phase 9: Automatically classifies image layout as 'Printed', 'Handwritten', or 'Mixed'.
    Logs result internally for auditing.
    """
    if not ocr_text:
        return "Printed"

    lowered = ocr_text.lower()
    
    # Check for printed indicators (hospital header, printed table headers, standard fonts, uniform alignment)
    printed_keywords = ["hospital", "clinic", "department", "tel:", "email:", "reg. no", "dr.", "date:", "address:"]
    printed_count = sum(1 for kw in printed_keywords if kw in lowered)

    # Check for handwritten irregularities (mixed casing, fragmented words, short lines)
    lines = ocr_text.splitlines()
    short_lines = sum(1 for line in lines if 1 <= len(line.strip()) <= 10)
    
    total_lines = len(lines) if len(lines) > 0 else 1
    short_line_ratio = short_lines / total_lines

    if printed_count >= 3 and short_line_ratio < 0.3:
        classification = "Printed"
    elif printed_count >= 1 and short_line_ratio >= 0.3:
        classification = "Mixed"
    else:
        classification = "Handwritten"

    logging.info(f"[Phase 9 Audit] Document Layout Classification: {classification} (Printed Score: {printed_count}, Short Line Ratio: {short_line_ratio:.2f})")
    print(f"[Phase 9 Audit] Document Layout Classification: {classification}")

    return classification
