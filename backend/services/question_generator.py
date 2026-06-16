"""Generates interview questions dynamically using Gemini."""

from __future__ import annotations

import json
import os
import re
from typing import Any

from services.gemini_client import GeminiClient

from models.interview_models import (
    Difficulty,
    ExperienceLevel,
    GeneratedQuestion,
    InterviewConfig,
    InterviewMode,
    QuestionType,
)


class QuestionGenerationError(Exception):
    pass


# Map duration → approximate question count
_DURATION_TO_COUNT = {
    5: 3,
    15: 8,
    30: 16,
    45: 24,
}


class QuestionGenerator:
    """Uses Gemini to generate interview questions based on config."""

    def generate(self, config: InterviewConfig) -> list[GeneratedQuestion]:
        """Generate a list of interview questions for the given config."""
        count = _DURATION_TO_COUNT.get(config.duration_minutes, 8)
        prompt = self._build_prompt(config, count)

        try:
            response = GeminiClient.generate_content(
                prompt,
                generation_config={
                    "temperature": 0.7,
                    "response_mime_type": "application/json",
                },
            )
        except Exception as exc:
            raise QuestionGenerationError(
                f"Gemini request failed: {exc}"
            ) from exc

        raw = getattr(response, "text", None) or ""
        if not raw.strip():
            raise QuestionGenerationError("Gemini returned an empty response.")

        questions = self._parse_questions(raw)
        return questions[:count]

    def generate_follow_up(
        self,
        question: str,
        answer: str,
        role: str,
        difficulty: str,
    ) -> str | None:
        """Generate a single contextual follow-up question from an answer."""
        prompt = (
            "You are a senior technical interviewer. The candidate was asked:\n\n"
            f'Question: "{question}"\n\n'
            f'Candidate answered: "{answer}"\n\n'
            f"Role: {role}\n"
            f"Difficulty: {difficulty}\n\n"
            "Generate exactly ONE follow-up question that digs deeper into "
            "what the candidate said. The follow-up should be specific to their "
            "answer and test deeper understanding.\n\n"
            "Return ONLY the follow-up question text as a plain string, "
            "no JSON, no explanation, no quotes around it."
        )

        try:
            response = GeminiClient.generate_content(
                prompt,
                generation_config={"temperature": 0.6},
            )
            text = getattr(response, "text", None) or ""
            text = text.strip().strip('"').strip("'")
            return text if text else None
        except Exception:
            return None

    def _build_prompt(self, config: InterviewConfig, count: int) -> str:
        mode = config.mode
        role = config.role
        exp = config.experience_level.value
        diff = config.difficulty.value
        skills = ", ".join(config.skills) if config.skills else "general"
        resume = (config.resume_text or "")[:12000]

        # Build distribution description
        if mode == InterviewMode.resume:
            distribution = (
                f"Generate {count} questions derived entirely from the candidate's resume.\n"
                "Focus on their listed skills, projects, and experience."
            )
        elif mode == InterviewMode.skill:
            distribution = (
                f"Generate {count} questions focused on these skills: {skills}.\n"
                "Cover practical usage, tradeoffs, and deep knowledge."
            )
        else:  # hybrid
            resume_count = max(1, int(count * 0.4))
            skill_count = max(1, int(count * 0.4))
            hr_count = max(1, count - resume_count - skill_count)
            distribution = (
                f"Generate exactly {count} questions with this distribution:\n"
                f"- {resume_count} questions from the resume (projects, experience, skills)\n"
                f"- {skill_count} questions on these skills: {skills}\n"
                f"- {hr_count} HR/behavioral questions\n"
            )

        prompt = (
            "You are a senior technical recruiter generating interview questions.\n\n"
            f"Role: {role}\n"
            f"Experience Level: {exp}\n"
            f"Difficulty: {diff}\n"
            f"Interview Mode: {mode.value}\n\n"
            f"{distribution}\n\n"
            "Question types must be one of: technical, behavioral, hr, project\n\n"
        )

        if resume:
            prompt += f"Candidate Resume:\n{resume}\n\n"

        prompt += (
            "Return ONLY a valid JSON array. No markdown, no code fences.\n"
            "Each element must be:\n"
            '{"question": "...", "question_type": "technical|behavioral|hr|project", '
            '"source": "brief description of source"}\n'
        )

        return prompt

    def _parse_questions(self, raw: str) -> list[GeneratedQuestion]:
        cleaned = raw.strip()
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r"\s*```$", "", cleaned)

        try:
            parsed = json.loads(cleaned)
        except json.JSONDecodeError:
            match = re.search(r"\[.*\]", cleaned, flags=re.DOTALL)
            if not match:
                raise QuestionGenerationError("Gemini response was not valid JSON.")
            try:
                parsed = json.loads(match.group(0))
            except json.JSONDecodeError as exc:
                raise QuestionGenerationError(
                    "Gemini response was not valid JSON."
                ) from exc

        if not isinstance(parsed, list):
            raise QuestionGenerationError("Expected a JSON array of questions.")

        questions: list[GeneratedQuestion] = []
        for item in parsed:
            if not isinstance(item, dict):
                continue
            q_text = str(item.get("question", "")).strip()
            if not q_text:
                continue

            q_type_raw = str(item.get("question_type", "technical")).lower().strip()
            try:
                q_type = QuestionType(q_type_raw)
            except ValueError:
                q_type = QuestionType.technical

            source = str(item.get("source", "")).strip()
            questions.append(
                GeneratedQuestion(question=q_text, question_type=q_type, source=source)
            )

        return questions
