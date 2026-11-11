from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
import os
import asyncio
import time
from dotenv import load_dotenv
from google import genai
from google.genai import types
from app.services.supabase_client import save_analysis_history
from app.services.security import sanitize_prompt_text
from app.services.structured_logger import log_audit_event

load_dotenv()

router = APIRouter(prefix="/api")

client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY") or "DUMMY_KEY",
    http_options=types.HttpOptions(
        timeout=12000,
        retry_options=types.HttpRetryOptions(attempts=1),
    ),
)
MODEL_CANDIDATES = ["gemini-3.1-flash-lite", "gemini-flash-lite-latest", "gemini-3.5-flash-lite", "gemini-2.5-flash"]

class SymptomRequest(BaseModel):
    symptoms: str
    user_id: Optional[str] = None
    lang: str = "en"

@router.post("/symptoms")
async def check_symptoms(req: SymptomRequest):
    start_time = time.time()
    
    if not req.symptoms or len(req.symptoms.strip()) == 0:
        return {"response": "Please describe your symptoms in detail."}

    sanitized_symptoms = sanitize_prompt_text(req.symptoms)

    lang_map = {
        "hi": "Hindi",
        "kn": "Kannada",
        "ta": "Tamil",
        "ml": "Malayalam",
        "te": "Telugu",
        "en": "English"
    }
    target_lang = lang_map.get(req.lang, "English")

    prompt = f"""
You are a helpful and expert medical symptom checker assistant.

The user reports the following symptoms:
{sanitized_symptoms}

Provide a well-structured, educational response including:
1. ### Possible Causes (Keep it broad and professional)
2. ### Basic Care Advice
3. ### When to Consult a Doctor

CRITICAL RULES:
- Use markdown for structure (### for headings, ** for bold keywords).
- Do NOT provide a definitive medical diagnosis.
- Do NOT prescribe medications.
- Emphasize that you are an AI.
- Keep the response concise and easy to read.
- YOUR RESPONSE MUST BE IN THE FOLLOWING LANGUAGE: {target_lang}
"""
    def _generate() -> str:
        config = types.GenerateContentConfig(
            max_output_tokens=1024,
            temperature=0.4,
        )
        for model_name in MODEL_CANDIDATES:
            try:
                response = client.models.generate_content(
                    model=model_name,
                    contents=prompt,
                    config=config,
                )
                txt = response.text if hasattr(response, "text") and response.text else ""
                if txt and txt.strip():
                    return txt.strip()
            except Exception as ex:
                if "403" in str(ex) or "PERMISSION_DENIED" in str(ex):
                    raise
                continue
        return "I am sorry, I couldn't process your request."

    try:
        ai_response = await asyncio.to_thread(_generate)
        if req.user_id:
            await save_analysis_history(req.user_id, "symptom", ai_response)

        log_audit_event("symptoms_check", time.time() - start_time, status="SUCCESS")
        return {"response": ai_response}
    except Exception as e:
        log_audit_event("symptoms_failed", time.time() - start_time, status="FAILURE")
        return {"response": "Symptom checker is temporarily unavailable. Please try again shortly."}
