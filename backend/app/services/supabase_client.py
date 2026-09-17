import os
import asyncio
import logging
from typing import Optional
from datetime import datetime, timezone
from supabase import create_client, Client

url: str = os.environ.get("SUPABASE_URL") or ""
key: str = os.environ.get("SUPABASE_ANON_KEY") or ""
supabase: Client = create_client(url, key)

_in_memory_history: dict[str, list[dict]] = {}

async def save_analysis_history(user_id: Optional[str], analysis_type: str, result: str):
    if not user_id:
        user_id = "default"
    
    data = {
        "user_id": user_id,
        "type": analysis_type,
        "result": result,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    
    if user_id not in _in_memory_history:
        _in_memory_history[user_id] = []
    _in_memory_history[user_id].insert(0, data)
    _in_memory_history[user_id] = _in_memory_history[user_id][:10]
    
    # Also save under "default" as fallback
    if user_id != "default":
        if "default" not in _in_memory_history:
            _in_memory_history["default"] = []
        _in_memory_history["default"].insert(0, data)
        _in_memory_history["default"] = _in_memory_history["default"][:10]
    
    try:
        # Supabase-py is sync, so we run it in a thread to keep FastAPI responsive
        await asyncio.to_thread(
            lambda: supabase.table("analysis_history").insert(data).execute()
        )
    except Exception as e:
        # Log the error but don't crash the API. 
        # RLS policy violations (42501) are common if Supabase isn't configured for service-side inserts.
        logging.error(f"Supabase Save Error: {str(e)}")
        print(f"Supabase Save Error: {str(e)}")

async def get_user_recent_history(user_id: Optional[str] = None, limit: int = 5) -> list[dict]:
    search_id = user_id or "default"
    
    try:
        def _fetch():
            query = supabase.table("analysis_history").select("*")
            if user_id:
                query = query.eq("user_id", user_id)
            res = query.order("created_at", desc=True).limit(limit).execute()
            return res.data if res and hasattr(res, 'data') and res.data else []
        
        db_records = await asyncio.to_thread(_fetch)
        if db_records:
            return db_records
    except Exception as e:
        logging.error(f"Supabase History Fetch Error: {str(e)}")
        print(f"Supabase History Fetch Error: {str(e)}")

    # Return in-memory fallback
    mem_records = _in_memory_history.get(search_id) or _in_memory_history.get("default") or []
    return mem_records[:limit]

