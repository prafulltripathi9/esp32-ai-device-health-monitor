import os
import pandas as pd

from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine, text


# Project root directory
PROJECT_ROOT = Path(__file__).resolve().parents[2]

# Load existing backend environment variables
ENV_PATH = PROJECT_ROOT / "backend" / ".env"
load_dotenv(ENV_PATH)

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL not found in backend/.env")


# Database connection
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True
)


def fetch_telemetry(device_id: str = "ESP32_001") -> pd.DataFrame:

    query = text("""
        SELECT
            id,
            device_id,
            uptime_seconds,
            free_heap,
            minimum_free_heap,
            largest_free_block,
            wifi_rssi,
            wifi_reconnect_count,
            wifi_connected,
            created_at
        FROM device_telemetry
        WHERE device_id = :device_id
        ORDER BY created_at ASC, id ASC
    """)

    with engine.connect() as connection:
        dataframe = pd.read_sql(
            query,
            connection,
            params={"device_id": device_id}
        )

    return dataframe