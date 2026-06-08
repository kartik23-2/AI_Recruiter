from fastapi import APIRouter, File, HTTPException, UploadFile

from services.resume_parser import ResumeParser

router = APIRouter(tags=["resume"])
parser = ResumeParser()


@router.post("/analyze-resume")
async def analyze_resume(file: UploadFile = File(...)):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file provided.")

    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(
            status_code=400,
            detail="Only PDF files are supported.",
        )

    content = await file.read()
    if not content:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")

    try:
        profile = parser.parse_pdf(content)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail="Failed to parse resume. Please try a different PDF.",
        ) from exc

    return profile
