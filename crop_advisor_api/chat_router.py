import json
import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from sqlalchemy import select, delete
from database import ChatSession, ChatMessage, AsyncSessionLocal

router = APIRouter(prefix="/chat", tags=["Chat"])


# ─── Request/Response Models ──────────────────────────────────────────────────

class StartSessionRequest(BaseModel):
    enriched_analysis: dict  # the full JSON from POST /analyze


class StartSessionResponse(BaseModel):
    session_id: str
    message: str


class ChatMessageRequest(BaseModel):
    session_id: str
    message: str


class ChatMessageResponse(BaseModel):
    session_id: str
    reply: str
    history: list[dict]


class ResetSessionRequest(BaseModel):
    session_id: str
    enriched_analysis: dict


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.post("/start", response_model=StartSessionResponse)
async def start_session(req: StartSessionRequest):
    """
    Call this once after POST /analyze.
    Pass the enriched analysis JSON — returns a session_id for all future chat calls.
    """
    session_id = str(uuid.uuid4())

    async with AsyncSessionLocal() as db:
        session = ChatSession(
            session_id=session_id,
            enriched_json=json.dumps(req.enriched_analysis),
        )
        db.add(session)
        await db.commit()

    return StartSessionResponse(
        session_id=session_id,
        message="Session started. You can now ask questions about your crop analysis.",
    )


@router.post("/message", response_model=ChatMessageResponse)
async def send_message(req: ChatMessageRequest):
    """
    Send a user message and get an AI response.
    Always include the session_id returned from /chat/start.
    """
    from chat_service import get_chat_response

    async with AsyncSessionLocal() as db:
        # Load session
        result = await db.execute(
            select(ChatSession).where(ChatSession.session_id == req.session_id)
        )
        session = result.scalar_one_or_none()
        if not session:
            raise HTTPException(status_code=404, detail="Session not found. Call /chat/start first.")

        enriched_json = json.loads(session.enriched_json)

        # Load conversation history
        result = await db.execute(
            select(ChatMessage)
            .where(ChatMessage.session_id == req.session_id)
            .order_by(ChatMessage.created_at)
        )
        messages = result.scalars().all()
        history = [{"role": m.role, "content": m.content} for m in messages]

        # Get LLM reply
        reply = await get_chat_response(enriched_json, history, req.message)

        # Save user message + assistant reply
        db.add(ChatMessage(session_id=req.session_id, role="user", content=req.message))
        db.add(ChatMessage(session_id=req.session_id, role="assistant", content=reply))
        await db.commit()

    return ChatMessageResponse(
        session_id=req.session_id,
        reply=reply,
        history=history + [
            {"role": "user", "content": req.message},
            {"role": "assistant", "content": reply},
        ],
    )


@router.post("/reset", response_model=StartSessionResponse)
async def reset_session(req: ResetSessionRequest):
    """
    Start fresh with a new analysis while keeping the same session_id.
    Clears all previous messages.
    """
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(ChatSession).where(ChatSession.session_id == req.session_id)
        )
        session = result.scalar_one_or_none()
        if not session:
            raise HTTPException(status_code=404, detail="Session not found.")

        # Update analysis JSON
        session.enriched_json = json.dumps(req.enriched_analysis)

        # Clear message history
        await db.execute(
            delete(ChatMessage).where(ChatMessage.session_id == req.session_id)
        )
        await db.commit()

    return StartSessionResponse(
        session_id=req.session_id,
        message="Session reset with new analysis.",
    )


@router.get("/history/{session_id}")
async def get_history(session_id: str):
    """Returns the full conversation history for a session."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(ChatMessage)
            .where(ChatMessage.session_id == session_id)
            .order_by(ChatMessage.created_at)
        )
        messages = result.scalars().all()
        if not messages:
            raise HTTPException(status_code=404, detail="No history found for this session.")

    return {"session_id": session_id, "history": [{"role": m.role, "content": m.content} for m in messages]}
