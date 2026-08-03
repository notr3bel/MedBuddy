import os
import asyncio
import json
import re
from google import genai

client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY")
)

async def extract_medicine_schedule(text: str):

    prompt = f"""
You are a medical prescription parser.

Extract all medicines from this prescription.

Return ONLY a valid JSON array.
Do not use markdown.
Do not use ```json blocks.
Do not add explanations.

Format:

[
  {{
    "medicine": "Pan 40",
    "dosage": "1-0-1",
    "duration": "5 days",
    "timing": "Before Food"
  }}
]

Prescription:

{text}
"""

    def _generate():
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=prompt
        )

        text = response.text.strip()
        text = re.sub(r"```json", "", text)
        text = re.sub(r"```", "", text)

        try:
            return json.loads(text)
        except Exception:
            return []

    return await asyncio.to_thread(_generate)