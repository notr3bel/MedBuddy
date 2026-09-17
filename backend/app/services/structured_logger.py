import json
import logging
import time
import re

# Configure base logger
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("medintel.audit")

PII_PATTERNS = [
    (r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b", "[REDACTED_EMAIL]"),
    (r"\b(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b", "[REDACTED_PHONE]"),
    (r"\b\d{4}[-\s]?\d{4}[-\s]?\d{4}\b", "[REDACTED_ID]")
]

def sanitize_pii(text: str) -> str:
    """
    Scrubs sensitive PII before writing logs.
    """
    if not text:
        return ""
    sanitized = text
    for pattern, replacement in PII_PATTERNS:
        sanitized = re.sub(pattern, replacement, sanitized)
    return sanitized

def log_audit_event(
    event_type: str,
    processing_time_sec: float,
    ocr_duration_sec: float = 0.0,
    gemini_duration_sec: float = 0.0,
    doc_type: str = "Unknown",
    confidence_score: float = 1.0,
    medicine_count: int = 0,
    status: str = "SUCCESS",
    warnings: list[str] | None = None
):
    """
    Phase 15: Log structured performance, safety, and operational metrics without logging PII.
    """
    log_data = {
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
        "event_type": event_type,
        "status": status,
        "processing_time_sec": round(processing_time_sec, 3),
        "ocr_duration_sec": round(ocr_duration_sec, 3),
        "gemini_duration_sec": round(gemini_duration_sec, 3),
        "doc_type": doc_type,
        "confidence_score": round(confidence_score, 2),
        "medicine_count": medicine_count,
        "warnings": warnings or []
    }
    
    logger.info(f"[AUDIT_LOG] {json.dumps(log_data)}")
    print(f"[AUDIT_LOG] {json.dumps(log_data)}")
