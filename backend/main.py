from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routes.resume import router as resume_router

app = FastAPI(
    title="AI Recruiter API",
    description="Backend services for the AI Recruiter application",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(resume_router)


@app.get("/health")
async def health_check():
    return {"status": "ok"}
