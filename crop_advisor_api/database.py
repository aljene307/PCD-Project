from dotenv import load_dotenv
load_dotenv()

from datetime import datetime
from sqlalchemy import (
    Column, String, Text, DateTime, Integer,
    Float, ForeignKey, UniqueConstraint, create_engine
)
from sqlalchemy.orm import declarative_base, relationship
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

DATABASE_URL      = "sqlite+aiosqlite:///./crop_knowledge.db"
SYNC_DATABASE_URL = "sqlite:///./crop_knowledge.db"

Base = declarative_base()


# ─── Crop Knowledge Base ──────────────────────────────────────────────────────

class Crop(Base):
    """
    Core crop identity + the full notes text (primary RAG source).
    One row per crop species.
    """
    __tablename__ = "crops"

    id                = Column(Integer, primary_key=True, autoincrement=True)
    common_name       = Column(String(200), nullable=False, unique=True, index=True)
    scientific_name   = Column(String(200), nullable=True)

    # From description{}
    life_form         = Column(String(100), nullable=True)   # e.g. "shrub"
    physiology        = Column(String(200), nullable=True)   # e.g. "evergreen, multi stem"
    habit             = Column(String(100), nullable=True)   # e.g. "erect"
    category          = Column(String(200), nullable=True)   # e.g. "materials, medicinals..."
    life_span         = Column(String(100), nullable=True)   # e.g. "perennial"
    plant_attributes  = Column(String(200), nullable=True)   # e.g. "grown on large scale"

    # Primary RAG source — full botanical/agronomic text
    notes             = Column(Text, nullable=True)

    created_at        = Column(DateTime, default=datetime.utcnow)
    updated_at        = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    ecology           = relationship("CropEcology",     back_populates="crop", uselist=False, cascade="all, delete-orphan")
    climate           = relationship("CropClimate",     back_populates="crop", uselist=False, cascade="all, delete-orphan")
    cultivation       = relationship("CropCultivation", back_populates="crop", uselist=False, cascade="all, delete-orphan")
    session_crops     = relationship("SessionCrop",     back_populates="crop")


class CropEcology(Base):
    """
    All numeric soil & climate tolerance ranges.
    opt = optimal range, abs = absolute (survival) range.
    """
    __tablename__ = "crop_ecology"

    id              = Column(Integer, primary_key=True, autoincrement=True)
    crop_id         = Column(Integer, ForeignKey("crops.id", ondelete="CASCADE"), nullable=False, unique=True)

    # Temperature (°C)
    temp_opt_min    = Column(Float, nullable=True)
    temp_opt_max    = Column(Float, nullable=True)
    temp_abs_min    = Column(Float, nullable=True)
    temp_abs_max    = Column(Float, nullable=True)

    # Annual rainfall (mm)
    rainfall_opt_min = Column(Float, nullable=True)
    rainfall_opt_max = Column(Float, nullable=True)
    rainfall_abs_min = Column(Float, nullable=True)
    rainfall_abs_max = Column(Float, nullable=True)

    # Soil pH
    soil_ph_opt_min  = Column(Float, nullable=True)
    soil_ph_opt_max  = Column(Float, nullable=True)
    soil_ph_abs_min  = Column(Float, nullable=True)
    soil_ph_abs_max  = Column(Float, nullable=True)

    # Altitude (m)
    altitude_abs_min = Column(Float, nullable=True)
    altitude_abs_max = Column(Float, nullable=True)

    # Latitude (degrees)
    latitude_abs_min = Column(Float, nullable=True)
    latitude_abs_max = Column(Float, nullable=True)

    # Qualitative soil properties
    soil_texture_optimal  = Column(String(200), nullable=True)
    soil_texture_absolute = Column(String(200), nullable=True)
    soil_depth_optimal    = Column(String(200), nullable=True)
    soil_depth_absolute   = Column(String(200), nullable=True)
    soil_fertility_optimal  = Column(String(100), nullable=True)
    soil_fertility_absolute = Column(String(100), nullable=True)
    soil_drainage_optimal   = Column(String(100), nullable=True)
    soil_drainage_absolute  = Column(String(100), nullable=True)
    soil_salinity_optimal   = Column(String(100), nullable=True)
    soil_salinity_absolute  = Column(String(100), nullable=True)
    light_intensity_optimal  = Column(String(100), nullable=True)
    light_intensity_absolute = Column(String(100), nullable=True)

    crop = relationship("Crop", back_populates="ecology")


class CropClimate(Base):
    """
    Climate zone, photoperiod, and killing temperature info.
    """
    __tablename__ = "crop_climate"

    id                      = Column(Integer, primary_key=True, autoincrement=True)
    crop_id                 = Column(Integer, ForeignKey("crops.id", ondelete="CASCADE"), nullable=False, unique=True)

    climate_zone            = Column(Text,        nullable=True)   # e.g. "tropical wet & dry (Aw)..."
    photoperiod             = Column(String(200),  nullable=True)   # e.g. "short day (<12 hours)..."
    killing_temp_rest       = Column(String(200),  nullable=True)
    killing_temp_growth     = Column(String(200),  nullable=True)
    abiotic_tolerance       = Column(Text,        nullable=True)
    abiotic_susceptibility  = Column(Text,        nullable=True)
    introduction_risks      = Column(Text,        nullable=True)

    crop = relationship("Crop", back_populates="climate")


