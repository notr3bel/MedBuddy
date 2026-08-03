import os

import evaluate
import pandas as pd
import torch
from PIL import Image
from sklearn.model_selection import train_test_split
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

CSV_PATH = "prescription_dataset/prescription_only.csv"
IMAGES_DIR = "prescription_dataset/images"

MODEL_DIR = "models/trocr_medical_ocr"
OUTPUT_DIR = "./trocr_prescription_results"
SAVE_DIR = "models/trocr_prescription_ocr"

MAX_LENGTH = 512
TRAIN_SPLIT = 0.9
RANDOM_SEED = 42

# --------------------------------------------------
# LOAD PROCESSOR + MODEL
# --------------------------------------------------

processor = TrOCRProcessor.from_pretrained(MODEL_DIR)

model = VisionEncoderDecoderModel.from_pretrained(MODEL_DIR)

model.config.decoder_start_token_id = processor.tokenizer.cls_token_id
model.config.pad_token_id = processor.tokenizer.pad_token_id
model.config.eos_token_id = processor.tokenizer.sep_token_id
model.generation_config.max_new_tokens = 512

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

class PrescriptionDataset(Dataset):

    def __init__(self, dataframe, image_folder):

        self.df = dataframe.reset_index(drop=True)
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

        text = str(row["TEXT"])

        pixel_values = processor(
            image,
            return_tensors="pt"
        ).pixel_values.squeeze()

        labels = processor.tokenizer(
            text,
            padding="max_length",
            max_length=MAX_LENGTH,
            truncation=True,
            return_tensors="pt"
        ).input_ids.squeeze()

        labels[labels == processor.tokenizer.pad_token_id] = -100

        return {
            "pixel_values": pixel_values,
            "labels": labels
        }

# --------------------------------------------------
# LOAD + SPLIT DATA
# --------------------------------------------------

df = pd.read_csv(CSV_PATH)

train_df, val_df = train_test_split(
    df,
    train_size=TRAIN_SPLIT,
    random_state=RANDOM_SEED,
    shuffle=True,
)

train_dataset = PrescriptionDataset(train_df, IMAGES_DIR)
val_dataset = PrescriptionDataset(val_df, IMAGES_DIR)

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
    generation_max_length=512,

    evaluation_strategy="epoch",

    save_strategy="epoch",

    logging_strategy="steps",

    logging_steps=10,

    save_total_limit=2,

    load_best_model_at_end=True,

    metric_for_best_model="cer",

    greater_is_better=False,

    per_device_train_batch_size=2,

    per_device_eval_batch_size=2,

    gradient_accumulation_steps=4,

    num_train_epochs=10,

    fp16=True,

    learning_rate=3e-5,

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
# FINAL EVALUATION
# --------------------------------------------------

eval_results = trainer.evaluate()

print("Training Samples:", len(train_dataset))
print("Validation Samples:", len(val_dataset))
print("CER:", eval_results["eval_cer"])
print("WER:", eval_results["eval_wer"])

# --------------------------------------------------
# SAVE MODEL
# --------------------------------------------------

os.makedirs(SAVE_DIR, exist_ok=True)

model.save_pretrained(SAVE_DIR)

processor.save_pretrained(SAVE_DIR)

print(f"Model Saved Successfully: {SAVE_DIR}")
