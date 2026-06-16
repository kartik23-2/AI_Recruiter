from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Load environment variables from backend/.env (if present)
load_dotenv(Path(__file__).resolve().parent / ".env")

from routes.interview import router as interview_router
from routes.resume import router as resume_router

app = FastAPI(
    title="AI Recruiter API",
    description="Backend services for the AI Recruiter application",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(resume_router)
app.include_router(interview_router)


@app.get("/health")
async def health_check():
    return {"status": "ok"}
