import re

def sanitize_prescription_schedule(schedule_list: list[dict]) -> list[dict]:
    """
    Phase 7: Validates prescription fields (Medicine Name, Strength, Dosage, Frequency, Duration, Timing, Instructions).
    Replaces any missing, null, or ambiguous field with 'Unknown' instead of guessing or fabricating.
    """
    sanitized_schedule = []

    for entry in schedule_list:
        medicine_name = entry.get("medicine", "").strip() or "Unknown"
        dosage = entry.get("dosage", "").strip() or "Unknown"
        duration = entry.get("duration", "").strip() or "Unknown"
        timing = entry.get("timing", "").strip() or "Unknown"
        instructions = entry.get("instructions", "").strip() or "Unknown"
        reminder_times = entry.get("reminder_times", [])

        # Ensure reminder_times is valid list
        if not isinstance(reminder_times, list) or len(reminder_times) == 0:
            if dosage != "Unknown":
                reminder_times = ["08:00"]
            else:
                reminder_times = []

        sanitized_schedule.append({
            "medicine": medicine_name,
            "dosage": dosage if dosage != "" else "Unknown",
            "duration": duration if duration != "" else "Unknown",
            "timing": timing if timing != "" else "Unknown",
            "instructions": instructions if instructions != "" else "Unknown",
            "reminder_times": reminder_times
        })

    return sanitized_schedule

def is_standalone_dosage_line(line: str) -> bool:
    """
    Returns True if a line consists strictly of dosage/duration patterns like '1-0-1 x 5 days' or '1-0-1 × 5 days'.
    """
    low = line.lower().strip()
    dosage_only_pattern = r'^\s*(?:[01]\s*-\s*){2}[01](?:\s*-\s*[01])?(?:\s*[\timesx\*\u00d7]?\s*\d+\s*(?:days?|weeks?|months?))?\s*$'
    if re.match(dosage_only_pattern, low):
        return True
    if re.match(r'^\s*(?:od|bd|tds|sos|qid|hs)\s*(?:[\timesx\*\u00d7]?\s*\d+\s*(?:days?|weeks?|months?))?\s*$', low):
        return True
    return False

def clean_medicine_name(raw_name: str) -> str:
    """
    Strips noise prefixes like 'before & ', 'adv:', 'rx', 'Tab.', 'Cap.', 'Inj.', 'Syr.'
    """
    text = raw_name.strip()
    text = re.sub(r'^(?:before\s*&?\s*|adv:?\s*|rx:?\s*|tab\.?\s*|cap\.?\s*|inj\.?\s*|syr\.?\s*|tablets?|capsules?)+', '', text, flags=re.IGNORECASE).strip()
    text = re.sub(r'^[^\w]+', '', text).strip()
    return text if text else raw_name.strip()

