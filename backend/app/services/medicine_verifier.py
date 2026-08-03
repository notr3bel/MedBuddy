"""
Verify medicine names extracted by Azure OCR using TrOCR.

For now this module identifies likely medicine lines and returns the
original text unchanged. TrOCR-based verification will be added later.
"""

MEDICINE_KEYWORDS = (
    "tab",
    "tablet",
    "cap",
    "capsule",
    "syp",
    "syrup",
    "inj",
    "mg",
    "ml",
)


def _is_likely_medicine_line(line: str) -> bool:
    lowered = line.lower()
    return any(keyword in lowered for keyword in MEDICINE_KEYWORDS)


async def verify_medicine_names(text: str) -> str:
    """
    Verify medicine names in OCR text.

    Currently returns the original text unchanged after identifying
    likely medicine lines. TrOCR verification will be added later.
    """
    if not text or not text.strip():
        return text

    lines = text.splitlines()
    medicine_lines = []

    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue

        if _is_likely_medicine_line(stripped):
            medicine_lines.append(stripped)

    # TODO: Load prescription image and run TrOCR on medicine regions.
    # TODO: Compare TrOCR output with Azure OCR medicine lines.
    # TODO: Replace or correct medicine names when TrOCR confidence is high.
    # TODO: Keep original text for non-medicine lines and low-confidence cases.

    _ = medicine_lines

    return text
