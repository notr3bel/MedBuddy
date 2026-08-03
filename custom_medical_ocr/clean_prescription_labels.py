"""
Clean prescription OCR labels using Gemini.

Run from custom_medical_ocr with the backend virtual environment:

    ..\\backend\\venv\\Scripts\\python.exe clean_prescription_labels.py
"""

import asyncio
import csv
import os
from pathlib import Path

from dotenv import load_dotenv
from google import genai

# --------------------------------------------------
# PATHS + ENV
# --------------------------------------------------

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
BACKEND_DIR = PROJECT_ROOT / "backend"
DATASET_DIR = SCRIPT_DIR / "prescription_dataset"

INPUT_CSV = DATASET_DIR / "prescription_labels.csv"
OUTPUT_CSV = DATASET_DIR / "cleaned_labels.csv"
REPORT_CSV = DATASET_DIR / "cleaning_report.csv"

load_dotenv(BACKEND_DIR / ".env")

GEMINI_MODEL = "gemini-2.5-flash"
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

CLEANING_PROMPT = """You are cleaning OCR output from a doctor's prescription.

Remove:
- Hospital names
- Hospital addresses
- Phone numbers
- Email IDs
- Websites
- Doctor registration numbers
- Boilerplate headers and footers

Keep:
- Medicine names
- Dosage instructions
- Dates
- Clinical notes
- Symptoms
- Diagnoses

Rules:
1. Correct obvious OCR mistakes only when you are confident.
2. Do NOT hallucinate or invent medicines.
3. Do NOT invent information that is not present in the OCR text.
4. If uncertain, keep the original wording.
5. Preserve useful line structure.

Return only the cleaned prescription content.

OCR TEXT:
{text}"""


# --------------------------------------------------
# GEMINI
# --------------------------------------------------

def clean_text_with_gemini(ocr_text: str) -> str:
    if not ocr_text.strip():
        return ""

    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=CLEANING_PROMPT.format(text=ocr_text),
    )

    cleaned_text = (
        response.text.strip()
        if hasattr(response, "text") and response.text
        else ""
    )

    return cleaned_text


async def clean_text(ocr_text: str) -> str:
    return await asyncio.to_thread(clean_text_with_gemini, ocr_text)


# --------------------------------------------------
# MAIN
# --------------------------------------------------

async def main():
    if not INPUT_CSV.is_file():
        raise FileNotFoundError(f"Input CSV not found: {INPUT_CSV}")

    with INPUT_CSV.open(newline="", encoding="utf-8") as csv_file:
        input_rows = list(csv.DictReader(csv_file))

    total_rows = len(input_rows)

    if total_rows == 0:
        raise ValueError(f"No rows found in: {INPUT_CSV}")

    DATASET_DIR.mkdir(parents=True, exist_ok=True)

    total_success = 0
    total_failed = 0
    cleaned_rows = []
    report_rows = []

    for index, row in enumerate(input_rows, start=1):
        print(f"Processed {index}/{total_rows}")

        image_name = row["IMAGE"]
        ocr_text = row.get("TEXT") or ""
        original_length = len(ocr_text)

        try:
            cleaned_text = await clean_text(ocr_text)
            cleaned_rows.append({"IMAGE": image_name, "CLEANED_TEXT": cleaned_text})
            report_rows.append(
                {
                    "IMAGE": image_name,
                    "ORIGINAL_LENGTH": original_length,
                    "CLEANED_LENGTH": len(cleaned_text),
                }
            )
            total_success += 1
        except Exception as error:
            print(f"Failed: {image_name} ({error})")
            cleaned_rows.append({"IMAGE": image_name, "CLEANED_TEXT": ocr_text})
            report_rows.append(
                {
                    "IMAGE": image_name,
                    "ORIGINAL_LENGTH": original_length,
                    "CLEANED_LENGTH": len(ocr_text),
                }
            )
            total_failed += 1

    with OUTPUT_CSV.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=["IMAGE", "CLEANED_TEXT"])
        writer.writeheader()
        writer.writerows(cleaned_rows)

    with REPORT_CSV.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(
            csv_file,
            fieldnames=["IMAGE", "ORIGINAL_LENGTH", "CLEANED_LENGTH"],
        )
        writer.writeheader()
        writer.writerows(report_rows)

    print(f"Total Success: {total_success}")
    print(f"Total Failed: {total_failed}")
    print(f"Saved: {OUTPUT_CSV}")
    print(f"Saved: {REPORT_CSV}")


if __name__ == "__main__":
    asyncio.run(main())
