from fastapi import FastAPI, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional
from sqlalchemy.orm import Session
from app.services.ml_service import ml_health_service
from app.database import engine, Base, get_db
from app.models import DeviceTelemetry as TelemetryModel
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="ESP32 Device Health Monitor API",
    description="Backend API for ESP32 device telemetry",
    version="1.0.0",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
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


@app.get("/")
def home():
    return {"message": "ESP32 Device Health Monitor Backend is running"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}


# Receive ESP32 telemetry
@app.post("/api/v1/telemetry")
def receive_telemetry(data: DeviceTelemetry, db: Session = Depends(get_db)):
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

        print(f"Telemetry saved successfully: {telemetry.device_id}")

        return {
            "success": True,
            "message": "Telemetry saved successfully",
            "device_id": telemetry.device_id,
            "record_id": telemetry.id,
        }

    except Exception as error:
        db.rollback()

        raise HTTPException(status_code=500, detail=str(error))


# Get all registered devices
@app.get("/api/v1/devices")
def get_all_devices(db: Session = Depends(get_db)):

    device_ids = db.query(TelemetryModel.device_id).distinct().all()

    devices = []

    for item in device_ids:
        device_id = item[0]

        telemetry = (
            db.query(TelemetryModel)
            .filter(TelemetryModel.device_id == device_id)
            .order_by(TelemetryModel.created_at.desc(), TelemetryModel.id.desc())
            .first()
        )

        if telemetry is None:
            continue

        health = ml_health_service.analyze_device(telemetry)

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


# Get latest device status
@app.get("/api/v1/devices/{device_id}")
def get_device_status(device_id: str, db: Session = Depends(get_db)):
    telemetry = (
        db.query(TelemetryModel)
        .filter(TelemetryModel.device_id == device_id)
        .order_by(TelemetryModel.created_at.desc(), TelemetryModel.id.desc())
        .first()
    )

    if telemetry is None:
        raise HTTPException(status_code=404, detail="Device telemetry not found")

    return {"success": True, "device": format_telemetry(telemetry)}


# Get device telemetry history
@app.get("/api/v1/devices/{device_id}/history")
def get_device_history(
    device_id: str,
    limit: int = Query(default=50, ge=1, le=500),
    db: Session = Depends(get_db),
):
    records = (
        db.query(TelemetryModel)
        .filter(TelemetryModel.device_id == device_id)
        .order_by(TelemetryModel.created_at.desc(), TelemetryModel.id.desc())
        .limit(limit)
        .all()
    )

    return {
        "success": True,
        "device_id": device_id,
        "total_records": len(records),
        "history": [format_telemetry(record) for record in records],
    }


# Get AI-powered device health
@app.get("/api/v1/devices/{device_id}/health")
def get_device_health(device_id: str, db: Session = Depends(get_db)):
    telemetry = (
        db.query(TelemetryModel)
        .filter(TelemetryModel.device_id == device_id)
        .order_by(TelemetryModel.created_at.desc(), TelemetryModel.id.desc())
        .first()
    )

    if telemetry is None:
        raise HTTPException(status_code=404, detail="Device telemetry not found")

    try:
        health = ml_health_service.analyze_device(telemetry)

        return {
            "success": True,
            "device_id": device_id,
            "health": health,
            "telemetry": format_telemetry(telemetry),
        }

    except Exception as error:
        raise HTTPException(
            status_code=500, detail=f"Health analysis failed: {str(error)}"
        )


# Get device health history
@app.get("/api/v1/devices/{device_id}/health/history")
def get_device_health_history(
    device_id: str,
    limit: int = Query(default=50, ge=1, le=500),
    db: Session = Depends(get_db),
):
    records = (
        db.query(TelemetryModel)
        .filter(TelemetryModel.device_id == device_id)
        .order_by(TelemetryModel.created_at.desc(), TelemetryModel.id.desc())
        .limit(limit)
        .all()
    )

    if not records:
        raise HTTPException(
            status_code=404, detail="Device telemetry history not found"
        )

    try:
        history = []

        for record in records:
            health = ml_health_service.analyze_device(record)

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

    except Exception as error:
        raise HTTPException(
            status_code=500, detail=f"Health history analysis failed: {str(error)}"
        )
