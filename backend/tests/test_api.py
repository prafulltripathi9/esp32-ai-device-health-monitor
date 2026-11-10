from app.services.ml_service import ml_health_service


def sample_telemetry(device_id="ESP32_TEST_001"):
    return {
        "device_id": device_id,
        "uptime_seconds": 3600,
        "free_heap": 180000,
        "minimum_free_heap": 150000,
        "largest_free_block": 110592,
        "reset_reason": "Power-on",
        "wifi": {
            "connected": True,
            "ssid": "TestNetwork",
            "rssi": -55,
            "reconnect_count": 0,
        },
    }


def test_root_endpoint(client):
    response = client.get("/")

    assert response.status_code == 200
    assert "running" in response.json()["message"]


def test_health_endpoint(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_receive_telemetry(client):
    response = client.post(
        "/api/v1/telemetry",
        json=sample_telemetry(),
    )

    assert response.status_code == 200
    assert response.json()["success"] is True
    assert response.json()["device_id"] == "ESP32_TEST_001"


def test_get_device_status(client):
    client.post("/api/v1/telemetry", json=sample_telemetry())

    response = client.get("/api/v1/devices/ESP32_TEST_001")

    assert response.status_code == 200
    assert response.json()["success"] is True
    assert response.json()["device"]["device_id"] == "ESP32_TEST_001"


def test_device_history(client):
    client.post("/api/v1/telemetry", json=sample_telemetry())

    response = client.get(
        "/api/v1/devices/ESP32_TEST_001/history",
        params={"limit": 5},
    )

    assert response.status_code == 200
    assert response.json()["total_records"] == 1
    assert len(response.json()["history"]) == 1


def test_device_health(client, monkeypatch):
    client.post("/api/v1/telemetry", json=sample_telemetry())

    expected_health = {
        "health_status": "Healthy",
        "ml_status": "Normal",
        "anomaly_score": 0.25,
        "issues": [],
    }

    monkeypatch.setattr(
        ml_health_service,
        "analyze_device",
        lambda telemetry: expected_health,
    )

    response = client.get(
        "/api/v1/devices/ESP32_TEST_001/health"
    )

    assert response.status_code == 200
    assert response.json()["health"] == expected_health


def test_device_health_history(client, monkeypatch):
    client.post("/api/v1/telemetry", json=sample_telemetry())

    expected_health = {
        "health_status": "Healthy",
        "ml_status": "Normal",
        "anomaly_score": 0.25,
        "issues": [],
    }

    monkeypatch.setattr(
        ml_health_service,
        "analyze_device",
        lambda telemetry: expected_health,
    )

    response = client.get(
        "/api/v1/devices/ESP32_TEST_001/health/history",
        params={"limit": 5},
    )

    assert response.status_code == 200
    assert response.json()["total_records"] == 1
    assert response.json()["history"][0]["health"] == expected_health


def test_unknown_device_returns_404(client):
    response = client.get(
        "/api/v1/devices/ESP32_UNKNOWN"
    )

    assert response.status_code == 404


def test_invalid_telemetry_returns_422(client):
    response = client.post(
        "/api/v1/telemetry",
        json={"device_id": "ESP32_TEST_001"},
    )

    assert response.status_code == 422


def test_invalid_history_limit_returns_422(client):
    response = client.get(
        "/api/v1/devices/ESP32_TEST_001/history",
        params={"limit": 0},
    )

    assert response.status_code == 422