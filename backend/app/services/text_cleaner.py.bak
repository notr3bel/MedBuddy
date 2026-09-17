def clean_prescription_text(text):

    lines = text.split("\n")

    filtered = []

    ignore_words = [
        "hospital",
        "uhid",
        "doctor",
        "reg",
        "phone",
        "road",
        "bengaluru",
        "www",
        "email"
    ]

    for line in lines:

        l = line.lower()

        if any(word in l for word in ignore_words):
            continue

        if len(line.strip()) < 3:
            continue

        filtered.append(line)

    return "\n".join(filtered)

def extract_medicine_lines(text):

    lines = text.split("\n")

    meds = []

    keywords = ["tab", "cap", "syr", "inj"]

    for line in lines:

        l = line.lower()

        if any(k in l for k in keywords):
            meds.append(line)

    return "\n".join(meds)

def remove_markdown(text: str) -> str:
    """
    Remove common markdown symbols like hashtags and asterisks.
    """
    import re
    # Remove bold/italic asterisks
    text = re.sub(r'[*_]{1,3}', '', text)
    # Remove headers (hashtags at start of line)
    text = re.sub(r'^#+\s+', '', text, flags=re.MULTILINE)
    # Remove markdown link syntax [text](url) -> text
    text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
    # Remove horizontal rules
    text = re.sub(r'^-{3,}$', '', text, flags=re.MULTILINE)
    
    return text.strip()
