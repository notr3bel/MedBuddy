from azure.ai.vision.imageanalysis import ImageAnalysisClient
from azure.ai.vision.imageanalysis.models import VisualFeatures
from azure.core.credentials import AzureKeyCredential
import os
from google import genai
from app.services.text_cleaner import remove_markdown

endpoint = os.getenv("AZURE_VISION_ENDPOINT")
key = os.getenv("AZURE_VISION_KEY")

vision_client = ImageAnalysisClient(
    endpoint=endpoint,
    credential=AzureKeyCredential(key)
)

gemini_client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
MODEL = "gemini-2.5-flash"


def analyze_skin(image_bytes, language: str = "en"):

    result = vision_client.analyze(
        image_data=image_bytes,
        visual_features=[VisualFeatures.TAGS, VisualFeatures.CAPTION]
    )

    tags = []

    if result.tags is not None:
        for tag in result.tags.list:
            tags.append(tag.name)

    caption = ""
    if result.caption is not None:
        caption = result.caption.text

    lang_map = {
        "hi": "Hindi",
        "kn": "Kannada",
        "ta": "Tamil",
        "ml": "Malayalam",
        "te": "Telugu",
        "en": "English"
    }
    target_lang = lang_map.get(language, "English")

    prompt = f"""
You are a skin care advisor. Analyze the following Azure Vision detecting tags and caption of a skin image.

Tags: {tags}
Caption: {caption}

Explain possible skin conditions based on these visual cues and provide basic care advice.
YOUR RESPONSE MUST BE IN THE FOLLOWING LANGUAGE: {target_lang}

Rules:
- Be concise and easy to read.
- Use markdown for structure (### for headings, ** for bold keywords).
- Do not diagnose diseases or suggest prescription medicines.
- Provide general advice ONLY.
- Suggest seeing a dermatologist if the condition persists or is severe.
"""

    response = gemini_client.models.generate_content(
        model=MODEL,
        contents=prompt
    )

    return response.text if response.text else ""
