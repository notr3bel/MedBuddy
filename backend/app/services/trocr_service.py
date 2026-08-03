from pathlib import Path

import torch
from PIL import Image
from transformers import TrOCRProcessor, VisionEncoderDecoderModel

# --------------------------------------------------
# MODEL PATH
# --------------------------------------------------

MODEL_DIR = (
    Path(__file__).resolve().parents[3]
    / "custom_medical_ocr"
    / "models"
    / "trocr_medical_ocr"
)

# --------------------------------------------------
# LOAD MODEL ONCE AT STARTUP
# --------------------------------------------------

device = torch.device(
    "cuda" if torch.cuda.is_available()
    else "cpu"
)

processor = TrOCRProcessor.from_pretrained(MODEL_DIR)
model = VisionEncoderDecoderModel.from_pretrained(MODEL_DIR)

model.config.decoder_start_token_id = processor.tokenizer.cls_token_id
model.config.pad_token_id = processor.tokenizer.pad_token_id
model.config.eos_token_id = processor.tokenizer.sep_token_id

model.to(device)
model.eval()

print(f"Using Device: {device}")
print("Model Loaded Successfully")


# --------------------------------------------------
# INFERENCE
# --------------------------------------------------

def predict_medicine_name(image_path: str) -> str:
    try:
        image = Image.open(image_path).convert("RGB")

        pixel_values = processor(
            image,
            return_tensors="pt"
        ).pixel_values.to(device)

        with torch.no_grad():
            generated_ids = model.generate(
                pixel_values,
                num_beams=4,
                max_new_tokens=32,
                early_stopping=True,
            )

        recognized_text = processor.batch_decode(
            generated_ids,
            skip_special_tokens=True,
        )[0]

        return recognized_text.strip()

    except Exception as e:
        print(f"TrOCR Error: {e}")
        return "OCR_ERROR"
