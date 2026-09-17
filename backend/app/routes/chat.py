from typing import Optional
from fastapi import APIRouter, Form, HTTPException
from app.services.gemini_chat import get_chat_response
from app.services.security import sanitize_prompt_text
from app.services.structured_logger import log_audit_event
import time

router = APIRouter(prefix="/api")

@router.post("/chat")
async def chat_with_assistant(
    query: str = Form(...),
    lang: str = Form("en"),
    user_id: Optional[str] = Form(None)
):
    start_time = time.time()
    
    if not query or len(query.strip()) == 0:
        return {"success": False, "response": "Please enter a valid medical question."}
        
    sanitized_query = sanitize_prompt_text(query)
    
    try:
        response_text = await get_chat_response(sanitized_query, language=lang, user_id=user_id)
        log_audit_event("chat_query", time.time() - start_time, status="SUCCESS")
        return {
            "success": True,
            "response": response_text
        }
    except Exception as e:
        log_audit_event("chat_failed", time.time() - start_time, status="FAILURE")
        return {
            "success": False,
            "response": "Medical Assistant service is temporarily busy. Please try again shortly."
        }
