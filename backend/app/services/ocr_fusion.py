import difflib

def merge_ocr_results(azure_text: str, trocr_prediction: str) -> str:
    """
    Merge the raw text from Azure OCR with the target medicine brand name predicted by TrOCR.
    Rules:
    - Azure OCR remains the primary OCR.
    - TrOCR is only used to improve medicine name spellings.
    - Do not modify dosage, dates, frequencies, or schedule.
    - Only replace medicine spellings when TrOCR provides a better prediction.
    """
    if not trocr_prediction or not trocr_prediction.strip() or trocr_prediction == "OCR_ERROR":
        return azure_text

    trocr_name = trocr_prediction.strip()
    
    # Clean non-alphanumeric chars from prediction for mapping
    clean_trocr = "".join(c for c in trocr_name if c.isalnum()).lower()
    if not clean_trocr:
        return azure_text

    lines = azure_text.split("\n")
    merged_lines = []
    
    for line in lines:
        if not line.strip():
            merged_lines.append(line)
            continue
            
        words = line.split()
        new_words = []
        
        for word in words:
            # Clean word for comparison (keeping only alphanumeric characters)
            clean_word = "".join(c for c in word if c.isalnum()).lower()
            
            if clean_word:
                # Calculate similarity ratio between this word and TrOCR's medicine name prediction
                ratio = difflib.SequenceMatcher(None, clean_word, clean_trocr).ratio()
                
                # If there's high similarity (e.g. >= 0.75) but they aren't exactly identical,
                # we replace the word with the TrOCR name.
                if 0.75 <= ratio < 1.0 and abs(len(clean_word) - len(clean_trocr)) <= 3:
                    # Keep any trailing/leading symbols from the original word if possible
                    # but substitute the core alphanumeric spelling
                    new_word = word.lower().replace(clean_word, trocr_name)
                    new_words.append(new_word)
                    continue
            
            new_words.append(word)
            
        merged_lines.append(" ".join(new_words))
        
    return "\n".join(merged_lines)
