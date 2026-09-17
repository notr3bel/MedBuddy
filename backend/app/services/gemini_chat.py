from typing import Optional
import os
import asyncio
import logging
from google import genai
from google.genai import types
from app.services.text_cleaner import remove_markdown
from app.services.supabase_client import get_user_recent_history

# Setup logging
logging.basicConfig(filename="gemini_debug.log", level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL = "gemini-3.6-flash"


async def get_chat_response(query: str, language: str = "en", user_id: Optional[str] = None) -> str:
    logging.info(f"Received query: {query} in language: {language} for user: {user_id}")
    lang_map = {
        "hi": "Hindi",
        "kn": "Kannada",
        "ta": "Tamil",
        "ml": "Malayalam",
        "te": "Telugu",
        "en": "English"
    }
    target_lang = lang_map.get(language, "English")

    history_records = await get_user_recent_history(user_id=user_id, limit=5)
    
    history_context = ""
    if history_records:
        history_lines = []
        for idx, item in enumerate(history_records, 1):
            item_type = str(item.get("type", "analysis")).upper()
            item_date = str(item.get("created_at", "Recent"))
            item_result = str(item.get("result", ""))
            if len(item_result) > 1500:
                item_result = item_result[:1500] + "... [truncated]"
            history_lines.append(f"Record #{idx} [{item_type} - {item_date}]:\n{item_result}")
        history_context = "\n\n".join(history_lines)

    prompt = f"""
You are MedIntel AI Voice Assistant.
You have direct access to the user's recent medical history and analysis records below:

--- USER RECENT MEDICAL HISTORY ---
{history_context if history_context else "No prior history records found for this user."}
-----------------------------------

User Query:
"{query}"

INSTRUCTIONS:
1. If the user asks about their recent prescription, medical report, skin analysis, symptoms, or health history (e.g., "explain my prescription", "tell me about my recent prescription analysis", "explain my report"), retrieve the relevant details from USER RECENT MEDICAL HISTORY above and explain the findings, detected medications, dosages, or lab results clearly.
2. If history records are present in USER RECENT MEDICAL HISTORY, DO NOT say you cannot access their medical records or prescription details.
3. If the user asks general health questions, provide safe, accurate, and educational guidance.
4. DO NOT provide definitive diagnoses or replace a doctor's advice.
5. USE PLAIN TEXT ONLY. Do NOT use markdown symbols like hashtags (#), asterisks (*), or bold text formatting so that your response can be spoken cleanly by Text-to-Speech.
6. YOUR RESPONSE MUST BE IN THE FOLLOWING LANGUAGE: {target_lang}
"""

    async def _call_gemini():
        try:
            def _generate() -> str:
                config = types.GenerateContentConfig(
                    max_output_tokens=512,
                    temperature=0.7,
                )
                response = client.models.generate_content(
                    model=MODEL,
                    contents=prompt,
                    config=config,
                )
                text = response.text.strip() if hasattr(response, "text") and response.text else ""
                return remove_markdown(text)
            
            return await asyncio.to_thread(_generate)
        except Exception as e:
            logging.error(f"Gemini API Error: {str(e)}")
            return f"Error: {str(e)}"

    return await _call_gemini()
