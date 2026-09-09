import io
import json
import os
import re
from datetime import datetime, timezone
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, ValidationError, field_validator
from PyPDF2 import PdfReader

from services.gemini_client import GeminiClient


class ResumeAnalysisError(Exception):
    pass


class ResumeProfile(BaseModel):
    model_config = ConfigDict(extra="ignore")

    name: str = ""
    skills: list[str] = Field(default_factory=list)
    projects: list[str] = Field(default_factory=list)
    education: list[str] = Field(default_factory=list)
    experience: list[str] = Field(default_factory=list)
    strengths: list[str] = Field(default_factory=list)
    weakAreas: list[str] = Field(default_factory=list)

    @field_validator(
        "skills",
        "projects",
        "education",
        "experience",
        "strengths",
        "weakAreas",
        mode="before",
    )
    @classmethod
    def _validate_list(cls, value: Any) -> Any:
        if value is None:
            return []
        if isinstance(value, list):
            return [item for item in value if str(item).strip()]
        raise ValueError("Expected a JSON array of strings.")

    @field_validator("name", mode="before")
    @classmethod
    def _validate_name(cls, value: Any) -> str:
        if value is None:
            return ""
        if not isinstance(value, str):
            raise ValueError("Expected a string for name.")
        return value.strip()


class GeminiResumeAnalyzer:
    """Analyzes resumes using Google's Gemini models."""

    def analyze_pdf(self, pdf_bytes: bytes) -> dict[str, Any]:
        text = self._extract_text(pdf_bytes)
        if not text.strip():
            raise ValueError("Could not extract text from the PDF.")

        profile = self._generate_profile(text)
        return {
            **profile.model_dump(),
            "analyzedAt": datetime.now(timezone.utc).isoformat(),
        }

    def _extract_text(self, pdf_bytes: bytes) -> str:
        reader = PdfReader(io.BytesIO(pdf_bytes))
        pages: list[str] = []
        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:
                pages.append(page_text)
        return "\n".join(pages)

    def _generate_profile(self, resume_text: str) -> ResumeProfile:
        prompt = self._build_prompt(resume_text)
        try:
            response = GeminiClient.generate_content(
                prompt,
                generation_config={
                    "temperature": 0.2,
                    "response_mime_type": "application/json",
                },
            )
        except Exception as exc:
            raise ResumeAnalysisError("Gemini request failed.") from exc

        raw_text = getattr(response, "text", None) or ""
        if not raw_text.strip():
            raise ResumeAnalysisError("Gemini returned an empty response.")

        payload = self._extract_json_payload(raw_text)
        try:
            return ResumeProfile.model_validate(payload)
        except ValidationError as exc:
            raise ResumeAnalysisError("Gemini returned malformed resume data.") from exc

    def _build_prompt(self, resume_text: str) -> str:
        resume_text = resume_text[:18000]
        return (
            "You are a resume analysis engine. Extract structured data from the resume below. "
            "Return only valid JSON. No markdown, no explanation, no code fences. "
            "The JSON must follow this schema exactly:\n"
            "{\n"
            '  "name": "",\n'
            '  "skills": [],\n'
            '  "projects": [],\n'
            '  "education": [],\n'
            '  "experience": [],\n'
            '  "strengths": [],\n'
            '  "weakAreas": []\n'
            "}\n\n"
            "Rules:\n"
            "- Keep every field as a JSON string or array of strings.\n"
            "- Use concise, resume-derived phrasing.\n"
            "- If a section is absent, return an empty array.\n"
            "- If the name cannot be determined, return an empty string.\n\n"
            f"Resume text:\n{resume_text}"
        )

    def _extract_json_payload(self, raw_text: str) -> dict[str, Any]:
        cleaned = raw_text.strip()
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r"\s*```$", "", cleaned)

        try:
            parsed = json.loads(cleaned)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", cleaned, flags=re.DOTALL)
            if not match:
                raise ResumeAnalysisError("Gemini response was not valid JSON.")
            try:
                parsed = json.loads(match.group(0))
            except json.JSONDecodeError as exc:
                raise ResumeAnalysisError("Gemini response was not valid JSON.") from exc

        if not isinstance(parsed, dict):
            raise ResumeAnalysisError("Gemini response must be a JSON object.")

        return parsed