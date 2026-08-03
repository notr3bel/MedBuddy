import os
import asyncio
from google import genai
from app.services.text_cleaner import remove_markdown


# Reads your API key from the GEMINI_API_KEY environment variable.
# You can also set GOOGLE_API_KEY as an alternative environment variable name.
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))


async def explain_prescription(text: str, language: str = "en") -> str:
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
You are an expert medical assistant specializing in parsing messy doctor prescriptions.

CONTENT:
The following text is OCR-extracted data from a medical prescription. It might contain significant typos or broken text.

OBJECTIVE:
1. Identify ALL medicines listed in the text accurately.
2. For EACH medicine, determine the standard/brand name and the generic equivalent (e.g., "Pan 40 (Pantoprazole)").
3. Use the Brand Name as the main title if identifiable, otherwise use the Generic Name.
4. DO NOT mention typos or spelling corrections. Just provide the finalized correct information.
5. For each medicine, provide exactly these three points in simple, non-medical language:
   - Description: A very simple one-sentence explanation of what this medicine is.
   - Reason for Prescription: Why this is used in simple words.
   - Instructions: Clear timing and dosage instructions based on the text.

FORMAT:
Use markdown for structure (this will be rendered in the app):
Use `###` for Medicine names.
Use `**` for labels like **Description**, **Reason**, and **Instructions**.

Example:
### Pan 40 (Pantoprazole)
**Description**: Reduces stomach acid.
**Reason**: Used for acidity or heartburn.
**Instructions**: Take 1 tablet daily before breakfast.

---

PRESCRIBER TEXT:
{text}

CONSTRAINTS:
- Do NOT skip any medicines.
- USE SIMPLE WORDS.
- Add a brief medical disclaimer at the bottom stating this is an AI interpretation.
- YOUR RESPONSE MUST BE IN THE FOLLOWING LANGUAGE: {target_lang}
"""

    def _generate():
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt,
        )
        text = response.text.strip() if hasattr(response, "text") and response.text else ""
        return text

    return await asyncio.to_thread(_generate)
