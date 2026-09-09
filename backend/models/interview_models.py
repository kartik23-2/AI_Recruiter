"""Pydantic models for the interview engine."""

from __future__ import annotations

from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


# ── Enums ────────────────────────────────────────────────────────────────────

class InterviewMode(str, Enum):
    resume = "resume"
    skill = "skill"
    hybrid = "hybrid"


class ExperienceLevel(str, Enum):
    fresher = "fresher"
    zero_to_one = "0-1 years"
    one_to_three = "1-3 years"
    three_plus = "3+ years"


class Difficulty(str, Enum):
    easy = "easy"
    medium = "medium"
    hard = "hard"


class QuestionType(str, Enum):
    technical = "technical"
    behavioral = "behavioral"
    hr = "hr"
    project = "project"
    follow_up = "follow_up"


# ── Request / Response Models ────────────────────────────────────────────────

class InterviewConfig(BaseModel):
    """Configuration sent from the Flutter client to generate questions."""

    mode: InterviewMode
    role: str = Field(..., min_length=1, max_length=200)
    experience_level: ExperienceLevel
    difficulty: Difficulty
    duration_minutes: int = Field(default=15, ge=5, le=45)
    skills: list[str] = Field(default_factory=list)
    resume_text: Optional[str] = None  # extracted resume text (optional)


class GeneratedQuestion(BaseModel):
    """A single generated interview question."""

    question: str
    question_type: QuestionType
    source: str = ""  # e.g. "resume-skill:Flutter" or "selected-skill:Python"


class EvaluateAnswerRequest(BaseModel):
    """Payload for the evaluate-answer endpoint."""

    question: str
    question_type: str = "technical"
    answer: str
    role: str = "Software Engineer"
    difficulty: str = "medium"


class AnswerEvaluation(BaseModel):
    """Per-answer evaluation returned by the evaluation endpoint."""

    technical_accuracy: int = Field(default=0, ge=0, le=100)
    communication: int = Field(default=0, ge=0, le=100)
    confidence: int = Field(default=0, ge=0, le=100)
    problem_solving: int = Field(default=0, ge=0, le=100)
    overall: int = Field(default=0, ge=0, le=100)
    feedback: str = ""
    follow_up_question: Optional[str] = None


class GenerateReportRequest(BaseModel):
    """Payload for the generate-report endpoint."""

    role: str
    difficulty: str
    experience_level: str
    questions: list[dict]  # [{question, question_type, answer, scores}]


class InterviewReport(BaseModel):
    """Final interview report produced by Gemini."""

    overall_score: int = Field(default=0, ge=0, le=100)
    strengths: list[str] = Field(default_factory=list)
    weaknesses: list[str] = Field(default_factory=list)
    communication_analysis: str = ""
    technical_analysis: str = ""
    areas_to_improve: list[str] = Field(default_factory=list)
    recommended_topics: list[str] = Field(default_factory=list)
    recommended_questions: list[str] = Field(default_factory=list)
