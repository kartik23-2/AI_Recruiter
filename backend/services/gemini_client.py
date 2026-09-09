"""Centralized Gemini client with API key rotation."""

import os
from typing import Any, List

import google.generativeai as genai
from google.api_core.exceptions import ResourceExhausted

class GeminiClient:
    """Manages Gemini API key rotation and request execution."""

    _keys: List[str] = []
    _current_index: int = 0
    _model_name: str = "gemini-2.5-flash"
    _initialized: bool = False

    @classmethod
    def _initialize(cls) -> None:
        if cls._initialized:
            return

        keys = []
        
        # Load primary key
        primary = os.getenv("GEMINI_API_KEY")
        if primary:
            keys.append(primary)
            
        # Load fallback keys: GEMINI_API_KEY_1, GEMINI_API_KEY_2, etc.
        for i in range(1, 10):
            k = os.getenv(f"GEMINI_API_KEY_{i}")
            if k:
                keys.append(k)
        
        # Remove empty and duplicates while preserving order
        seen = set()
        cls._keys = [x for x in keys if not (x in seen or seen.add(x))]
        
        cls._model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
        cls._initialized = True

    @classmethod
    def generate_content(cls, prompt: Any, generation_config: dict | None = None) -> Any:
        cls._initialize()
        
        if not cls._keys:
            raise Exception("No GEMINI_API_KEY configured in environment variables.")

        attempts = 0
        max_attempts = len(cls._keys)

        while attempts < max_attempts:
            current_key = cls._keys[cls._current_index]
            try:
                genai.configure(api_key=current_key)
                model = genai.GenerativeModel(cls._model_name)
                return model.generate_content(prompt, generation_config=generation_config)
            except ResourceExhausted:
                # Rotate to the next key
                cls._current_index = (cls._current_index + 1) % len(cls._keys)
                attempts += 1
            except Exception as e:
                # For any other exception, raise immediately
                raise e

        # If we exited the loop, all keys returned ResourceExhausted
        raise ResourceExhausted("All provided Gemini API keys have exhausted their quota.")
