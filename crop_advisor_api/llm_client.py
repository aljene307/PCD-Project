from dotenv import load_dotenv
load_dotenv()

import os
from fastapi import HTTPException
from groq import AsyncGroq, RateLimitError as GroqRateLimitError

MODEL = "llama-3.1-8b-instant"


async def chat_completion(
    system: str,
    messages: list,
    max_tokens: int = 1024,
    temperature: float = 0.5,
) -> str:
    api_key = os.getenv("GROQ_API_KEY", "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")
    client = AsyncGroq(api_key=api_key)
    try:
        resp = await client.chat.completions.create(
            model=MODEL,
            messages=[{"role": "system", "content": system}] + messages,
            max_tokens=max_tokens,
            temperature=temperature,
        )
        return resp.choices[0].message.content.strip()
    except GroqRateLimitError as e:
        raise HTTPException(
            status_code=429,
            detail=f"Groq rate limit reached. Please retry in a few minutes. ({e})",
        )
