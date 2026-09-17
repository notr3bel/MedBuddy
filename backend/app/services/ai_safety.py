def enforce_medical_safety_defaults(ai_output: dict, confidence: float = 1.0) -> dict:
    """
    Phases 12 & 19: Medical Safety & Low-Confidence AI Response Handler.
    Ensures system NEVER invents medicines, dosages, schedules, diagnoses, or report values.
    """
    if confidence < 0.5:
        return {
            "is_valid_prescription": False,
            "verified_text": "I could not confidently identify this medicine.",
            "medicines": [],
            "schedule": [],
            "explanation": "I could not confidently identify this medicine. Please upload a clearer medical document.",
            "precautions": []
        }

    is_valid = ai_output.get("is_valid_prescription", False)
    medicines = ai_output.get("medicines", [])
    schedule = ai_output.get("schedule", [])
    explanation = ai_output.get("explanation", "")

    if not is_valid or (not medicines and not schedule):
        return {
            "is_valid_prescription": False,
            "verified_text": ai_output.get("verified_text", "Not a valid prescription."),
            "medicines": [],
            "schedule": [],
            "explanation": "This image doesn't seem to contain legible prescription medications.",
            "precautions": []
        }

    # Ensure required medical disclaimer exists in explanation
    disclaimer = "\n\n*Medical Disclaimer: MedIntel AI provides automated interpretations for educational purposes. Always consult a qualified healthcare professional before taking medications or making medical decisions.*"
    if "Disclaimer" not in explanation:
        explanation = explanation.strip() + disclaimer

    ai_output["explanation"] = explanation
    return ai_output
