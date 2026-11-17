import logging
import os

from typing import Optional

from fastapi import FastAPI, Depends, HTTPException, Query, Path
from fastapi.middleware.cors import CORSMiddleware

from pydantic import BaseModel, Field

from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

from app.services.ml_service import ml_health_service
from app.database import engine, Base, get_db
from app.models import DeviceTelemetry as TelemetryModel


logger = logging.getLogger(__name__)


# --------------------------------------------------
# Application Configuration
# --------------------------------------------------

app = FastAPI(
    title="ESP32 Device Health Monitor API",
    description="Backend API for ESP32 device telemetry",
    version="1.0.0",
)


# CORS configuration
# Add additional frontend origins through the CORS_ORIGINS environment variable.
configured_origins = os.getenv("CORS_ORIGINS", "")

allowed_origins = [
    origin.strip()
    for origin in configured_origins.split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)


# Automatically create database tables
Base.metadata.create_all(bind=engine)


# --------------------------------------------------
# Request Validation Models
# --------------------------------------------------

class WiFiStatus(BaseModel):
    connected: bool

    ssid: Optional[str] = Field(
        default=None,
        max_length=32,
    )

    rssi: int = Field(
        ge=-127,
        le=0,
    )

    reconnect_count: int = Field(
        ge=0,
    )


class DeviceTelemetry(BaseModel):
    device_id: str = Field(
        min_length=1,
        max_length=50,
    )

    uptime_seconds: int = Field(
        ge=0,
    )

    free_heap: int = Field(
        ge=0,
    )

    minimum_free_heap: int = Field(
        ge=0,
    )

    largest_free_block: int = Field(
        ge=0,
    )

    reset_reason: str = Field(
        min_length=1,
        max_length=50,
    )

    wifi: WiFiStatus


# --------------------------------------------------
# Helper Functions
# --------------------------------------------------

def format_telemetry(telemetry):
    return {
        "id": telemetry.id,
        "device_id": telemetry.device_id,
        "uptime_seconds": telemetry.uptime_seconds,
        "free_heap": telemetry.free_heap,
        "minimum_free_heap": telemetry.minimum_free_heap,
        "largest_free_block": telemetry.largest_free_block,
        "reset_reason": telemetry.reset_reason,
        "wifi": {
            "connected": telemetry.wifi_connected,
            "ssid": telemetry.wifi_ssid,
            "rssi": telemetry.wifi_rssi,
            "reconnect_count": telemetry.wifi_reconnect_count,
        },
        "created_at": telemetry.created_at,
    }


def get_latest_telemetry(device_id: str, db: Session):
    return (
        db.query(TelemetryModel)
        .filter(TelemetryModel.device_id == device_id)
        .order_by(
            TelemetryModel.created_at.desc(),
            TelemetryModel.id.desc(),
        )
        .first()
    )


def analyze_device_health(telemetry):
    try:
        return ml_health_service.analyze_device(telemetry)

    except Exception:
        logger.exception(
            "Health analysis failed for device: %s",
            telemetry.device_id,
        )

        raise HTTPException(
            status_code=503,
            detail="Device health analysis is temporarily unavailable.",
        )


# --------------------------------------------------
# Basic Routes
# --------------------------------------------------

@app.get("/")
def home():
    return {
        "message": "ESP32 Device Health Monitor Backend is running"
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy"
    }


# --------------------------------------------------
# Receive ESP32 Telemetry
# --------------------------------------------------

@app.post("/api/v1/telemetry")
def receive_telemetry(
    data: DeviceTelemetry,
    db: Session = Depends(get_db),
):
    try:
        telemetry = TelemetryModel(
            device_id=data.device_id,
            uptime_seconds=data.uptime_seconds,
            free_heap=data.free_heap,
            minimum_free_heap=data.minimum_free_heap,
            largest_free_block=data.largest_free_block,
            reset_reason=data.reset_reason,
            wifi_connected=data.wifi.connected,
            wifi_ssid=data.wifi.ssid,
            wifi_rssi=data.wifi.rssi,
            wifi_reconnect_count=data.wifi.reconnect_count,
        )

        db.add(telemetry)
        db.commit()
        db.refresh(telemetry)

        logger.info(
            "Telemetry saved successfully for device: %s",
            telemetry.device_id,
        )

        return {
            "success": True,
            "message": "Telemetry saved successfully",
            "device_id": telemetry.device_id,
            "record_id": telemetry.id,
        }

    except SQLAlchemyError:
        db.rollback()

        logger.exception("Database error while saving telemetry.")

        raise HTTPException(
            status_code=500,
            detail="Unable to save telemetry due to a database error.",
        )

    except Exception:
        db.rollback()

        logger.exception("Unexpected error while receiving telemetry.")

        raise HTTPException(
            status_code=500,
            detail="An unexpected error occurred while saving telemetry.",
        )


