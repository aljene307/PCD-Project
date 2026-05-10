import json
import uuid
from fastapi import APIRouter, HTTPException
from sqlalchemy import select, delete

from database import AdvisorSession, AdvisorMessage, AsyncSessionLocal
from models import (
    AdvisorSessionRequest,
    AdvisorSessionResponse,
    AdvisorChatRequest,
    AdvisorChatResponse,
)

router = APIRouter(prefix="/advisor", tags=["Advisor"])


# ─── Session initialisation ───────────────────────────────────────────────────

@router.post("/session/init", response_model=AdvisorSessionResponse)
async def init_session(req: AdvisorSessionRequest):
    """
    Create a new advisor chat session.

    Body:
        user_id           – caller identifier
        soil_layers       – {"D1": {smu_id, DRG, OC, pH, …}, "D2": …, …}
        crop_requirements – {"wheat": {climate_needs, terrain_needs, soil_needs}, …}

    Returns a session_id to use for all subsequent /chat calls.
    """
    session_id = str(uuid.uuid4())
    context = req.model_dump()   # includes user_id, soil_layers, crop_requirements

    async with AsyncSessionLocal() as db:
        db.add(AdvisorSession(
            session_id=session_id,
            user_id=req.user_id,
            context_json=json.dumps(context),
        ))
        await db.commit()

    return AdvisorSessionResponse(
        session_id=session_id,
        user_id=req.user_id,
        message="Session initialised. You can now send messages to /advisor/chat/message.",
    )


# ─── Chat message ─────────────────────────────────────────────────────────────

@router.post("/chat/message", response_model=AdvisorChatResponse)
async def send_message(req: AdvisorChatRequest):
    """
    Send a user message and receive an agronomist AI reply.

    Body:
        session_id – from /advisor/session/init
        message    – the user's question or statement
    """
    from advisor_service import get_advisor_response

    async with AsyncSessionLocal() as db:
        # Load session context
        result = await db.execute(
            select(AdvisorSession).where(AdvisorSession.session_id == req.session_id)
        )
        session = result.scalar_one_or_none()
        if not session:
            raise HTTPException(
                status_code=404,
                detail="Session not found. Call POST /advisor/session/init first.",
            )

        context = json.loads(session.context_json)

        # Load conversation history
        result = await db.execute(
            select(AdvisorMessage)
            .where(AdvisorMessage.session_id == req.session_id)
            .order_by(AdvisorMessage.created_at)
        )
        messages = result.scalars().all()
        history = [{"role": m.role, "content": m.content} for m in messages]

        # Call LLM
        reply = await get_advisor_response(context, history, req.message)

        # Persist both turns
        db.add(AdvisorMessage(session_id=req.session_id, role="user",      content=req.message))
        db.add(AdvisorMessage(session_id=req.session_id, role="assistant", content=reply))
        await db.commit()

    updated_history = history + [
        {"role": "user",      "content": req.message},
        {"role": "assistant", "content": reply},
    ]

    return AdvisorChatResponse(
        session_id=req.session_id,
        reply=reply,
        history=updated_history,
    )


# ─── History retrieval ────────────────────────────────────────────────────────

@router.get("/chat/history/{session_id}")
async def get_history(session_id: str):
    """Return the full conversation history for a session."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(AdvisorMessage)
            .where(AdvisorMessage.session_id == session_id)
            .order_by(AdvisorMessage.created_at)
        )
        messages = result.scalars().all()

    if not messages:
        raise HTTPException(status_code=404, detail="No messages found for this session.")

    return {
        "session_id": session_id,
        "history": [{"role": m.role, "content": m.content} for m in messages],
    }


# ─── Session reset ────────────────────────────────────────────────────────────

@router.post("/session/reset", response_model=AdvisorSessionResponse)
async def reset_session(req: AdvisorSessionRequest):
    """
    Re-initialise an existing session identified by user_id with new soil/crop data.
    Clears all previous messages and updates the stored context.
    If the user has no existing session a new one is created.
    """
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(AdvisorSession)
            .where(AdvisorSession.user_id == req.user_id)
            .order_by(AdvisorSession.created_at.desc())
        )
        session = result.scalars().first()

        if session:
            session.context_json = json.dumps(req.model_dump())
            await db.execute(
                delete(AdvisorMessage).where(AdvisorMessage.session_id == session.session_id)
            )
            await db.commit()
            session_id = session.session_id
        else:
            session_id = str(uuid.uuid4())
            db.add(AdvisorSession(
                session_id=session_id,
                user_id=req.user_id,
                context_json=json.dumps(req.model_dump()),
            ))
            await db.commit()

    return AdvisorSessionResponse(
        session_id=session_id,
        user_id=req.user_id,
        message="Session reset with new soil and crop data.",
    )


# ─── List sessions for a user ─────────────────────────────────────────────────

@router.get("/sessions/{user_id}")
async def list_sessions(user_id: str):
    """Return all sessions (id + created_at) for a given user_id."""
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(AdvisorSession)
            .where(AdvisorSession.user_id == user_id)
            .order_by(AdvisorSession.created_at.desc())
        )
        sessions = result.scalars().all()

    if not sessions:
        raise HTTPException(status_code=404, detail="No sessions found for this user.")

    return {
        "user_id": user_id,
        "sessions": [
            {"session_id": s.session_id, "created_at": s.created_at.isoformat()}
            for s in sessions
        ],
    }
