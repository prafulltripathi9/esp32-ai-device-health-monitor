#ifndef SYSTEM_CONFIG_H
#define SYSTEM_CONFIG_H

/* ================= DEVICE CONFIGURATION ================= */

#define SYSTEM_DEVICE_ID              "ESP32_001"

/* ================= BACKEND CONFIGURATION ================= */

#define SYSTEM_BACKEND_URL            "http://192.168.1.81:8000/api/v1/telemetry"

/* ================= TELEMETRY CONFIGURATION ================= */

#define TELEMETRY_INTERVAL_MS         5000U
#define TELEMETRY_JSON_BUFFER_SIZE    512U

/* ================= HTTP CONFIGURATION ================= */

#define HTTP_MAX_RETRIES              3U
#define HTTP_RETRY_BASE_DELAY_MS      1000U
#define HTTP_TIMEOUT_MS               10000

/* ================= WIFI CONFIGURATION ================= */

#define WIFI_RECONNECT_BASE_DELAY_MS  1000U
#define WIFI_RECONNECT_MAX_DELAY_MS   30000U

#endif /* SYSTEM_CONFIG_H */