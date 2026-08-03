"""
Generate prescription OCR labels using MedBuddy's Azure Vision OCR.

Run from custom_medical_ocr with the backend virtual environment:

    ..\backend\venv\Scripts\python.exe generate_prescription_labels.py
"""

import asyncio
import csv
import sys
from pathlib import Path

from dotenv import load_dotenv

# --------------------------------------------------
# PATHS + ENV
# --------------------------------------------------

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
BACKEND_DIR = PROJECT_ROOT / "backend"

IMAGES_DIR = SCRIPT_DIR / "prescription_dataset" / "images"
OUTPUT_CSV = SCRIPT_DIR / "prescription_dataset" / "prescription_labels.csv"

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tif", ".tiff", ".webp"}

load_dotenv(BACKEND_DIR / ".env")
sys.path.insert(0, str(BACKEND_DIR))

from app.services.ocr import extract_text_from_image


# --------------------------------------------------
# OCR
# --------------------------------------------------

async def extract_text(image_path: Path) -> str:
    image_bytes = image_path.read_bytes()
    extracted_text = await extract_text_from_image(image_bytes)
    return extracted_text.strip().replace("\n", " ")


# --------------------------------------------------
# MAIN
# --------------------------------------------------

async def main():
    if not IMAGES_DIR.is_dir():
        raise FileNotFoundError(f"Images directory not found: {IMAGES_DIR}")

    image_files = sorted(
        [
            path
            for path in IMAGES_DIR.iterdir()
            if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS
        ],
        key=lambda path: path.name.lower(),
    )

    total_images = len(image_files)
    if total_images == 0:
        raise FileNotFoundError(f"No images found in: {IMAGES_DIR}")

    OUTPUT_CSV.parent.mkdir(parents=True, exist_ok=True)

    total_success = 0
    total_failed = 0
    rows = []

    for index, image_path in enumerate(image_files, start=1):
        print(f"Processed {index}/{total_images}")

        try:
            text = await extract_text(image_path)
            rows.append({"IMAGE": image_path.name, "TEXT": text})
            total_success += 1
        except Exception as error:
            print(f"Failed: {image_path.name} ({error})")
            rows.append({"IMAGE": image_path.name, "TEXT": ""})
            total_failed += 1

    with OUTPUT_CSV.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=["IMAGE", "TEXT"])
        writer.writeheader()
        writer.writerows(rows)

    print(f"Total Success: {total_success}")
    print(f"Total Failed: {total_failed}")
    print(f"Saved: {OUTPUT_CSV}")


if __name__ == "__main__":
    asyncio.run(main())
