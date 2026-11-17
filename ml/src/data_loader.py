import os
import logging
import pandas as pd

from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError


logger = logging.getLogger(__name__)


# Project root directory
PROJECT_ROOT = Path(__file__).resolve().parents[2]

# Load existing backend environment variables
ENV_PATH = PROJECT_ROOT / "backend" / ".env"
load_dotenv(ENV_PATH)

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL not found in backend/.env"
    )


# Database connection
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_recycle=1800,
)


# Required dataset columns
REQUIRED_COLUMNS = [
    "id",
    "device_id",
    "uptime_seconds",
    "free_heap",
    "minimum_free_heap",
    "largest_free_block",
    "wifi_rssi",
    "wifi_reconnect_count",
    "wifi_connected",
    "created_at",
]


def fetch_telemetry(
    device_id: str = "ESP32_001",
) -> pd.DataFrame:

    if not isinstance(device_id, str) or not device_id.strip():
        raise ValueError("A valid device_id must be provided.")

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

    try:
        with engine.connect() as connection:

            dataframe = pd.read_sql(
                query,
                connection,
                params={"device_id": device_id.strip()},
            )

        if dataframe.empty:
            logger.warning(
                "No telemetry records found for device: %s",
                device_id,
            )
            return dataframe

        missing_columns = [
            column
            for column in REQUIRED_COLUMNS
            if column not in dataframe.columns
        ]

        if missing_columns:
            raise ValueError(
                f"Missing dataset columns: {missing_columns}"
            )

        logger.info(
            "Fetched %s telemetry records for device %s",
            len(dataframe),
            device_id,
        )

        return dataframe

    except SQLAlchemyError:
        logger.exception(
            "Database error while fetching telemetry for device: %s",
            device_id,
        )
        raise


def close_database_connection():
    """Dispose database connection pool."""
    engine.dispose()