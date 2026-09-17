import time
import uuid
import logging
from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI, Request, Response, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.routes.health import router as health_router
from app.routes.prescription import router as prescription_router
from app.routes.report import router as report_router
from app.routes.skin import router as skin_router
from app.routes.chat import router as chat_router
from app.routes.symptoms import router as symptoms_router
from app.routes.model import router as model_router
from app.routes.reminders import router as reminders_router

from app.services.resilience import (
    is_rate_limited,
    run_startup_checks,
    METRICS,
    http_exception_handler,
    validation_exception_handler,
    unhandled_exception_handler
)

app = FastAPI(
    title="MedIntel API",
    description="Backend services for Medical Assistance Mobile App",
    version="1.0.0"
)

# Run startup diagnostic checks
run_startup_checks()

# Centralized Exception Handling (Task 11)
app.add_exception_handler(HTTPException, http_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request-ID, Rate-Limiting, & Latency Metrics Middleware (Task 11)
@app.middleware("http")
async def reliability_middleware(request: Request, call_next):
    start_time = time.time()
    request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
    request.state.request_id = request_id

    # Rate limiting check
    client_ip = request.client.host if request.client else "127.0.0.1"
    if is_rate_limited(client_ip):
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={
                "success": False,
                "error": "Rate limit exceeded. Maximum 60 requests per minute.",
                "request_id": request_id
            }
        )

    # File payload size validation (Max 20MB)
    content_length = request.headers.get("content-length")
    if content_length and int(content_length) > 20 * 1024 * 1024:
        return JSONResponse(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            content={
                "success": False,
                "error": "File size exceeds the 20MB maximum limit.",
                "request_id": request_id
            }
        )

    response: Response = await call_next(request)
    duration_ms = (time.time() - start_time) * 1000.0
    METRICS.record_request(duration_ms)

    # Reliability & Correlation Headers (Task 11)
    response.headers["X-Request-ID"] = request_id
    response.headers["X-Response-Time-MS"] = f"{duration_ms:.2f}"

    # Security Hardening Headers (Task 14)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response

app.include_router(health_router)
app.include_router(prescription_router)
app.include_router(report_router)
app.include_router(skin_router)
app.include_router(chat_router)
app.include_router(symptoms_router)
app.include_router(model_router)
app.include_router(reminders_router)

@app.get("/")
def root():
    return {"status": "Backend running successfully"}
