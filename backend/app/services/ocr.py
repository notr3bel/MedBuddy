from azure.ai.vision.imageanalysis import ImageAnalysisClient
from azure.ai.vision.imageanalysis.models import VisualFeatures
from azure.core.credentials import AzureKeyCredential
import os
import io

endpoint = os.getenv("AZURE_VISION_ENDPOINT")
key = os.getenv("AZURE_VISION_KEY")

client = ImageAnalysisClient(
    endpoint=endpoint,
    credential=AzureKeyCredential(key)
)

import asyncio

def _analyze(image_bytes):
    return client.analyze(
        image_data=image_bytes,
        visual_features=[VisualFeatures.READ]
    )

async def extract_text_from_image(image_bytes: bytes):

    result = client.analyze(
        image_data=image_bytes,
        visual_features=[VisualFeatures.READ]
    )

    extracted_text = ""

    if result.read is not None:
        for block in result.read.blocks:
            for line in block.lines:
                extracted_text += line.text + "\n"

    return extracted_text