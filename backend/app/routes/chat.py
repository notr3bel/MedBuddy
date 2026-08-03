from fastapi import APIRouter, Form
from app.services.gemini_chat import get_chat_response

router = APIRouter(prefix="/api")

@router.post("/chat")
async def chat_with_assistant(query: str = Form(...), lang: str = Form("en")):
    
    response_text = await get_chat_response(query, language=lang)
    
    return {
        "success": True,
        "response": response_text
    }
