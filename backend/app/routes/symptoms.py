from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
import os
import asyncio
import re
from google import genai
from app.services.text_cleaner import remove_markdown
from app.services.supabase_client import save_analysis_history

router = APIRouter(prefix="/api")

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL = "gemini-2.5-flash"

class SymptomRequest(BaseModel):
    symptoms: str
    user_id: Optional[str] = None
    lang: str = "en"

@router.post("/symptoms")
async def check_symptoms(req: SymptomRequest):
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
{req.symptoms}

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
        response = client.models.generate_content(
            model=MODEL,
            contents=prompt,
        )
        return response.text if hasattr(response, "text") and response.text else "I am sorry, I couldn't understand that."

    ai_response = await asyncio.to_thread(_generate)

    if req.user_id:
        await save_analysis_history(req.user_id, "symptom", ai_response)

    return {"response": ai_response}
