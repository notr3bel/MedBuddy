MEDICINE_KEYWORDS = [
    "tab",
    "tablet",
    "cap",
    "capsule",
    "syp",
    "syrup",
    "inj",
    "mg",
    "ml"
]

def extract_possible_medicines(text: str):
    medicines = []
    lines = text.split("\n")
    for line in lines:
        lower = line.lower()
        if any(keyword in lower for keyword in MEDICINE_KEYWORDS):
            medicines.append(line.strip())
    return medicines
