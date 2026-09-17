import os
import io
import json
import logging
import asyncio
from PIL import Image
from google import genai
from google.genai import types

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL = "gemini-3.6-flash"

async def classify_document_and_safety(image_bytes: bytes, target_endpoint: str = "prescription") -> dict:
    """
    Phases 3 & 4: Document Classification & Non-Medical Object Detection using Gemini Vision.
    
    target_endpoint: "prescription" or "report"
    Returns:
    {
        "is_medical": bool,
        "doc_type": str,
        "wrong_endpoint": bool,
        "rejection_message": str | None
    }
    """
    try:
        pil_img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        
        prompt = """
Analyze this uploaded image carefully and perform document classification & medical relevance detection.

Step 1: Determine if this image is a VALID MEDICAL DOCUMENT or a NON-MEDICAL / SELF-WRITTEN NOTE.

CRITICAL RULES:
- A VALID PRESCRIPTION MUST BE AN OFFICIAL DOCTOR'S PRESCRIPTION issued by a clinic, hospital, or healthcare provider (containing doctor letterhead, clinic address, Rx symbol, doctor signature/seal, or formal prescription layout).
- A self-written list of medicine names written by a user on plain paper, notebook paper, ruled paper, or hand-written notes WITHOUT an official doctor letterhead/clinic header IS NOT A VALID PRESCRIPTION ("Self-Written Notes" / "Non-Medical").

NON-MEDICAL objects include: Self-Written Medicine Notes on plain paper, Notebooks, School Assignments, Cars, Dogs, Cats, Animals, Trees, People, Selfies, Landscapes, Nature, Food, Restaurant Menus, Non-medical Receipts/Invoices, Newspapers, General Photos.

Step 2: If it IS a valid medical document, classify it precisely into one of these exact types:
- "Prescription" (Official Doctor's prescription with medicines, dosage, instructions)
- "Medical Report" (Lab test results, CBC, LFT, KFT, Lipid, HbA1c, Thyroid, Urine, Radiology reports like MRI, CT, X-ray, ECG, Echo)
- "Medicine Strip" (Blister pack or box of medication)
- "Pharmacy Bill" (Invoice/receipt from pharmacy)
- "Hospital Invoice" (Billing statement from hospital)
- "Medical Certificate" (Doctor's sick leave or fitness certificate)
- "Self-Written Notes" / "Non-Medical"

Step 3: Output raw JSON ONLY with these exact keys:
{
  "is_medical": true/false,
  "classified_type": "Prescription" | "Medical Report" | "Medicine Strip" | "Pharmacy Bill" | "Hospital Invoice" | "Medical Certificate" | "Self-Written Notes" | "Non-Medical",
  "reason": "Short explanation"
}
"""

        def _call_gemini():
            config = types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=0.1,
                max_output_tokens=256,
            )
            # Pass image directly as PIL image or bytes
            contents: list = [pil_img, prompt]
            response = client.models.generate_content(
                model=MODEL,
                contents=contents,
                config=config
            )
            return response.text if hasattr(response, "text") and response.text else "{}"

        raw_json = await asyncio.to_thread(_call_gemini)
        
        # Clean json wrapper
        clean_text = raw_json.strip()
        if clean_text.startswith("```json"):
            clean_text = clean_text[7:]
        if clean_text.endswith("```"):
            clean_text = clean_text[:-3]
        clean_text = clean_text.strip()

        parsed = json.loads(clean_text)
        is_medical = parsed.get("is_medical", False)
        doc_type = parsed.get("classified_type", "Non-Medical")

        if doc_type == "Self-Written Notes":
            is_medical = False

        # Non-medical rejection check
        if not is_medical or doc_type in ["Non-Medical", "Random Document", "Self-Written Notes"]:
            if doc_type == "Self-Written Notes":
                msg = (
                    "This document appears to be a self-written list of medicine names on plain paper and not an official doctor's prescription.\n\n"
                    "Self-written medicine notes or lists on plain/ruled paper are not accepted as valid prescriptions.\n\n"
                    "Please upload an official prescription issued by a doctor or clinic."
                )
            elif target_endpoint == "prescription":
                msg = (
                    "This image doesn't seem to be a prescription.\n"
                    "Try uploading:\n\n"
                    "📄 A doctor's prescription\n"
                    "📸 A clear, well-lit photo\n"
                    "📑 A single prescription page"
                )
            elif target_endpoint == "report":
                msg = (
                    "This image doesn't seem to be a report.\n"
                    "Try uploading:\n\n"
                    "📄 A doctor's report\n"
                    "📸 A clear, well-lit photo\n"
                    "📑 A single report page"
                )
            else:
                msg = "This image does not appear to contain a medical document."
            return {
                "is_medical": False,
                "doc_type": doc_type,
                "wrong_endpoint": False,
                "rejection_message": msg
            }

        # Cross-module mismatch check
        wrong_endpoint = False
        rejection_msg = None

        doc_type_lower = str(doc_type).lower()

        if target_endpoint == "prescription":
            if doc_type in ["Medical Report"] and "lab" in parsed.get("reason", "").lower():
                wrong_endpoint = True
                rejection_msg = "This appears to be a medical report. Please use Medical Report Analysis."
            elif doc_type in ["Pharmacy Bill", "Hospital Invoice"]:
                wrong_endpoint = True
                rejection_msg = f"This appears to be a {doc_type.lower()}. Please upload a medical prescription."
            elif not is_medical:
                wrong_endpoint = True
                rejection_msg = (
                    "This image doesn't seem to be a prescription.\n"
                    "Try uploading:\n\n"
                    "📄 A doctor's prescription\n"
                    "📸 A clear, well-lit photo\n"
                    "📑 A single prescription page"
                )
        elif target_endpoint == "report":
            if any(k in doc_type_lower for k in ["prescription", "rx"]) and "report" not in doc_type_lower:
                wrong_endpoint = True
                rejection_msg = "This appears to be a prescription. Please use Prescription Analysis."

        return {
            "is_medical": True,
            "doc_type": doc_type,
            "wrong_endpoint": wrong_endpoint,
            "rejection_message": rejection_msg
        }

    except Exception as e:
        logging.error(f"Document classification error: {e}")
        # In case of API network failure in classification, return neutral pass to avoid blocking valid images
        return {
            "is_medical": True,
            "doc_type": "Unknown",
            "wrong_endpoint": False,
            "rejection_message": None
        }
