import os
import io
import asyncio
import json
import re
import time
import logging
from PIL import Image, ImageOps
from google import genai
from google.genai import types

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY") or "DUMMY_KEY")
MODEL_CANDIDATES = ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-1.5-flash"]

def extract_json_object(raw_text: str) -> str:
    """
    Robustly extracts and cleans a JSON object substring from raw model output.
    Handles markdown fences, leading/trailing commentary, trailing commas, and unescaped newlines.
    """
    if not raw_text or not raw_text.strip():
        return ""

    text = raw_text.strip()

    # 1. Strip markdown code fences
    if "```" in text:
        match = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", text, re.IGNORECASE)
        if match:
            text = match.group(1).strip()

    # 2. Extract substring between first '{' and last '}'
    start_idx = text.find("{")
    end_idx = text.rfind("}")
    if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
        text = text[start_idx : end_idx + 1]

    # 3. Clean trailing commas before closing braces/brackets
    text = re.sub(r",\s*([\}\]])", r"\1", text)

    return text

def _call_single_model(model: str, contents: list) -> dict:
    config = types.GenerateContentConfig(
        response_mime_type="application/json",
        temperature=0.1,
        max_output_tokens=1536,
    )
    response = client.models.generate_content(
        model=model,
        contents=contents,
        config=config,
    )

    raw_text = response.text.strip() if hasattr(response, "text") and response.text else ""
    cleaned_json_str = extract_json_object(raw_text)

    parsed = None
    try:
        parsed = json.loads(cleaned_json_str)
    except Exception as parse_err:
        # Repair literal unescaped newlines inside JSON string values
        try:
            repaired = re.sub(r'("(?:[^"\\]|\\.)*")', lambda m: m.group(1).replace('\n', '\\n').replace('\r', '\\r'), cleaned_json_str)
            parsed = json.loads(repaired)
        except Exception:
            raise ValueError(f"JSONDecodeError: {parse_err}")

    if not isinstance(parsed, dict):
        parsed = {}

    for k in ["is_valid_prescription", "verified_text", "medicines", "schedule", "explanation", "precautions"]:
        if k not in parsed:
            if k == "is_valid_prescription":
                parsed[k] = False
            elif k in ["medicines", "schedule", "precautions"]:
                parsed[k] = []
            else:
                parsed[k] = ""

    if not parsed.get("medicines") and parsed.get("schedule"):
        parsed["medicines"] = [
            {"medicine": s.get("medicine", "Prescribed Medication"), "generic": "Prescribed Medication"}
            for s in parsed["schedule"] if isinstance(s, dict) and s.get("medicine")
        ]

    return {"raw_text": raw_text, "parsed": parsed}

async def analyze_prescription_ai(text: str, language: str = "en", image_bytes: bytes | None = None) -> dict:
    """
    Analyzes prescription document using Gemini Multimodal AI.
    Features robust JSON parsing, per-attempt timeout, multi-model retry, and safe fallback.
    """
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
You are an expert medical AI assistant. Analyze this uploaded prescription image and OCR text.

OCR EXTRACTED TEXT (if available):
{text if text else "None"}

LANGUAGES REQUIREMENT:
- The fields "verified_text", "explanation", and "precautions" MUST be written in {target_lang}.
- All medicine names, generic names, duration, timing, and reminder_times must remain in English.

TASK 1: PRESCRIPTION VALIDATION & AUTHENTICITY CHECK
Determine if this image/text is a VALID OFFICIAL DOCTOR'S PRESCRIPTION issued by a clinic, hospital, or healthcare practitioner.

CRITICAL RULES:
- If the image is a self-written list of medicine names, user handwritten note on plain/ruled notebook paper without an official doctor/clinic header, Rx symbol, or doctor credentials, IT IS NOT A VALID PRESCRIPTION.
- Ignore non-medical objects, selfies, animals, cars, food menus, homework, general notes, or non-prescription bills.

IF NOT A VALID OFFICIAL PRESCRIPTION (e.g. Self-written notes, general objects):
Set "is_valid_prescription": false
Set "explanation": "This document appears to be a self-written list of medicine names on plain paper and not an official doctor's prescription.\n\nSelf-written medicine notes or lists on plain/ruled paper are not accepted as valid prescriptions.\n\nPlease upload an official prescription issued by a doctor or clinic."
Set "medicines": [], "schedule": [], "precautions": []

TASK 2: MEDICINE EXTRACTION & BRIEF ANALYSIS (If valid prescription)
1. Set "is_valid_prescription": true
2. Extract all valid prescribed medications into "medicines" array (Brand Name "medicine", Generic Name "generic").
3. Extract structured dosage schedule into "schedule" array:
   - "medicine": Brand/Commercial Name
   - "dosage": Dosage pattern (e.g. "1-0-1", "Once daily", "1 tablet")
   - "duration": Course duration (e.g. "5 days", "1 week", "As needed")
   - "timing": Instruction (e.g. "After Food", "Before Food")
   - "reminder_times": List of HH:MM 24-hour notification times based on dosage:
     - "1-0-0" -> ["08:00"]
     - "0-1-0" -> ["13:00"]
     - "0-0-1" -> ["20:00"]
     - "1-0-1" -> ["08:00", "20:00"]
     - "1-1-1" -> ["08:00", "14:00", "20:00"]
     - Default if unspecified -> ["08:00"]
