"""Interview API routes — question generation, answer evaluation, report."""

from __future__ import annotations

from fastapi import APIRouter, HTTPException

from models.interview_models import (
    AnswerEvaluation,
    EvaluateAnswerRequest,
    GenerateReportRequest,
    GeneratedQuestion,
    InterviewConfig,
    InterviewReport,
)
from services.answer_evaluator import AnswerEvaluationError, AnswerEvaluator
from services.question_generator import QuestionGenerationError, QuestionGenerator
from services.report_generator import ReportGenerationError, ReportGenerator

router = APIRouter(prefix="/interview", tags=["interview"])

# Lazy singletons
_question_gen: QuestionGenerator | None = None
_evaluator: AnswerEvaluator | None = None
_report_gen: ReportGenerator | None = None


def _get_question_generator() -> QuestionGenerator:
    global _question_gen
    if _question_gen is None:
        _question_gen = QuestionGenerator()
    return _question_gen


def _get_evaluator() -> AnswerEvaluator:
    global _evaluator
    if _evaluator is None:
        _evaluator = AnswerEvaluator()
    return _evaluator


def _get_report_generator() -> ReportGenerator:
    global _report_gen
    if _report_gen is None:
        _report_gen = ReportGenerator()
    return _report_gen


@router.post("/generate-questions", response_model=list[GeneratedQuestion])
async def generate_questions(config: InterviewConfig):
    """Generate interview questions based on the provided configuration."""
    try:
        questions = _get_question_generator().generate(config)
    except QuestionGenerationError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail="Failed to generate questions. Please try again.",
        ) from exc

    if not questions:
        raise HTTPException(
            status_code=502,
            detail="No questions were generated. Please adjust your configuration.",
        )

    return questions


@router.post("/evaluate-answer", response_model=AnswerEvaluation)
async def evaluate_answer(request: EvaluateAnswerRequest):
    """Evaluate a candidate's answer and optionally produce a follow-up question."""
    try:
        evaluation = _get_evaluator().evaluate(
            question=request.question,
            question_type=request.question_type,
            answer=request.answer,
            role=request.role,
            difficulty=request.difficulty,
        )
    except AnswerEvaluationError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail="Failed to evaluate answer. Please try again.",
        ) from exc

    return evaluation


@router.post("/generate-report", response_model=InterviewReport)
async def generate_report(request: GenerateReportRequest):
    """Generate a comprehensive interview report from all Q&A data."""
    try:
        report = _get_report_generator().generate(
            role=request.role,
            difficulty=request.difficulty,
            experience_level=request.experience_level,
            questions=request.questions,
        )
    except ReportGenerationError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail="Failed to generate report. Please try again.",
        ) from exc

    return report
