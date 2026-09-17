import logging
import asyncio
import time
import os
from collections import defaultdict
from fastapi import Request, HTTPException, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from app.services.supabase_client import supabase

logger = logging.getLogger("medintel.resilience")

# Rate limiting tracking (IP -> list of request timestamps)
_rate_limit_records = defaultdict(list)
RATE_LIMIT_MAX = 60
RATE_LIMIT_WINDOW_SEC = 60.0

def is_rate_limited(client_ip: str) -> bool:
    now = time.time()
    timestamps = _rate_limit_records[client_ip]
    # Remove timestamps older than window
    _rate_limit_records[client_ip] = [ts for ts in timestamps if now - ts < RATE_LIMIT_WINDOW_SEC]
    if len(_rate_limit_records[client_ip]) >= RATE_LIMIT_MAX:
        return True
    _rate_limit_records[client_ip].append(now)
    return False

def run_startup_checks():
    logger.info("Running MedIntel system startup checks...")
    gemini_key = os.getenv("GEMINI_API_KEY")
    if not gemini_key:
        logger.warning("GEMINI_API_KEY is not set in environment variables.")
    else:
        logger.info("GEMINI_API_KEY configured.")
    if supabase is None:
        logger.warning("Supabase client is not connected.")
    else:
        logger.info("Supabase client initialized.")

class SystemMetrics:
    def __init__(self):
        self.total_requests = 0
        self.total_latency_ms = 0.0
        self.ocr_failures = 0
        self.gemini_retries = 0
        self.cache_hits = 0
        self.cache_misses = 0

    def record_request(self, duration_ms: float):
        self.total_requests += 1
        self.total_latency_ms += duration_ms

    def get_metrics_summary(self):
        avg_latency = (self.total_latency_ms / self.total_requests) if self.total_requests > 0 else 0.0
        return {
            "total_requests": self.total_requests,
            "avg_latency_ms": round(avg_latency, 2),
            "ocr_failures": self.ocr_failures,
            "gemini_retries": self.gemini_retries,
            "cache_hits": self.cache_hits,
            "cache_misses": self.cache_misses
        }

METRICS = SystemMetrics()

async def http_exception_handler(request: Request, exc: Exception):
    request_id = getattr(request.state, "request_id", "N/A")
    status_code = exc.status_code if isinstance(exc, HTTPException) else status.HTTP_500_INTERNAL_SERVER_ERROR
    detail = exc.detail if isinstance(exc, HTTPException) else str(exc)
    return JSONResponse(
        status_code=status_code,
        content={
            "success": False,
            "error": detail,
            "request_id": request_id
        }
    )

async def validation_exception_handler(request: Request, exc: Exception):
    request_id = getattr(request.state, "request_id", "N/A")
    details = exc.errors() if isinstance(exc, RequestValidationError) else []
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "success": False,
            "error": "Invalid request payload format.",
            "details": details,
            "request_id": request_id
        }
    )

async def unhandled_exception_handler(request: Request, exc: Exception):
    request_id = getattr(request.state, "request_id", "N/A")
    logger.error(f"Unhandled Exception for Request {request_id}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "error": "An internal server error occurred.",
            "request_id": request_id
        }
    )

async def get_system_health_status():
    gemini_ok = bool(os.getenv("GEMINI_API_KEY"))
    supabase_ok = supabase is not None
    return {
        "status": "healthy" if (gemini_ok and supabase_ok) else "degraded",
        "gemini_ai": "operational" if gemini_ok else "unconfigured",
        "supabase_db": "connected" if supabase_ok else "disconnected",
        "azure_vision_ocr": "operational",
        "trocr_gpu": "operational"
    }

def is_transient_error(exception: Exception) -> bool:
    """
    Identifies retryable network / API errors.
    """
    err_str = str(exception).lower()
    retryable_keywords = ["timeout", "503", "502", "504", "connection reset", "rate limit", "429"]
    return any(kw in err_str for kw in retryable_keywords)

async def execute_with_retry(async_fn, *args, max_attempts: int = 3, **kwargs):
    """
    Executes async function with automatic retries and exponential backoff.
    """
    attempt = 0
    delay = 1.0

    while attempt < max_attempts:
        try:
            return await async_fn(*args, **kwargs)
        except Exception as e:
            attempt += 1
            if attempt >= max_attempts or not is_transient_error(e):
                logger.error(f"Execution failed after attempt {attempt}: {e}")
                raise e
            logger.warning(f"Transient failure (attempt {attempt}/{max_attempts}): {e}. Retrying in {delay}s...")
            await asyncio.sleep(delay)
            delay *= 2.0
