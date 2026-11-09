from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional

from sqlalchemy.orm import Session

from app.database import engine, Base, get_db
from app.models import DeviceTelemetry as TelemetryModel


app = FastAPI(
    title="ESP32 Device Health Monitor API",
    description="Backend API for ESP32 device telemetry",
    version="1.0.0"
)


# Automatically create database tables
Base.metadata.create_all(bind=engine)


class WiFiStatus(BaseModel):
    connected: bool
    ssid: Optional[str] = None
    rssi: int
    reconnect_count: int


class DeviceTelemetry(BaseModel):
    device_id: str
    uptime_seconds: int
    free_heap: int
    minimum_free_heap: int
    largest_free_block: int
    reset_reason: str
    wifi: WiFiStatus


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


@app.post("/api/v1/telemetry")
def receive_telemetry(
    data: DeviceTelemetry,
    db: Session = Depends(get_db)
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
            wifi_reconnect_count=data.wifi.reconnect_count
        )

        db.add(telemetry)
        db.commit()
        db.refresh(telemetry)

        print(f"Telemetry saved successfully: {telemetry.device_id}")

        return {
            "success": True,
            "message": "Telemetry saved successfully",
            "device_id": telemetry.device_id,
            "record_id": telemetry.id
        }

    except Exception as error:
        db.rollback()

        raise HTTPException(
            status_code=500,
            detail=str(error)
        )