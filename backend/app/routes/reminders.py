from fastapi import APIRouter, Query
from pydantic import BaseModel
from typing import Optional

from app.services.reminder_service import (
    save_user_reminder_schedule,
    get_user_reminder_schedules,
    log_dose_action,
    get_medication_dashboard
)

router = APIRouter(prefix="/api/reminders", tags=["reminders"])

class SaveScheduleRequest(BaseModel):
    user_id: str
    schedules: list[dict]
    timezone: Optional[str] = "Asia/Kolkata"
    prescription_id: Optional[str] = None

class DoseLogRequest(BaseModel):
    user_id: str
    schedule_id: str
    medicine_name: str
    status: str  # "Taken", "Skipped", "Snoozed"
    scheduled_time: str
    logged_at: Optional[str] = None

@router.post("/save")
async def save_reminders(req: SaveScheduleRequest):
    """
    Saves or updates user medication schedules in Supabase / memory.
    """
    return await save_user_reminder_schedule(
        user_id=req.user_id,
        schedules=req.schedules,
        timezone=req.timezone or "Asia/Kolkata",
        prescription_id=req.prescription_id
    )

@router.get("/schedules")
async def get_schedules(user_id: str = Query(..., description="User ID")):
    """
    Fetches active medication schedules for a user.
    """
    schedules = await get_user_reminder_schedules(user_id)
    return {
        "success": True,
        "schedules": schedules
    }

@router.post("/dose-log")
async def log_dose(req: DoseLogRequest):
    """
    Logs dose tracking status (Taken, Skipped, Snoozed) with timestamp.
    """
    return await log_dose_action(
        user_id=req.user_id,
        schedule_id=req.schedule_id,
        medicine_name=req.medicine_name,
        status=req.status,
        scheduled_time=req.scheduled_time,
        logged_at=req.logged_at
    )

@router.get("/dashboard")
async def get_dashboard(
    user_id: str = Query(..., description="User ID"),
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format")
):
    """
    Fetches medication management dashboard (today's medicines, upcoming doses, missed doses, adherence %).
    """
    return await get_medication_dashboard(user_id, date)
