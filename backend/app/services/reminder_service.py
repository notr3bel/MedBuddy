import logging
import asyncio
from typing import Optional
from app.services.supabase_client import supabase

logger = logging.getLogger("medintel.reminders")

# In-memory storage fallback when Supabase table is absent or unreachable
_in_memory_schedules: dict[str, list[dict]] = {}
_in_memory_dose_logs: list[dict] = []

def generate_reminder_times(dosage: str, custom_timings: Optional[dict] = None) -> list[str]:
    dosage = dosage.strip()
    m_time = (custom_timings or {}).get("morning") or "08:00"
    a_time = (custom_timings or {}).get("afternoon") or "14:00"
    d_time = (custom_timings or {}).get("dinner") or "20:00"

    mapping = {
        "1-0-0": [m_time],
        "0-1-0": [a_time],
        "0-0-1": [d_time],
        "1-0-1": [m_time, d_time],
        "1-1-0": [m_time, a_time],
        "0-1-1": [a_time, d_time],
        "1-1-1": [m_time, a_time, d_time]
    }
    return mapping.get(dosage, [m_time])

async def save_user_reminder_schedule(
    user_id: str,
    schedules: list[dict],
    timezone: str = "Asia/Kolkata",
    prescription_id: Optional[str] = None
) -> dict:
    if not user_id:
        user_id = "default"

    # Normalize records
    records = []
    for item in schedules:
        med_name = item.get("medicine_name") or item.get("medicine") or "Medicine"
        dosage = item.get("dosage") or "1-0-0"
        rem_times = item.get("reminder_times")
        if not isinstance(rem_times, list) or not rem_times:
            rem_times = generate_reminder_times(dosage)

        records.append({
            "user_id": user_id,
            "medicine_name": med_name,
            "medicine": med_name,
            "dosage": dosage,
            "duration": item.get("duration", "5 days"),
            "timing": item.get("timing", "After Food"),
            "instructions": item.get("instructions", "Take as prescribed."),
            "reminder_times": rem_times,
            "timezone": timezone,
            "prescription_id": prescription_id
        })

    # Update in-memory fallback immediately for instant sub-millisecond access
    _in_memory_schedules[user_id] = records
    _in_memory_schedules["default"] = records

    if supabase:
        try:
            def _insert():
                return supabase.table("medication_schedules").upsert(records).execute()
            await asyncio.to_thread(_insert)
        except Exception as e:
            logger.warning(f"Supabase schedule save fallback to in-memory: {e}")

    return {
        "success": True,
        "message": f"Saved {len(records)} medication schedules for user {user_id}."
    }

async def get_user_reminder_schedules(user_id: str) -> list[dict]:
    if not user_id:
        user_id = "default"

    # Check in-memory cache first for instant 0ms return!
    if user_id in _in_memory_schedules and _in_memory_schedules[user_id]:
        return _in_memory_schedules[user_id]

    if "default" in _in_memory_schedules and _in_memory_schedules["default"]:
        return _in_memory_schedules["default"]

    if supabase:
        try:
            def _fetch():
                res = supabase.table("medication_schedules").select("*").eq("user_id", user_id).execute()
                return res.data or []
            db_schedules = await asyncio.to_thread(_fetch)
            if db_schedules:
                _in_memory_schedules[user_id] = db_schedules
                return db_schedules
        except Exception as e:
            logger.warning(f"Supabase fetch schedules fallback: {e}")

    return _in_memory_schedules.get(user_id, _in_memory_schedules.get("default", []))

async def log_dose_action(
    user_id: str,
    schedule_id: str,
    medicine_name: str,
    status: str,
    scheduled_time: str,
    logged_at: Optional[str] = None
) -> dict:
    log_entry = {
        "user_id": user_id or "default",
        "schedule_id": schedule_id,
        "medicine_name": medicine_name,
        "status": status,
        "scheduled_time": scheduled_time,
        "logged_at": logged_at
    }
    _in_memory_dose_logs.append(log_entry)

    if supabase:
        try:
            def _log():
                supabase.table("dose_logs").insert(log_entry).execute()
            await asyncio.to_thread(_log)
        except Exception as e:
            logger.warning(f"Supabase dose log fallback: {e}")

    return {
        "success": True,
        "message": f"Dose status '{status}' recorded for {medicine_name}."
    }

async def get_medication_dashboard(user_id: str, date: Optional[str] = None) -> dict:
    target_id = user_id or "default"
    schedules = await get_user_reminder_schedules(target_id)
    user_logs = [log for log in _in_memory_dose_logs if log.get("user_id") == target_id]

    taken_count = sum(1 for l in user_logs if l.get("status") == "Taken")
    skipped_count = sum(1 for l in user_logs if l.get("status") == "Skipped")
    total_logged = len(user_logs)
    adherence_rate = round((taken_count / total_logged * 100), 1) if total_logged > 0 else 100.0

    return {
        "success": True,
        "date": date,
        "total_medicines": len(schedules),
        "schedules": schedules,
        "adherence_rate": adherence_rate,
        "dose_stats": {
            "taken": taken_count,
            "skipped": skipped_count,
            "total_logged": total_logged
        }
    }
