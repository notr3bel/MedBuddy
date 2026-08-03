import os
import pandas as pd
from PIL import Image

import evaluate
import torch
from torch.utils.data import Dataset

from transformers import (
    TrOCRProcessor,
    VisionEncoderDecoderModel,
    Seq2SeqTrainer,
    Seq2SeqTrainingArguments,
)

# --------------------------------------------------
# METRICS
# --------------------------------------------------

cer_metric = evaluate.load("cer")
wer_metric = evaluate.load("wer")

# --------------------------------------------------
# CONFIG
# --------------------------------------------------

TRAIN_CSV = "dataset/training_labels.csv"
VAL_CSV = "dataset/validation_labels.csv"

TRAIN_IMAGES = "dataset/training_words"
VAL_IMAGES = "dataset/validation_words"

MODEL_NAME = "microsoft/trocr-base-handwritten"
OUTPUT_DIR = "./trocr_results"
SAVE_DIR = "models/trocr_medical_ocr"

# --------------------------------------------------
# LOAD PROCESSOR + MODEL
# --------------------------------------------------

processor = TrOCRProcessor.from_pretrained(MODEL_NAME)

model = VisionEncoderDecoderModel.from_pretrained(MODEL_NAME)

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

print(f"Using Device: {device}")

# --------------------------------------------------
# DATASET
# --------------------------------------------------

class MedicineDataset(Dataset):

    def __init__(self, csv_file, image_folder):

        self.df = pd.read_csv(csv_file)

        self.image_folder = image_folder

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):

        row = self.df.iloc[idx]

        image_path = os.path.join(
            self.image_folder,
            row["IMAGE"]
        )

        image = Image.open(image_path).convert("RGB")

        text = str(row["MEDICINE_NAME"])

        pixel_values = processor(
            image,
            return_tensors="pt"
        ).pixel_values.squeeze()

        labels = processor.tokenizer(
            text,
            padding="max_length",
            max_length=32,
            return_tensors="pt"
        ).input_ids.squeeze()

        labels[labels == processor.tokenizer.pad_token_id] = -100

        return {
            "pixel_values": pixel_values,
            "labels": labels
        }

# --------------------------------------------------
# DATASETS
# --------------------------------------------------

train_dataset = MedicineDataset(
    TRAIN_CSV,
    TRAIN_IMAGES
)

val_dataset = MedicineDataset(
    VAL_CSV,
    VAL_IMAGES
)

print("Training Samples:", len(train_dataset))
print("Validation Samples:", len(val_dataset))

# --------------------------------------------------
# EVALUATION METRICS
# --------------------------------------------------

def compute_metrics(pred):

    labels_ids = pred.label_ids
    pred_ids = pred.predictions

    pred_str = processor.batch_decode(
        pred_ids,
        skip_special_tokens=True
    )

    labels_ids[labels_ids == -100] = processor.tokenizer.pad_token_id

    label_str = processor.batch_decode(
        labels_ids,
        skip_special_tokens=True
    )

    cer = cer_metric.compute(
        predictions=pred_str,
        references=label_str
    )

    wer = wer_metric.compute(
        predictions=pred_str,
        references=label_str
    )

    return {
        "cer": cer,
        "wer": wer
    }

# --------------------------------------------------
# TRAINING ARGUMENTS
# --------------------------------------------------

training_args = Seq2SeqTrainingArguments(

    output_dir=OUTPUT_DIR,

    predict_with_generate=True,

    evaluation_strategy="epoch",

    save_strategy="epoch",

    logging_strategy="steps",

    logging_steps=50,

    save_total_limit=2,

    load_best_model_at_end=True,

    per_device_train_batch_size=4,

    per_device_eval_batch_size=4,

    num_train_epochs=3,

    fp16=True,

    learning_rate=5e-5,

    weight_decay=0.01
)

# --------------------------------------------------
# TRAINER
# --------------------------------------------------

trainer = Seq2SeqTrainer(

    model=model,

    args=training_args,

    train_dataset=train_dataset,

    eval_dataset=val_dataset,

    tokenizer=processor.feature_extractor,

    compute_metrics=compute_metrics
)

# --------------------------------------------------
# TRAIN MODEL
# --------------------------------------------------

print("Starting Training...")

trainer.train()

# --------------------------------------------------
# SAVE MODEL
# --------------------------------------------------

os.makedirs(SAVE_DIR, exist_ok=True)

model.save_pretrained(SAVE_DIR)

processor.save_pretrained(SAVE_DIR)

print("Model Saved Successfully")
