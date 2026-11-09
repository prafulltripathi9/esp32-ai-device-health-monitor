from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    BigInteger,
    func
)

from app.database import Base


class DeviceTelemetry(Base):

    __tablename__ = "device_telemetry"

    id = Column(Integer, primary_key=True, index=True)

    device_id = Column(String(50), nullable=False, index=True)

    uptime_seconds = Column(BigInteger, nullable=False)

    free_heap = Column(BigInteger, nullable=False)

    minimum_free_heap = Column(BigInteger, nullable=False)

    largest_free_block = Column(BigInteger, nullable=False)

    reset_reason = Column(String(50), nullable=False)

    wifi_connected = Column(Boolean, nullable=False)

    wifi_ssid = Column(String(32), nullable=True)

    wifi_rssi = Column(Integer, nullable=False)

    wifi_reconnect_count = Column(Integer, nullable=False)

    created_at = Column(
        DateTime,
        server_default=func.now()
    )