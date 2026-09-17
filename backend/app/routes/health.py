from fastapi import APIRouter, Query, HTTPException
from app.schemas.response import BasicResponse
from app.services.supabase_client import supabase
from google import genai
import os
import asyncio
from dotenv import load_dotenv

load_dotenv()

router = APIRouter(prefix="/api")

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY") or "DUMMY_KEY")
MODEL = "gemini-2.5-flash"

from app.services.resilience import get_system_health_status, METRICS

@router.get("/health")
async def health_check():
    """
    Task 11 Deep System Health Check: Exposes health status for Azure Vision OCR,
    Gemini AI, Supabase DB, and TrOCR GPU.
    """
    health = await get_system_health_status()
    return {
        "success": True,
        "health": health
    }

@router.get("/metrics")
async def get_metrics():
    """
    Task 11 Application Metrics Endpoint: Returns request count, avg latency,
    OCR failures, Gemini retries, cache hit rate, and document classification counts.
    """
    return {
        "success": True,
        "metrics": METRICS.get_metrics_summary()
    }

@router.get("/health-summary")
async def get_health_summary(user_id: str = Query(...), lang: str = Query("en")):
    try:
        lang_map = {
            "hi": "Hindi",
            "kn": "Kannada",
            "ta": "Tamil",
            "ml": "Malayalam",
            "te": "Telugu",
            "en": "English"
        }
        target_lang = lang_map.get(lang, "English")

        # Fetch last 5 records from Supabase
        if not supabase:
            raise HTTPException(status_code=503, detail="Database client unavailable")

        response = supabase.table("analysis_history") \
            .select("*") \
            .eq("user_id", user_id) \
            .order("created_at", desc=True) \
            .limit(5) \
            .execute()
        
        records = response.data
        if not records:
            empty_msg = {
                "English": "Start by uploading a prescription or report to track your health timeline.",
                "Hindi": "अपने स्वास्थ्य समयरेखा को ट्रैक करने के लिए एक नुस्खा या रिपोर्ट अपलोड करके शुरू करें।",
                "Kannada": "ನಿಮ್ಮ ಆರೋಗ್ಯ ಟೈಮ್‌ಲೈನ್ ಅನ್ನು ಟ್ರ್ಯಾಕ್ ಮಾಡಲು ಪ್ರಿಸ್ಕ್ರಿಪ್ಷನ್ ಅಥವಾ ವರದಿಯನ್ನು ಅಪ್ಲೋಡ್ ಮಾಡುವ ಮೂಲಕ ಪ್ರಾರಂಭಿಸಿ.",
                "Tamil": "உங்கள் சுகாதார காலவரிசையைக் கண்கಾಣிக்க ஒரு மருந்துச் சீட்டு அல்லது அறிக்கையைப் பதிவேற்றுவதன் ಮೂಲಕ தொடங்கவும்.",
                "Malayalam": "നിങ്ങളുടെ ആരോഗ്യ ടൈംലൈൻ ട്രാക്കുചെയ്യുന്നതിന് ഒരു കുറിപ്പടി അല്ലെങ്കിൽ റിപ്പോർട്ട് അപ്‌ലോഡ് ചെയ്തുകൊണ്ട് ആരംഭിക്കുക.",
                "Telugu": "మీ ఆరోగ్య కాలక్రమాన్ని ట్రాక్ చేయడానికి ప్రిస్క్రిప్షన్ లేదా నివేదికను అప్‌లోడ్ చేయడం ద్వారా ప్రారంభించండి."
            }
            return {
                "total_events": 0,
                "most_common_condition": "None",
                "suggestion": empty_msg.get(target_lang, empty_msg["English"])
            }

        # Format records for Gemini
        history_text = "\n".join([f"Type: {r['type']}, Result: {r['result']}" for r in records])

        prompt = f"""
Analyze the following recent medical history events for a user and provide:
1. Most common condition or concern (short phrase).
2. A helpful health suggestion (1-2 sentences).

History:
{history_text}

Output format:
Condition: <condition>
Suggestion: <suggestion>

YOUR RESPONSE MUST BE IN THE FOLLOWING LANGUAGE: {target_lang}
"""

        def _generate():
            resp = client.models.generate_content(
                model=MODEL,
                contents=prompt,
                config=genai.types.GenerateContentConfig(
                    max_output_tokens=150,
                    temperature=0.3,
                    thinking_config=genai.types.ThinkingConfig(thinking_budget=0),
                )
            )
            return (getattr(resp, "text", "") or "")

        ai_summary = await asyncio.to_thread(_generate)
        
        # Parse AI response
        condition = "General"
        suggestion = "Keep monitoring your health."
        
        for line in ai_summary.split("\n"):
            if "Condition:" in line:
                condition = line.replace("Condition:", "").strip()
            if "Suggestion:" in line:
                suggestion = line.replace("Suggestion:", "").strip()

        return {
            "total_events": len(records),
            "most_common_condition": condition,
            "suggestion": suggestion
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
