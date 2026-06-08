import io
import re
from typing import Any

from PyPDF2 import PdfReader


class ResumeParser:
    """Extracts structured profile data from resume PDF text."""

    SECTION_HEADERS = {
        "skills": ["skills", "technical skills", "core competencies", "technologies"],
        "projects": ["projects", "personal projects", "key projects"],
        "education": ["education", "academic background", "qualifications"],
        "experience": [
            "experience",
            "work experience",
            "professional experience",
            "employment history",
        ],
    }

    COMMON_SKILLS = [
        "python", "java", "javascript", "typescript", "dart", "flutter",
        "react", "node.js", "nodejs", "fastapi", "django", "flask",
        "sql", "postgresql", "mysql", "mongodb", "firebase", "aws",
        "docker", "kubernetes", "git", "html", "css", "c++", "c#",
        "kotlin", "swift", "android", "ios", "machine learning",
        "deep learning", "tensorflow", "pytorch", "rest api", "graphql",
        "agile", "scrum", "linux", "azure", "gcp", "redis", "spring boot",
    ]

    def parse_pdf(self, pdf_bytes: bytes) -> dict[str, Any]:
        text = self._extract_text(pdf_bytes)
        if not text.strip():
            raise ValueError("Could not extract text from the PDF.")

        lines = self._normalize_lines(text)
        sections = self._split_sections(lines)

        return {
            "name": self._extract_name(lines),
            "skills": self._extract_skills(sections.get("skills", []), text),
            "projects": self._extract_bullet_items(sections.get("projects", [])),
            "education": self._extract_bullet_items(sections.get("education", [])),
            "experience": self._extract_bullet_items(sections.get("experience", [])),
        }

    def _extract_text(self, pdf_bytes: bytes) -> str:
        reader = PdfReader(io.BytesIO(pdf_bytes))
        pages = []
        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:
                pages.append(page_text)
        return "\n".join(pages)

    def _normalize_lines(self, text: str) -> list[str]:
        text = text.replace("\r", "\n")
        lines = []
        for raw in text.split("\n"):
            line = re.sub(r"\s+", " ", raw).strip()
            if line:
                lines.append(line)
        return lines

    def _split_sections(self, lines: list[str]) -> dict[str, list[str]]:
        sections: dict[str, list[str]] = {}
        current_key: str | None = None

        for line in lines:
            header_key = self._match_section_header(line)
            if header_key:
                current_key = header_key
                sections.setdefault(current_key, [])
                continue

            if current_key:
                sections[current_key].append(line)

        return sections

    def _match_section_header(self, line: str) -> str | None:
        normalized = line.lower().strip(":-• ")
        for key, aliases in self.SECTION_HEADERS.items():
            for alias in aliases:
                if normalized == alias or normalized.startswith(f"{alias} "):
                    return key
        return None

    def _extract_name(self, lines: list[str]) -> str:
        for line in lines[:5]:
            if self._match_section_header(line):
                continue
            if len(line.split()) <= 6 and not re.search(r"[@|/]", line):
                if not re.search(
                    r"\b(resume|curriculum vitae|cv|phone|email|linkedin)\b",
                    line,
                    re.IGNORECASE,
                ):
                    return line
        return lines[0] if lines else ""

    def _extract_skills(self, section_lines: list[str], full_text: str) -> list[str]:
        skills: list[str] = []

        if section_lines:
            section_text = " ".join(section_lines)
            parts = re.split(r"[,;|•·\n]", section_text)
            for part in parts:
                skill = part.strip(" -•")
                if 1 < len(skill) <= 40:
                    skills.append(skill)

        lowered = full_text.lower()
        for skill in self.COMMON_SKILLS:
            if skill in lowered and skill.title() not in skills:
                skills.append(skill.title())

        seen: set[str] = set()
        unique: list[str] = []
        for skill in skills:
            key = skill.lower()
            if key not in seen:
                seen.add(key)
                unique.append(skill)
        return unique[:20]

    def _extract_bullet_items(self, section_lines: list[str]) -> list[str]:
        items: list[str] = []
        current = ""

        for line in section_lines:
            if re.match(r"^[\-•●▪◦]\s+", line) or re.match(r"^\d+[\.\)]\s+", line):
                if current:
                    items.append(current.strip())
                current = re.sub(r"^[\-•●▪◦]\s+", "", line)
                current = re.sub(r"^\d+[\.\)]\s+", "", current)
            elif current:
                current += f" {line}"
            else:
                current = line

        if current:
            items.append(current.strip())

        if not items and section_lines:
            items = section_lines[:8]

        return items[:10]
