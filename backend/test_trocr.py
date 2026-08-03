"""
Manual test script for TrOCR medicine name prediction.

Run from backend with the virtual environment activated:

    python test_trocr.py
"""

from app.services.trocr_service import predict_medicine_name


def main():
    try:
        image_path = input("Enter image path: ")
        result = predict_medicine_name(image_path)

        print("=================================")
        print("Prediction:")
        print(result)
        print("=================================")

    except Exception as error:
        print("=================================")
        print("Error:")
        print(error)
        print("=================================")


if __name__ == "__main__":
    main()
