import os
import asyncio
from google import genai
from app.services.text_cleaner import remove_markdown

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL = "gemini-2.5-flash"

async def summarize_medical_report(report_text: str, language: str = "en"):
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
You are an expert medical report analyzer. Your goal is to provide a very concise, easy-to-read summary of a medical report.

Your job:
1. Provide a "Health Status Overview" (Briefly state if the report is generally normal or has issues).
2. List "Key Findings": Only the most important test results, especially abnormal ones.
3. Use markdown for structure:
   - Use `###` for headings.
   - Use `**` for bolding important values or test names.
   - Use `> **⚠️ Warning:**` for abnormal values or urgent notes.
4. Add a "Suggestions & Next Steps" section based on the findings.
5. Count the total number of abnormal results.
6. YOUR RESPONSE MUST BE VALID JSON ONLY, with these exact keys:
   - "summary": A well-structured markdown string in {target_lang}.
   - "abnormal_count": An integer counting the abnormal results.

Rules:
- Keep it concise. Do NOT list every single normal value if there are many. Focus on what matters.
- Do NOT diagnose diseases or suggest specific medications. 
- Suggest consulting a doctor for any abnormal findings.
- Ensure the markdown is clean and professional.

Medical report text:
{report_text}
"""

    def _generate() -> dict:
        import json
        response = client.models.generate_content(
            model=MODEL,
            contents=prompt,
        )
        text = response.text if hasattr(response, "text") and response.text else "{}"
        # Clean json backticks if any
        if text.startswith("```json"):
            text = text[7:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()
        try:
            parsed = json.loads(text)
            return parsed
        except Exception:
            # Fallback
            return {"summary": text, "abnormal_count": 0}

    return await asyncio.to_thread(_generate)

