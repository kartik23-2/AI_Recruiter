from fastapi import APIRouter, File, HTTPException, UploadFile

from services.gemini_resume_analyzer import ResumeAnalysisError, GeminiResumeAnalyzer

router = APIRouter(tags=["resume"])
_analyzer: GeminiResumeAnalyzer | None = None


def _get_analyzer() -> GeminiResumeAnalyzer:
    global _analyzer
    if _analyzer is None:
        _analyzer = GeminiResumeAnalyzer()
    return _analyzer


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
        profile = _get_analyzer().analyze_pdf(content)
    except ResumeAnalysisError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail="Failed to analyze resume. Please try a different PDF.",
        ) from exc

    return profile
