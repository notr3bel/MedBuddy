import re

PROMPT_INJECTION_PATTERNS = [
    r"ignore previous instructions",
    r"ignore all prior instructions",
    r"you are now a",
    r"system prompt:",
    r"<\|im_start\|>",
    r"<\|im_end\|>",
    r"\[system\]",
    r"override rules",
    r"reveal secret"
]

def sanitize_prompt_text(input_text: str) -> str:
    """
    Phase 16: Strips prompt injection tokens and malicious sequences before feeding text into Gemini LLM prompts.
    """
    if not input_text:
        return ""

    sanitized = input_text
    for pattern in PROMPT_INJECTION_PATTERNS:
        sanitized = re.sub(pattern, "[FILTERED_INJECTION]", sanitized, flags=re.IGNORECASE)

    # Escape raw curly braces to prevent format string issues
    sanitized = sanitized.replace("{", "(").replace("}", ")")
    return sanitized.strip()
