from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes.health import router as health_router
from app.routes.prescription import router as prescription_router
from app.routes.report import router as report_router
from app.routes.skin import router as skin_router
from app.routes.chat import router as chat_router
from app.routes.symptoms import router as symptoms_router
from app.routes.model import router as model_router

app = FastAPI(
    title="MedIntel API",
    description="Backend services for Medical Assistance Mobile App",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(prescription_router)
app.include_router(report_router)
app.include_router(skin_router)
app.include_router(chat_router)
app.include_router(symptoms_router)
app.include_router(model_router)
@app.get("/")
def root():
    return {"status": "Backend running successfully"}