# --------------------------------------------------
# Get All Registered Devices
# --------------------------------------------------

@app.get("/api/v1/devices")
def get_all_devices(db: Session = Depends(get_db)):

    device_ids = (
        db.query(TelemetryModel.device_id)
        .distinct()
        .all()
    )

    devices = []

    for item in device_ids:
        device_id = item[0]

        telemetry = get_latest_telemetry(device_id, db)

        if telemetry is None:
            continue

        health = analyze_device_health(telemetry)

        devices.append(
            {
                "device_id": device_id,
                "health": health,
                "telemetry": format_telemetry(telemetry),
            }
        )

    return {
        "success": True,
        "total_devices": len(devices),
        "devices": devices,
    }


# --------------------------------------------------
# Get Latest Device Status
# --------------------------------------------------

@app.get("/api/v1/devices/{device_id}")
def get_device_status(
    device_id: str = Path(..., min_length=1, max_length=50),
    db: Session = Depends(get_db),
):

    telemetry = get_latest_telemetry(device_id, db)

    if telemetry is None:
        raise HTTPException(
            status_code=404,
            detail="Device telemetry not found",
        )

    return {
        "success": True,
        "device": format_telemetry(telemetry),
    }


# --------------------------------------------------
# Get Device Telemetry History
# --------------------------------------------------

@app.get("/api/v1/devices/{device_id}/history")
def get_device_history(
    device_id: str = Path(..., min_length=1, max_length=50),
    limit: int = Query(default=50, ge=1, le=500),
    db: Session = Depends(get_db),
):

    records = (
        db.query(TelemetryModel)
        .filter(TelemetryModel.device_id == device_id)
        .order_by(
            TelemetryModel.created_at.desc(),
            TelemetryModel.id.desc(),
        )
        .limit(limit)
        .all()
    )

    return {
        "success": True,
        "device_id": device_id,
        "total_records": len(records),
        "history": [
            format_telemetry(record)
            for record in records
        ],
    }


# --------------------------------------------------
# Get AI-Powered Device Health
# --------------------------------------------------

@app.get("/api/v1/devices/{device_id}/health")
def get_device_health(
    device_id: str = Path(..., min_length=1, max_length=50),
    db: Session = Depends(get_db),
):

    telemetry = get_latest_telemetry(device_id, db)

    if telemetry is None:
        raise HTTPException(
            status_code=404,
            detail="Device telemetry not found",
        )

    health = analyze_device_health(telemetry)

    return {
        "success": True,
        "device_id": device_id,
        "health": health,
        "telemetry": format_telemetry(telemetry),
    }


# --------------------------------------------------
# Get Device Health History
# --------------------------------------------------

@app.get("/api/v1/devices/{device_id}/health/history")
def get_device_health_history(
    device_id: str = Path(..., min_length=1, max_length=50),
    limit: int = Query(default=50, ge=1, le=500),
    db: Session = Depends(get_db),
):

    records = (
        db.query(TelemetryModel)
        .filter(TelemetryModel.device_id == device_id)
        .order_by(
            TelemetryModel.created_at.desc(),
            TelemetryModel.id.desc(),
        )
        .limit(limit)
        .all()
    )

    if not records:
        raise HTTPException(
            status_code=404,
            detail="Device telemetry history not found",
        )

    history = []

    for record in records:
        health = analyze_device_health(record)

        history.append(
            {
                "telemetry_id": record.id,
                "created_at": record.created_at,
                "health": health,
                "telemetry": format_telemetry(record),
            }
        )

    return {
        "success": True,
        "device_id": device_id,
        "total_records": len(history),
        "history": history,
    }