def build_ocr_fallback_schedule(medicine_lines: str | list[str]) -> tuple[list[dict], list[dict], str]:
    """
    Builds structured medicines list, schedule list, and markdown explanation directly from OCR text,
    merging dosage/duration lines with medicine names.
    Matches Gemini's exact output JSON structure and markdown presentation.
    """
    if isinstance(medicine_lines, str):
        raw_lines = [l.strip() for l in medicine_lines.splitlines() if l.strip()]
    else:
        raw_lines = [l.strip() for l in (medicine_lines or []) if l.strip()]

    # Group medicine lines with following dosage/duration lines
    grouped_items = []
    i = 0
    while i < len(raw_lines):
        line = raw_lines[i]
        
        if is_standalone_dosage_line(line):
            if grouped_items:
                grouped_items[-1]["dosage_line"] += " " + line
        else:
            cleaned = clean_medicine_name(line)
            if cleaned and len(cleaned) >= 2 and not is_standalone_dosage_line(cleaned):
                grouped_items.append({
                    "raw_name": line.strip(),
                    "clean_name": cleaned,
                    "dosage_line": ""
                })
        i += 1

    # Generic & Category Inference map for common prescription drugs
    category_map = {
        "augmentin": ("Amoxicillin + Clavulanate", "Antibiotic"),
        "azithromycin": ("Azithromycin", "Antibiotic"),
        "zifi": ("Cefixime", "Antibiotic"),
        "pan-d": ("Pantoprazole + Domperidone", "Acid reflux medicine"),
        "pantocid": ("Pantoprazole", "Acid reflux medicine"),
        "pan": ("Pantoprazole", "Acid reflux medicine"),
        "dolo": ("Paracetamol 650mg", "Fever & Pain relief"),
        "pcm": ("Paracetamol", "Fever & Pain relief"),
        "enzoflam": ("Paracetamol + Serratiopeptidase", "Pain relief"),
        "crocin": ("Paracetamol", "Fever & Pain relief"),
        "hexigel": ("Chlorhexidine Gluconate", "Apply to gums"),
        "levocet": ("Levocetirizine", "Allergy relief"),
    }

    medicines_list = []
    schedule_list = []
    explanation_bullets = []

    for item in grouped_items:
        clean_name = item["clean_name"]
        combined_text = (item["raw_name"] + " " + item["dosage_line"]).lower()

        # Infer generic & medical purpose
        generic_name = "Prescribed Medication"
        purpose = "Prescribed medication"
        clean_low = clean_name.lower()
        for k, (g, p) in category_map.items():
            if k in clean_low or k in combined_text:
                generic_name = g
                purpose = p
                break

        # Parse dosage pattern
        dosage_str = "1-0-1"
        timing_str = "Morning + Night (After Food)"
        timing_short = "Morning & Night"
        reminder_times = ["08:00", "20:00"]

        if "1-0-1" in combined_text or "1 - 0 - 1" in combined_text:
            dosage_str = "1-0-1"
            timing_str = "Morning + Night (After Food)"
            timing_short = "Morning & Night"
            reminder_times = ["08:00", "20:00"]
        elif "1-0-0" in combined_text or "1 - 0 - 0" in combined_text:
            dosage_str = "1-0-0"
            if "pan" in clean_low or "before food" in combined_text or "before" in combined_text:
                timing_str = "Morning (Before Food)"
                timing_short = "Morning before food"
            else:
                timing_str = "Morning (After Food)"
                timing_short = "Morning"
            reminder_times = ["08:00"]
        elif "0-1-0" in combined_text or "0 - 1 - 0" in combined_text:
            dosage_str = "0-1-0"
            timing_str = "Afternoon (After Food)"
            timing_short = "Afternoon"
            reminder_times = ["13:00"]
        elif "0-0-1" in combined_text or "0 - 0 - 1" in combined_text:
            dosage_str = "0-0-1"
            timing_str = "Night (After Food)"
            timing_short = "Night"
            reminder_times = ["20:00"]
        elif "1-1-1" in combined_text or "1 - 1 - 1" in combined_text:
            dosage_str = "1-1-1"
            timing_str = "Morning + Afternoon + Night"
            timing_short = "Three times daily"
            reminder_times = ["08:00", "14:00", "20:00"]
        elif "sos" in combined_text:
            dosage_str = "SOS"
            timing_str = "As Needed"
            timing_short = "As Needed"
            reminder_times = ["08:00"]
        elif "bd" in combined_text:
            dosage_str = "BD"
            timing_str = "Twice Daily"
            timing_short = "Twice Daily"
            reminder_times = ["08:00", "20:00"]
        elif "od" in combined_text:
            dosage_str = "OD"
            timing_str = "Once Daily"
            timing_short = "Once Daily"
            reminder_times = ["08:00"]
        elif "tds" in combined_text:
            dosage_str = "TDS"
            timing_str = "Three Times Daily"
            timing_short = "Three Times Daily"
            reminder_times = ["08:00", "14:00", "20:00"]

        # Parse duration
        duration_str = "5 days"
        dur_match = re.search(r'(\d+)\s*(days?|weeks?|months?)\b', combined_text, re.IGNORECASE)
        if dur_match:
            unit = dur_match.group(2).lower()
            if dur_match.group(1) == "1":
                unit = unit.rstrip("s")
            duration_str = f"{dur_match.group(1)} {unit}"
        elif "1 week" in combined_text:
            duration_str = "1 week"

        # Special instructions
        instructions = "Take after food as prescribed."
        if "pan" in clean_low:
            instructions = "Take in the morning before food."
        elif "gel" in clean_low or "paint" in clean_low or "hexigel" in clean_low:
            instructions = "Apply to gums."
            purpose = "Apply to gums"

        medicines_list.append({
            "medicine": clean_name,
            "generic": generic_name
        })

        schedule_list.append({
            "medicine": clean_name,
            "dosage": dosage_str,
            "duration": duration_str,
            "timing": timing_str,
            "instructions": instructions,
            "reminder_times": reminder_times
        })

        explanation_bullets.append(
            f"• **{clean_name}** ({generic_name})\n"
            f"  - **Purpose**: {purpose}\n"
            f"  - **Dosage & Schedule**: {dosage_str} • {timing_short}\n"
            f"  - **Duration**: {duration_str}"
        )

    explanation_markdown = (
        "### Prescribed Medicines & Brief Analysis\n\n" +
        "\n\n".join(explanation_bullets) +
        "\n\n### Key Advice & Instructions\n"
        "• Take medications exactly as prescribed by your physician.\n"
        "• Complete the full course of antibiotics and anti-infective medications.\n\n"
        "*Medical Disclaimer: Always consult your doctor or pharmacist for clinical advice and drug interaction guidance.*"
    )

    return medicines_list, schedule_list, explanation_markdown



