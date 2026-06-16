"""Evaluates candidate answers using Gemini."""

from __future__ import annotations

import json
import os
import re
from typing import Any

from services.gemini_client import GeminiClient

from models.interview_models import AnswerEvaluation


class AnswerEvaluationError(Exception):
    pass


class AnswerEvaluator:
    """Uses Gemini to evaluate a candidate's answer and generate follow-up."""

    def evaluate(
        self,
        question: str,
        question_type: str,
        answer: str,
        role: str,
        difficulty: str,
    ) -> AnswerEvaluation:
        """Evaluate a single answer and optionally produce a follow-up question."""
        if not answer.strip() or answer.strip().lower() == "no speech detected.":
            return AnswerEvaluation(
                technical_accuracy=0,
                communication=0,
                confidence=0,
                problem_solving=0,
                overall=0,
                feedback="No answer was provided.",
                follow_up_question=None,
            )

        prompt = self._build_prompt(question, question_type, answer, role, difficulty)

        try:
            response = GeminiClient.generate_content(
                prompt,
                generation_config={
                    "temperature": 0.3,
                    "response_mime_type": "application/json",
                },
            )
        except Exception as exc:
            raise AnswerEvaluationError(f"Gemini evaluation failed: {exc}") from exc

        raw = getattr(response, "text", None) or ""
        if not raw.strip():
            raise AnswerEvaluationError("Gemini returned an empty evaluation.")

        return self._parse_evaluation(raw)

    def _build_prompt(
        self,
        question: str,
        question_type: str,
        answer: str,
        role: str,
        difficulty: str,
    ) -> str:
        return (
            "You are a senior technical interviewer evaluating a candidate's answer.\n\n"
            f"Role: {role}\n"
            f"Difficulty: {difficulty}\n"
            f"Question Type: {question_type}\n\n"
            f'Question: "{question}"\n\n'
            f'Candidate Answer: "{answer}"\n\n'
            "Evaluate the answer and return ONLY valid JSON with this exact schema:\n"
            "{\n"
            '  "technical_accuracy": <0-100>,\n'
            '  "communication": <0-100>,\n'
            '  "confidence": <0-100>,\n'
            '  "problem_solving": <0-100>,\n'
            '  "overall": <0-100>,\n'
            '  "feedback": "<2-3 sentence constructive feedback>",\n'
            '  "follow_up_question": "<a contextual follow-up question based on the answer, or null>"\n'
            "}\n\n"
            "Scoring guidelines:\n"
            "- technical_accuracy: How correct and complete is the answer technically?\n"
            "- communication: How well does the candidate articulate the answer?\n"
            "- confidence: How confident does the candidate sound?\n"
            "- problem_solving: Does the answer demonstrate analytical thinking?\n"
            "- overall: Weighted average considering all factors.\n"
            "- follow_up_question: Generate a follow-up that digs deeper into "
            "what the candidate mentioned. If the answer is too vague, ask for "
            "clarification. Set to null if no follow-up is needed.\n\n"
            "No markdown, no code fences, just valid JSON."
        )

    def _parse_evaluation(self, raw: str) -> AnswerEvaluation:
        cleaned = raw.strip()
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r"\s*```$", "", cleaned)

        try:
            data = json.loads(cleaned)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", cleaned, flags=re.DOTALL)
            if not match:
                raise AnswerEvaluationError("Gemini evaluation was not valid JSON.")
            try:
                data = json.loads(match.group(0))
            except json.JSONDecodeError as exc:
                raise AnswerEvaluationError(
                    "Gemini evaluation was not valid JSON."
                ) from exc

        if not isinstance(data, dict):
            raise AnswerEvaluationError("Expected a JSON object for evaluation.")

        def _clamp(val: Any, lo: int = 0, hi: int = 100) -> int:
            try:
                return max(lo, min(hi, int(val)))
            except (TypeError, ValueError):
                return 0

        return AnswerEvaluation(
            technical_accuracy=_clamp(data.get("technical_accuracy")),
            communication=_clamp(data.get("communication")),
            confidence=_clamp(data.get("confidence")),
            problem_solving=_clamp(data.get("problem_solving")),
            overall=_clamp(data.get("overall")),
            feedback=str(data.get("feedback", "")).strip(),
            follow_up_question=data.get("follow_up_question"),
        )
