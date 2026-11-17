import os
import logging
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker


logger = logging.getLogger(__name__)


# ================= ENVIRONMENT CONFIGURATION =================

# Locate backend/.env independently of the current terminal directory
BACKEND_ROOT = Path(__file__).resolve().parents[1]
ENV_FILE = BACKEND_ROOT / ".env"

load_dotenv(dotenv_path=ENV_FILE)

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL environment variable is not configured. "
        "Check your backend .env file."
    )


# ================= DATABASE ENGINE =================

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=1800,
    pool_size=5,
    max_overflow=10,
    pool_timeout=30,
)


# ================= DATABASE SESSION =================

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


# ================= BASE MODEL =================

Base = declarative_base()


# ================= DATABASE DEPENDENCY =================

def get_db():
    db = SessionLocal()

    try:
        yield db

    except Exception:
        db.rollback()
        logger.exception("Database session error")
        raise

    finally:
        db.close()