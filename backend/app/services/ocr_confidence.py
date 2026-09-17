import re

def evaluate_ocr_confidence(text: str) -> dict:
    """
    Phase 5: Calculates OCR confidence and checks heuristics.
    Returns:
    {
        "pass_confidence": bool,
        "score": float,
        "reason": str | None
    }
    """
    if not text or not text.strip():
        return {
            "pass_confidence": False,
            "score": 0.0,
            "reason": "Unable to confidently read the document."
        }

    raw = text.strip()
    
    # 1. Length check: Very little text (< 8 characters or < 2 words)
    words = raw.split()
    if len(raw) < 8 or len(words) < 2:
        return {
            "pass_confidence": False,
            "score": 0.1,
            "reason": "Unable to confidently read the document."
        }

    # 2. Symbol ratio check (non-alphanumeric ratio)
    alphanumeric_count = sum(1 for c in raw if c.isalnum())
    total_chars = len(raw)
    symbol_ratio = (total_chars - alphanumeric_count) / total_chars

    if symbol_ratio > 0.75:
        return {
            "pass_confidence": False,
            "score": 0.2,
            "reason": "Unable to confidently read the document."
        }

    # 3. Repeated characters heuristic (e.g., "aaaaa", "11111", "%%%%%")
    repeated_pattern = re.search(r"(.)\1{4,}", raw)
    if repeated_pattern:
        return {
            "pass_confidence": False,
            "score": 0.25,
            "reason": "Unable to confidently read the document."
        }

    # 4. Dictionary / Word structure sanity check (ratio of single char words or pure gibberish)
    single_char_words = sum(1 for w in words if len(w) == 1 and w.lower() not in {"a", "i", "x"})
    if len(words) > 5 and (single_char_words / len(words)) > 0.4:
        return {
            "pass_confidence": False,
            "score": 0.3,
            "reason": "Unable to confidently read the document."
        }

    # Calculate overall confidence score between 0.0 and 1.0
    confidence_score = round(1.0 - (symbol_ratio * 0.5), 2)

    return {
        "pass_confidence": True,
        "score": confidence_score,
        "reason": None
    }
