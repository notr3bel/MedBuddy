import os
import io
import asyncio
import json
import re
import logging
import time
from PIL import Image, ImageOps
from google import genai
from google.genai import types

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY") or "DUMMY_KEY")
MODEL_CANDIDATES = ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-1.5-flash"]

def extract_json_object(raw_text: str) -> str:
    if not raw_text or not raw_text.strip():
        return ""
    text = raw_text.strip()
    if "```" in text:
        match = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", text, re.IGNORECASE)
        if match:
            text = match.group(1).strip()
    start_idx = text.find("{")
    end_idx = text.rfind("}")
    if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
        text = text[start_idx : end_idx + 1]
    return text

def _call_single_report_model(model: str, contents: list, report_text: str) -> dict:
    config = types.GenerateContentConfig(
        response_mime_type="application/json",
        temperature=0.1,
        max_output_tokens=512,
    )
    response = client.models.generate_content(
        model=model,
        contents=contents,
        config=config,
    )

    text = response.text.strip() if hasattr(response, "text") and response.text else ""
    cleaned_json_str = extract_json_object(text)

    parsed = None
    try:
        parsed = json.loads(cleaned_json_str)
    except Exception:
        parsed = {}

    if not isinstance(parsed, dict):
        parsed = {}

    if "is_valid_report" not in parsed:
        parsed["is_valid_report"] = bool(parsed.get("summary") and "doesn't seem to be a report" not in str(parsed.get("summary")))
    if "summary" not in parsed:
        parsed["summary"] = text
    if "abnormal_count" not in parsed:
        parsed["abnormal_count"] = 0
    if "report_type" not in parsed:
        parsed["report_type"] = "Medical Report"

    return {"raw_text": text, "parsed": parsed}

async def summarize_medical_report(report_text: str, language: str = "en", image_bytes: bytes | None = None) -> dict:
    """
    Analyzes medical report using Gemini Multimodal AI Vision with candidate model retries and 6s attempt timeouts.
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
You are an expert medical report analyzer AI. Analyze this uploaded medical report image and OCR text.

OCR EXTRACTED TEXT (if available):
{report_text if report_text else "None"}

LANGUAGES REQUIREMENT:
- The "summary" field MUST be written in {target_lang}.

TASK 1: REPORT VALIDATION & CLASSIFICATION
Determine if this image/text is a VALID MEDICAL REPORT or LAB TEST / RADIOLOGY / PATHOLOGY / CLINICAL FINDINGS REPORT (e.g. Blood Test, CBC, LFT, KFT, Lipid, HbA1c, Thyroid, Urine, MRI, CT, X-ray, ECG, Echo, Discharge Summary, Biopsy, Pathology Report, Doctor Note).
Ignore non-medical objects, selfies, animals, cars, food menus, homework, general notes, or prescriptions.

IF NOT A VALID MEDICAL REPORT:
Set "is_valid_report": false
Set "summary": "This image doesn't seem to be a report.\nTry uploading:\n\n📄 A doctor's report\n📸 A clear, well-lit photo\n📑 A single report page"
Set "abnormal_count": 0
Set "report_type": "Unknown Report"

TASK 2: REPORT SUMMARIZATION & CLINICAL ANALYSIS (If valid medical report)
1. Set "is_valid_report": true
2. Identify the report category as "report_type" (e.g. "CBC", "LFT", "KFT", "Lipid", "HbA1c", "Thyroid", "Urine", "MRI", "CT", "X-ray", "ECG", "Echo", or "Lab Report").
3. Count the total number of abnormal/out-of-range results as an integer "abnormal_count".
4. Format "summary" as a comprehensive, beautifully structured markdown report in {target_lang} containing EXACTLY these 3 headings:

### 🚨 Critical & Important Values (Needs Attention)
List any HIGH, LOW, ABNORMAL, POSITIVE, or OUT-OF-RANGE lab test parameters. For each abnormal parameter, include:
- Parameter Name & Detected Value (with units)
- Standard Reference Range
- ⚠️ Warning indicator & brief explanation of why this value needs attention.
If ALL values are normal: "✅ All detected parameters are within normal reference ranges."

### 📊 Important Report Parameters & Reference Findings
List all main test parameters identified in the report with detected values and reference ranges (e.g. Hemoglobin, WBC, RBC, Platelets, Fasting Glucose, TSH, Bilirubin, Creatinine, etc.).

### ℹ️ Clinical Summary & Important Information
Provide clear, patient-friendly information explaining:
- What this medical report category measures and why it is performed.
- General health implications of the findings.
- Actionable clinical next steps and consultation guidance.

CONSTRAINTS:
- Do NOT include patient address, doctor phone number, or administrative emails.
- Return raw JSON ONLY without markdown code blocks (no ```json).

JSON STRUCTURE:
{{
    "is_valid_report": true,
    "report_type": "CBC",
    "abnormal_count": 1,
    "summary": "### 🚨 Critical & Important Values (Needs Attention)\\n...\\n\\n### 📊 Important Report Parameters & Reference Findings\\n...\\n\\n### ℹ️ Clinical Summary & Important Information\\n..."
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
            if max(pil_img.width, pil_img.height) > 1200:
                pil_img.thumbnail((1200, 1200), Image.Resampling.LANCZOS)
            contents.append(pil_img)
        except Exception as ie:
            logging.warning(f"Could not load report image bytes into PIL: {ie}")

    contents.append(prompt)

    total_start = time.time()
    retry_count = 0

    for model in MODEL_CANDIDATES:
        retry_count += 1
        print(f"\n[DEBUG GEMINI REPORT] Retry Count: {retry_count} / {len(MODEL_CANDIDATES)}")
        print(f"[DEBUG GEMINI REPORT] Selected Model: {model}")
        print(f"[DEBUG GEMINI REPORT] Payload Summary: text_len={len(report_text or '')}, image_bytes={len(image_bytes) if image_bytes else 0}")
        
        attempt_start = time.time()
        try:
            result_dict = await asyncio.wait_for(
                asyncio.to_thread(_call_single_report_model, model, contents, report_text),
                timeout=6.0
            )
            attempt_dur = time.time() - attempt_start
            parsed = result_dict.get("parsed")

            if isinstance(parsed, dict) and parsed.get("summary"):
                print(f"[DEBUG GEMINI REPORT] Response Status: SUCCESS (Model: {model})")
                return parsed

        except asyncio.TimeoutError:
            attempt_dur = time.time() - attempt_start
            print(f"[DEBUG GEMINI REPORT ERROR] Timeout Triggered after {attempt_dur:.2f}s for model {model}")
        except Exception as err:
            attempt_dur = time.time() - attempt_start
            print(f"[DEBUG GEMINI REPORT ERROR] Model {model} request failed after {attempt_dur:.2f}s: {err}")

    print(f"\n[DEBUG GEMINI REPORT ERROR] All candidate attempts failed. Returning fast OCR fallback.")
    has_text = bool(report_text and len(report_text.strip()) >= 3)
    return {
        "is_valid_report": has_text,
        "summary": "### Medical Report Summary\n- **Status**: OCR extraction completed successfully.\n- **Note**: AI summary is temporarily unavailable.",
        "abnormal_count": 0,
        "report_type": "Medical Report",
        "fallback_activated": True
    }
