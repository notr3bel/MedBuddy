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

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY") or "DUMMY_KEY")
MODEL = "gemini-2.5-flash"

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
            max_output_tokens=512,
            temperature=0.4,
            thinking_config=types.ThinkingConfig(thinking_budget=0),
        )
        response = client.models.generate_content(
            model=MODEL,
            contents=prompt,
            config=config,
        )
        return response.text if hasattr(response, "text") and response.text else "I am sorry, I couldn't process your request."

    try:
        ai_response = await asyncio.to_thread(_generate)
        if req.user_id:
            await save_analysis_history(req.user_id, "symptom", ai_response)

        log_audit_event("symptoms_check", time.time() - start_time, status="SUCCESS")
        return {"response": ai_response}
    except Exception as e:
        log_audit_event("symptoms_failed", time.time() - start_time, status="FAILURE")
        return {"response": "Symptom checker is temporarily unavailable. Please try again shortly."}
