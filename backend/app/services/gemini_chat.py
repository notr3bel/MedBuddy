import os
import asyncio
import logging
from google import genai
from app.services.text_cleaner import remove_markdown

# Setup logging
logging.basicConfig(filename="gemini_debug.log", level=logging.INFO, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL = "gemini-2.5-flash"


async def get_chat_response(query: str, language: str = "en") -> str:
    logging.info(f"Received query: {query} in language: {language}")
    lang_map = {
        "hi": "Hindi",
        "kn": "Kannada",
        "ta": "Tamil",
        "ml": "Malayalam",
        "te": "Telugu",
        "en": "English"
    }
    target_lang = lang_map.get(language, "English")

    prompt = f"""
You are a medical assistant chatbot. 
Answer the user's medical query clearly and concisely.

RULES:
- Handle general health questions, medicine usage, and symptom awareness.
- DO NOT provide definitive diagnoses.
- DO NOT replace a doctor's advice.
- ALWAYS add a medical disclaimer at the end.
- USE PLAIN TEXT ONLY. Do NOT use markdown symbols like hashtags (#), asterisks (*), or bold text formatting.
- YOUR RESPONSE MUST BE IN THE FOLLOWING LANGUAGE: {target_lang}

User Query:
{query}
"""

    async def _call_gemini():
        try:
            def _generate() -> str:
                response = client.models.generate_content(
                    model=MODEL,
                    contents=prompt,
                    config={
                        "max_output_tokens": 512,
                        "temperature": 0.7,
                    },
                )
                text = response.text.strip() if hasattr(response, "text") and response.text else ""
                return remove_markdown(text)
            
            return await asyncio.to_thread(_generate)
        except Exception as e:
            logging.error(f"Gemini API Error: {str(e)}")
            return f"Error: {str(e)}"

    return await _call_gemini()
