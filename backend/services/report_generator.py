"""Generates a comprehensive interview report using Gemini."""

from __future__ import annotations

import json
import os
import re
from typing import Any

import google.generativeai as genai

from models.interview_models import InterviewReport


class ReportGenerationError(Exception):
    pass


class ReportGenerator:
    """Uses Gemini to produce a detailed post-interview report."""

    def __init__(self) -> None:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ReportGenerationError("GEMINI_API_KEY is not configured.")

        model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
        genai.configure(api_key=api_key)
        self._model = genai.GenerativeModel(model_name)

    def generate(
        self,
        role: str,
        difficulty: str,
        experience_level: str,
        questions: list[dict],
    ) -> InterviewReport:
        """Generate a full interview report from all Q&A + scores."""
        prompt = self._build_prompt(role, difficulty, experience_level, questions)

        try:
            response = self._model.generate_content(
                prompt,
                generation_config={
                    "temperature": 0.4,
                    "response_mime_type": "application/json",
                },
            )
        except Exception as exc:
            raise ReportGenerationError(f"Gemini report generation failed: {exc}") from exc

        raw = getattr(response, "text", None) or ""
        if not raw.strip():
            raise ReportGenerationError("Gemini returned an empty report.")

        return self._parse_report(raw)

    def _build_prompt(
        self,
        role: str,
        difficulty: str,
        experience_level: str,
        questions: list[dict],
    ) -> str:
        qa_section = ""
        for i, q in enumerate(questions, 1):
            qa_section += (
                f"\n--- Question {i} ---\n"
                f"Type: {q.get('question_type', 'unknown')}\n"
                f"Q: {q.get('question', '')}\n"
                f"A: {q.get('answer', 'No answer')}\n"
                f"Scores: {json.dumps(q.get('scores', {}))}\n"
            )

        return (
            "You are an expert hiring manager writing a detailed interview report.\n\n"
            f"Role: {role}\n"
            f"Difficulty: {difficulty}\n"
            f"Experience Level: {experience_level}\n"
            f"Total Questions: {len(questions)}\n\n"
            "Interview Transcript:\n"
            f"{qa_section}\n\n"
            "Generate a comprehensive interview report. Return ONLY valid JSON:\n"
            "{\n"
            '  "overall_score": <0-100>,\n'
            '  "strengths": ["strength 1", "strength 2", ...],\n'
            '  "weaknesses": ["weakness 1", "weakness 2", ...],\n'
            '  "communication_analysis": "<detailed analysis paragraph>",\n'
            '  "technical_analysis": "<detailed analysis paragraph>",\n'
            '  "areas_to_improve": ["area 1", "area 2", ...],\n'
            '  "recommended_topics": ["topic 1", "topic 2", ...],\n'
            '  "recommended_questions": ["question for next interview 1", ...]\n'
            "}\n\n"
            "Guidelines:\n"
            "- overall_score should be a weighted average reflecting performance\n"
            "- strengths: 3-5 specific things the candidate did well\n"
            "- weaknesses: 2-4 areas where the candidate struggled\n"
            "- communication_analysis: 3-5 sentences about how clearly they communicated\n"
            "- technical_analysis: 3-5 sentences about technical depth\n"
            "- areas_to_improve: 3-5 actionable improvement areas\n"
            "- recommended_topics: 4-6 specific topics to study\n"
            "- recommended_questions: 3-5 questions for the candidate to practice\n\n"
            "No markdown, no code fences."
        )

    def _parse_report(self, raw: str) -> InterviewReport:
        cleaned = raw.strip()
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r"\s*```$", "", cleaned)

        try:
            data = json.loads(cleaned)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", cleaned, flags=re.DOTALL)
            if not match:
                raise ReportGenerationError("Gemini report was not valid JSON.")
            try:
                data = json.loads(match.group(0))
            except json.JSONDecodeError as exc:
                raise ReportGenerationError(
                    "Gemini report was not valid JSON."
                ) from exc

        if not isinstance(data, dict):
            raise ReportGenerationError("Expected a JSON object for the report.")

        def _str_list(val: Any) -> list[str]:
            if isinstance(val, list):
                return [str(s).strip() for s in val if str(s).strip()]
            return []

        def _clamp(val: Any) -> int:
            try:
                return max(0, min(100, int(val)))
            except (TypeError, ValueError):
                return 0

        return InterviewReport(
            overall_score=_clamp(data.get("overall_score")),
            strengths=_str_list(data.get("strengths")),
            weaknesses=_str_list(data.get("weaknesses")),
            communication_analysis=str(data.get("communication_analysis", "")).strip(),
            technical_analysis=str(data.get("technical_analysis", "")).strip(),
            areas_to_improve=_str_list(data.get("areas_to_improve")),
            recommended_topics=_str_list(data.get("recommended_topics")),
            recommended_questions=_str_list(data.get("recommended_questions")),
        )
