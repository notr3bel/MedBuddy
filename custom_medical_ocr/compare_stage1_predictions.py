"""
Compare Stage 1 TrOCR model predictions on Stage 2 validation samples.

Run from custom_medical_ocr:

    ..\\.venv\\Scripts\\python.exe compare_stage1_predictions.py
"""

import csv
import os

import pandas as pd
import torch
from PIL import Image
from sklearn.model_selection import train_test_split
from transformers import TrOCRProcessor, VisionEncoderDecoderModel

# --------------------------------------------------
# CONFIG
# --------------------------------------------------

CSV_PATH = "prescription_dataset/prescription_only.csv"
IMAGES_DIR = "prescription_dataset/images"
MODEL_DIR = "models/trocr_medical_ocr"
OUTPUT_CSV = "stage1_vs_prescription_test.csv"

RANDOM_SEED = 42
NUM_SAMPLES = 5

# --------------------------------------------------
# LOAD PROCESSOR + MODEL
# --------------------------------------------------

processor = TrOCRProcessor.from_pretrained(MODEL_DIR)

model = VisionEncoderDecoderModel.from_pretrained(MODEL_DIR)

model.config.decoder_start_token_id = processor.tokenizer.cls_token_id
model.config.pad_token_id = processor.tokenizer.pad_token_id
model.config.eos_token_id = processor.tokenizer.sep_token_id

# --------------------------------------------------
# GPU SUPPORT
# --------------------------------------------------

device = torch.device(
    "cuda" if torch.cuda.is_available()
    else "cpu"
)

model.to(device)
model.eval()

print(f"Using Device: {device}")

if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")

# --------------------------------------------------
# LOAD + SPLIT DATA
# --------------------------------------------------

df = pd.read_csv(CSV_PATH)

train_df, val_df = train_test_split(
    df,
    test_size=0.10,
    random_state=RANDOM_SEED,
)

samples = val_df.head(NUM_SAMPLES)

# --------------------------------------------------
# INFERENCE
# --------------------------------------------------

results = []

for _, row in samples.iterrows():
    image_name = row["IMAGE"]
    ground_truth = str(row["TEXT"])

    image_path = os.path.join(IMAGES_DIR, image_name)
    image = Image.open(image_path).convert("RGB")

    pixel_values = processor(
        image,
        return_tensors="pt"
    ).pixel_values.to(device)

    with torch.no_grad():
        generated_ids = model.generate(
            pixel_values,
            num_beams=4,
            max_new_tokens=128,
            early_stopping=True,
        )

    prediction = processor.batch_decode(
        generated_ids,
        skip_special_tokens=True
    )[0]

    results.append(
        {
            "IMAGE": image_name,
            "GROUND_TRUTH": ground_truth,
            "PREDICTION": prediction,
        }
    )

    print("=" * 50)
    print(f"IMAGE: {image_name}")
    print()
    print("GROUND TRUTH:")
    print(ground_truth)
    print()
    print("PREDICTION:")
    print(prediction)
    print("=" * 50)
    print()

# --------------------------------------------------
# SAVE RESULTS
# --------------------------------------------------

with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as csv_file:
    writer = csv.DictWriter(
        csv_file,
        fieldnames=["IMAGE", "GROUND_TRUTH", "PREDICTION"],
    )
    writer.writeheader()
    writer.writerows(results)

print(f"Saved: {OUTPUT_CSV}")
