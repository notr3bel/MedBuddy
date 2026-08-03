import os

import pandas as pd

TRAIN_CSV = "dataset/training_labels.csv"
TRAIN_IMAGES = "dataset/training_words"
MISSING_OUTPUT = "missing_images.txt"


def main():
    df = pd.read_csv(TRAIN_CSV)
    image_names = df["IMAGE"].astype(str).tolist()

    total_csv_entries = len(image_names)
    missing_images = []

    for image_name in image_names:
        image_path = os.path.join(TRAIN_IMAGES, image_name)
        if not os.path.isfile(image_path):
            missing_images.append(image_name)

    total_images_found = total_csv_entries - len(missing_images)

    print("Total CSV Entries:", total_csv_entries)
    print("Total Images Found:", total_images_found)
    print("Missing Images:", len(missing_images))

    with open(MISSING_OUTPUT, "w", encoding="utf-8") as f:
        for image_name in missing_images:
            f.write(f"{image_name}\n")

    if missing_images:
        print("\nFirst 20 missing files:")
        for image_name in missing_images[:20]:
            print(image_name)
    else:
        print("\nFirst 20 missing files:")
        print("(none)")


if __name__ == "__main__":
    main()
