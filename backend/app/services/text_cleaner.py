import re
from app.services.medicine_db import search_local_db

COMMON_MEDICINES = [
    "pan 40", "pan40", "pan", "dolo 650", "dolo650", "dolo", "pcm", "levocet",
    "levocetirizine", "augmentin", "azithromycin", "azithral", "azee", "zifi",
    "crocin", "calpol", "paracetamol", "cetirizine", "pantocid", "pantoprazole",
    "omez", "omeprazole", "rantac", "glycomet", "metformin", "telma", "atorva",
    "zerodol", "combiflam", "meftal", "brufen", "ascoril", "benadryl", "asthalin",
    "disprin", "ecosprin", "limcee", "neurobion", "shelcal", "evion", "amoxicillin",
    "ciprofloxacin", "ofloxacin", "metrogyl", "taxim", "monocef", "rabeloc",
    "alprax", "nexito", "amaryl", "amlokind", "cetzine", "okacet", "moxikind",
    "amoxyclav", "zocon", "thyronorm", "eltroxin", "grilinctus", "budecort",
    "foracort", "deriphyllin", "clopidogrel", "deplatt", "alprazolam", "clonazepam",
    "lonazep", "diazepam", "valium", "duloflex", "escitalopram"
]

MEDICINE_KEYWORDS = [
    "tab", "tablet", "tablets", "cap", "capsule", "capsules", "syr", "syrup",
    "inj", "injection", "drop", "drops", "ointment", "gel", "cream", "lotion",
    "inhaler", "patch", "suspension", "soln", "solution", "powder", "respules"
]

DOSAGE_PATTERNS = [
    r'\b\d+(\.\d+)?\s*(mg|ml|mcg|gm|g|i\.u\.|iu)\b',
    r'\b[0-1]\s*-\s*[0-1]\s*-\s*[0-1](\s*-\s*[0-1])?\b',
    r'\b(od|bd|tds|sos|qid|hs|stat)\b'
]

def _is_medicine_line(l: str, raw_line: str) -> bool:
    if any(k in l for k in MEDICINE_KEYWORDS):
        return True

    if any(med in l for med in COMMON_MEDICINES):
        return True

    for pattern in DOSAGE_PATTERNS:
        if re.search(pattern, l):
            return True

    words = [w for w in re.split(r'[^a-zA-Z0-9]', raw_line) if len(w) >= 3]
    for w in words:
        if search_local_db(w, threshold=0.82):
            return True

    return False

def clean_prescription_text(text: str) -> str:
    if not text:
        return ""

    lines = text.split("\n")
    filtered = []

    email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
    url_pattern = r'https?://\S+|www\.\S+'
    phone_pattern = r'(\+?\d{1,3}[-.\s]?)?\(?\d{3,5}\)?[-.\s]?\d{3,5}[-.\s]?\d{3,5}'
    header_only_words = ["hospital", "uhid", "reg", "registration", "email:", "phone:", "website:", "road", "bengaluru"]

    for line in lines:
        raw_line = line.strip()
        if len(raw_line) < 2:
            continue

        l = raw_line.lower()
        is_med_line = _is_medicine_line(l, raw_line)

        if is_med_line:
            cleaned_line = re.sub(email_pattern, '', raw_line, flags=re.IGNORECASE)
            cleaned_line = re.sub(url_pattern, '', cleaned_line, flags=re.IGNORECASE)
            cleaned_line = re.sub(phone_pattern, '', cleaned_line)
            cleaned_line = " ".join(cleaned_line.split())
            if len(cleaned_line) >= 2:
                filtered.append(cleaned_line)
        else:
            if any(word in l for word in header_only_words):
                continue
            filtered.append(raw_line)

    return "\n".join(filtered)

def extract_medicine_lines(text: str) -> str:
    if not text:
        return ""

    lines = text.split("\n")
    meds = []

    for line in lines:
        raw_line = line.strip()
        if not raw_line:
            continue

        l = raw_line.lower()
        if _is_medicine_line(l, raw_line):
            meds.append(raw_line)

    return "\n".join(meds)

def remove_markdown(text: str) -> str:
    """
    Remove common markdown symbols like hashtags and asterisks.
    """
    text = re.sub(r'[*_]{1,3}', '', text)
    text = re.sub(r'^#+\s+', '', text, flags=re.MULTILINE)
    text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
    text = re.sub(r'^-{3,}$', '', text, flags=re.MULTILINE)
    
    return text.strip()

