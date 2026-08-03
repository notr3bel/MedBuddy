import os
from supabase import create_client, Client

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_ANON_KEY")
supabase: Client = create_client(url, key)

import asyncio
import logging

async def save_analysis_history(user_id: str, analysis_type: str, result: str):
    if not user_id:
        return
    
    data = {
        "user_id": user_id,
        "type": analysis_type,
        "result": result
    }
    
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