class CropCultivation(Base):
    """
    Production system, crop cycle duration, and companion species.
    """
    __tablename__ = "crop_cultivation"

    id                  = Column(Integer, primary_key=True, autoincrement=True)
    crop_id             = Column(Integer, ForeignKey("crops.id", ondelete="CASCADE"), nullable=False, unique=True)

    production_system   = Column(String(200), nullable=True)
    crop_cycle_min      = Column(Integer,     nullable=True)   # days
    crop_cycle_max      = Column(Integer,     nullable=True)   # days
    cropping_system     = Column(String(200), nullable=True)
    subsystem           = Column(String(200), nullable=True)
    companion_species   = Column(Text,        nullable=True)
    mechanization_level = Column(String(100), nullable=True)
    labour_intensity    = Column(String(100), nullable=True)

    crop = relationship("Crop", back_populates="cultivation")


# ─── Chat System ──────────────────────────────────────────────────────────────

class ChatSession(Base):
    """
    One session per user analysis. Stores the enriched JSON + links to crop knowledge.
    """
    __tablename__ = "chat_sessions"

    session_id    = Column(String, primary_key=True)
    enriched_json = Column(Text, nullable=False)
    created_at    = Column(DateTime, default=datetime.utcnow)

    messages      = relationship("ChatMessage",  back_populates="session", cascade="all, delete-orphan")
    session_crops = relationship("SessionCrop",  back_populates="session", cascade="all, delete-orphan")


class ChatMessage(Base):
    """
    Individual messages in a chat session.
    """
    __tablename__ = "chat_messages"

    id         = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String, ForeignKey("chat_sessions.session_id", ondelete="CASCADE"), nullable=False, index=True)
    role       = Column(String, nullable=False)    # "user" or "assistant"
    content    = Column(Text,   nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    session = relationship("ChatSession", back_populates="messages")


class SessionCrop(Base):
    """
    Join table: links a chat session to the crops recommended in that session.
    Rank preserved so we know which crop was #1, #2, etc.
    """
    __tablename__ = "session_crops"
    __table_args__ = (UniqueConstraint("session_id", "crop_id", name="uq_session_crop"),)

    id         = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String,  ForeignKey("chat_sessions.session_id", ondelete="CASCADE"), nullable=False, index=True)
    crop_id    = Column(Integer, ForeignKey("crops.id",                 ondelete="CASCADE"), nullable=False)
    rank       = Column(Integer, nullable=False)

    session    = relationship("ChatSession", back_populates="session_crops")
    crop       = relationship("Crop",        back_populates="session_crops")


# ─── Advisor Sessions (new user_id-based design) ─────────────────────────────

class AdvisorSession(Base):
    """
    Stores one soil+crop context per session.
    Many sessions can share the same user_id (one per analysis run).
    """
    __tablename__ = "advisor_sessions"

    session_id   = Column(String,   primary_key=True)
    user_id      = Column(String,   nullable=False, index=True)
    context_json = Column(Text,     nullable=False)   # serialised AdvisorSessionRequest
    created_at   = Column(DateTime, default=datetime.utcnow)

    messages = relationship("AdvisorMessage", back_populates="session", cascade="all, delete-orphan")


class AdvisorMessage(Base):
    """Individual turns in an advisor chat session."""
    __tablename__ = "advisor_messages"

    id         = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String,  ForeignKey("advisor_sessions.session_id", ondelete="CASCADE"), nullable=False, index=True)
    role       = Column(String,  nullable=False)   # "user" or "assistant"
    content    = Column(Text,    nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    session = relationship("AdvisorSession", back_populates="messages")


# ─── Engines & Init ───────────────────────────────────────────────────────────

sync_engine = create_engine(SYNC_DATABASE_URL, connect_args={"check_same_thread": False})

def init_db():
    Base.metadata.create_all(bind=sync_engine)

async_engine      = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = async_sessionmaker(async_engine, expire_on_commit=False)


# ─── Soil Analysis (Lab Reports) ─────────────────────────────────────────────

class SoilAnalysis(Base):
    """
    One report per submission. Links to individual measurements.
    """
    __tablename__ = "soil_analyses"

    id         = Column(Integer, primary_key=True, autoincrement=True)
    report_ref = Column(String(200), nullable=True)   # e.g. "20260406-R-HM"
    source     = Column(String(50),  nullable=False, default="upload")  # "upload" or "json"
    created_at = Column(DateTime, default=datetime.utcnow)

    measurements = relationship("SoilMeasurement", back_populates="analysis", cascade="all, delete-orphan")


class SoilMeasurement(Base):
    """
    One row per measurement in a soil analysis report.
    """
    __tablename__ = "soil_measurements"

    id          = Column(Integer, primary_key=True, autoincrement=True)
    analysis_id = Column(Integer, ForeignKey("soil_analyses.id", ondelete="CASCADE"), nullable=False, index=True)
    attribute   = Column(String(200), nullable=False)   # e.g. "pH"
    iso_method  = Column(String(200), nullable=True)    # e.g. "NF EN ISO 10390 (2022)"
    unit        = Column(String(50),  nullable=True)    # e.g. "---", "mS/Cm", "%"
    value       = Column(Float,       nullable=True)

    analysis = relationship("SoilAnalysis", back_populates="measurements")