"""
Classify cleaned prescription labels using keyword heuristics.

Run from custom_medical_ocr:

    ..\\backend\\venv\\Scripts\\python.exe categorize_labels.py
"""

import csv
import re
from collections import Counter
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DATASET_DIR = SCRIPT_DIR / "prescription_dataset"

INPUT_CSV = DATASET_DIR / "cleaned_labels.csv"
OUTPUT_CSV = DATASET_DIR / "categorized_labels.csv"

CATEGORIES = [
    "PRESCRIPTION",
    "MEDICAL_REPORT",
    "CERTIFICATE",
    "LETTER",
    "OTHER",
]

KEYWORDS = {
    "PRESCRIPTION": [
        r"\btab\b",
        r"\btabs\b",
        r"\bcap\b",
        r"\bcaps\b",
        r"\bsyr\b",
        r"\bsyrup\b",
        r"\binj\b",
        r"\binjection\b",
        r"\bmg\b",
        r"\bml\b",
        r"\bmcg\b",
        r"\bdose\b",
        r"\bdosage\b",
        r"\bsig\b",
        r"\bdispense\b",
        r"\brx\b",
        r"\bod\b",
        r"\bbd\b",
        r"\btds\b",
        r"\bqid\b",
        r"\bsos\b",
        r"\btablet\b",
        r"\bcapsule\b",
        r"\bteaspoon\b",
        r"\btsp\b",
        r"\bx\s*\d+\s*d\b",
        r"\d+\s*-\s*\d+\s*-\s*\d+",
        r"\bt\.\s*\w+",
        r"\bs\.\s*\w+",
        r"\bmedicine\b",
        r"\bmedicines prescribed\b",
    ],
    "MEDICAL_REPORT": [
        r"\bct\b",
        r"\bmri\b",
        r"\bultrasound\b",
        r"\bx-?ray\b",
        r"\bfindings\b",
        r"\bimpression\b",
        r"\bscan\b",
        r"\bradiology\b",
        r"\becg\b",
        r"\bekg\b",
        r"\bpathology\b",
        r"\bhistology\b",
        r"\breport\b",
        r"\bdiagnosis\b",
        r"\bprovisional diagnosis\b",
        r"\becography\b",
        r"\bpt\s*scan\b",
        r"\bimpedance\b",
        r"\btemporal bone\b",
    ],
    "CERTIFICATE": [
        r"\bto whom it may concern\b",
        r"\bwhomsoever it may concern\b",
        r"\bthis is to certify\b",
        r"\bthis is to inform\b",
        r"\badmitted\b",
        r"\bhospital stay\b",
        r"\bfitness certificate\b",
        r"\bmedical certificate\b",
        r"\bkindly do the needful\b",
        r"\bhome isolation\b",
        r"\bunder my care\b",
        r"\bcurrently admitted\b",
    ],
    "LETTER": [
        r"\bdear\b",
        r"\bsincerely\b",
        r"\bthanking you\b",
        r"\bkind regards\b",
        r"\bregards\b",
        r"\breferral\b",
        r"\bthank you\b",
        r"\byours faithfully\b",
    ],
}


def score_category(text: str, category: str) -> int:
    lowered = text.lower()
    score = 0
    for pattern in KEYWORDS[category]:
        score += len(re.findall(pattern, lowered))
    return score


def classify_text(text: str) -> str:
    if not text.strip():
        return "OTHER"

    scores = {category: score_category(text, category) for category in KEYWORDS}

    best_score = max(scores.values())
    if best_score == 0:
        return "OTHER"

    top_categories = [category for category, score in scores.items() if score == best_score]

    for category in CATEGORIES:
        if category in top_categories:
            return category

    return "OTHER"


def main():
    if not INPUT_CSV.is_file():
        raise FileNotFoundError(
            f"Input not found: {INPUT_CSV}\n"
            "Run clean_prescription_labels.py first."
        )

    with INPUT_CSV.open(newline="", encoding="utf-8") as csv_file:
        input_rows = list(csv.DictReader(csv_file))

    categorized_rows = []
    category_counts = Counter()

    for row in input_rows:
        image_name = row["IMAGE"]
        text = row.get("CLEANED_TEXT") or row.get("TEXT") or ""
        category = classify_text(text)

        categorized_rows.append(
            {
                "IMAGE": image_name,
                "CATEGORY": category,
                "TEXT": text,
            }
        )
        category_counts[category] += 1

    with OUTPUT_CSV.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=["IMAGE", "CATEGORY", "TEXT"])
        writer.writeheader()
        writer.writerows(categorized_rows)

    print(f"Saved: {OUTPUT_CSV}")
    print(f"Total rows: {len(categorized_rows)}")
    print("\nCategory counts:")
    for category in CATEGORIES:
        print(f"  {category}: {category_counts[category]}")


if __name__ == "__main__":
    main()