4. Format "explanation" as a clear, well-structured markdown summary in {target_lang} detailing EACH prescribed medicine in brief:
   ### Prescribed Medicines & Brief Analysis
   For EACH medicine in the prescription, list:
   - **Medicine Name & Generic Compound**
   - **Medical Purpose**: What it is prescribed for (e.g., Antibiotic for infection, Anti-inflammatory pain reliever, Acid reflux reducer, Antiseptic gum paint).
   - **Dosage & Timing**: When and how to take it (e.g., Morning before food, Night after food).
   - **Duration**: Course duration.

   ### Key Precautions & Advice
   - Important medical advice and usage precautions.

5. Provide key precautions in {target_lang} under "precautions".

CONSTRAINTS:
- Do NOT include doctor contact numbers, hospital address, patient address, or emails.
- Return raw JSON ONLY without markdown wrapping (no ```json).

JSON FORMAT:
{{
    "is_valid_prescription": true,
    "verified_text": "...",
    "medicines": [
        {{"medicine": "Dolo 650", "generic": "Paracetamol"}}
    ],
    "schedule": [
        {{
            "medicine": "Dolo 650",
            "dosage": "1-0-1",
            "duration": "5 days",
            "timing": "After Food",
            "reminder_times": ["08:00", "20:00"]
        }}
    ],
    "explanation": "...",
    "precautions": ["..."]
}}
"""

    contents = []
    if image_bytes and len(image_bytes) > 100:
        try:
            pil_img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
            try:
                pil_img = ImageOps.exif_transpose(pil_img)
            except Exception:
                pass
            contents.append(pil_img)
        except Exception as ie:
            logging.warning(f"Could not load image bytes into PIL: {ie}")

    contents.append(prompt)

    total_gemini_start = time.time()
    retry_count = 0

    for model in MODEL_CANDIDATES:
        retry_count += 1
        print(f"\n[DEBUG GEMINI] Retry Count: {retry_count} / {len(MODEL_CANDIDATES)}")
        print(f"[DEBUG GEMINI] Selected Model: {model}")
        print(f"[DEBUG GEMINI] Endpoint URL: https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent")
        print(f"[DEBUG GEMINI] Payload Summary: text_len={len(text or '')}, image_bytes={len(image_bytes) if image_bytes else 0}")
        
        attempt_start = time.time()
        try:
            # Enforce 6-second timeout per attempt
            result_dict = await asyncio.wait_for(
                asyncio.to_thread(_call_single_model, model, contents),
                timeout=6.0
            )
            attempt_dur = time.time() - attempt_start
            raw_text = result_dict.get("raw_text", "")
            parsed = result_dict.get("parsed")

            if isinstance(parsed, dict):
                print(f"[DEBUG GEMINI] Response Status: SUCCESS (200 OK)")
                print(f"[DEBUG GEMINI] Response Length: {len(raw_text)}")
                print(f"[DEBUG GEMINI] JSON Extraction Success: TRUE")
                print(f"[DEBUG GEMINI] JSON Parsing Success: TRUE")
                print(f"[DEBUG GEMINI] Final Selected Model: {model}")
                print(f"[DEBUG GEMINI] Fallback Activated: FALSE")
                return parsed

        except asyncio.TimeoutError:
            attempt_dur = time.time() - attempt_start
            print(f"[DEBUG GEMINI ERROR] Timeout Triggered after {attempt_dur:.2f}s for model {model}")
        except Exception as err:
            attempt_dur = time.time() - attempt_start
            print(f"[DEBUG GEMINI ERROR] Model {model} request/parse failed after {attempt_dur:.2f}s: {err}")

    total_dur = time.time() - total_gemini_start
    print(f"\n[DEBUG GEMINI ERROR] All Gemini candidate model attempts failed. Total duration: {total_dur:.2f}s")
    print("[FALLBACK ACTIVATED] Preserving OCR and candidate validation results.")
    print(f"[DEBUG GEMINI] Fallback Activated: TRUE")
    print(f"[DEBUG GEMINI] Final Selected Model: NONE (Fallback)")

    has_text = bool(text and len(text.strip()) >= 3)
    return {
        "is_valid_prescription": has_text,
        "verified_text": text or "",
        "medicines": [],
        "schedule": [],
        "explanation": "AI explanation is temporarily unavailable. OCR extraction completed successfully.",
        "precautions": [],
        "fallback_activated": True
    }

