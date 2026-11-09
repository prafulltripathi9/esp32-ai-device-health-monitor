#include <stdio.h>
#include <string.h>

#include "telemetry.h"

esp_err_t telemetry_generate_json(
    const device_health_data_t *health_data,
    const wifi_status_t *wifi_status,
    char *json_buffer,
    size_t buffer_size)
{
    if (health_data == NULL ||
        wifi_status == NULL ||
        json_buffer == NULL ||
        buffer_size == 0)
    {
        return ESP_ERR_INVALID_ARG;
    }

    const char *reset_reason = "UNKNOWN";

    switch (health_data->reset_reason)
    {
        case ESP_RST_POWERON:
            reset_reason = "POWERON";
            break;

        case ESP_RST_SW:
            reset_reason = "SOFTWARE";
            break;

        case ESP_RST_PANIC:
            reset_reason = "PANIC";
            break;

        case ESP_RST_INT_WDT:
            reset_reason = "INT_WDT";
            break;

        case ESP_RST_TASK_WDT:
            reset_reason = "TASK_WDT";
            break;

        case ESP_RST_WDT:
            reset_reason = "WDT";
            break;

        case ESP_RST_DEEPSLEEP:
            reset_reason = "DEEPSLEEP";
            break;

        case ESP_RST_BROWNOUT:
            reset_reason = "BROWNOUT";
            break;

        case ESP_RST_SDIO:
            reset_reason = "SDIO";
            break;

        default:
            break;
    }

    int written = snprintf(
        json_buffer,
        buffer_size,

        "{"
        "\"device_id\":\"ESP32_001\","
        "\"uptime_seconds\":%llu,"
        "\"free_heap\":%lu,"
        "\"minimum_free_heap\":%lu,"
        "\"largest_free_block\":%lu,"
        "\"reset_reason\":\"%s\","
        "\"wifi\":{"
        "\"connected\":%s,"
        "\"ssid\":\"%s\","
        "\"rssi\":%d,"
        "\"reconnect_count\":%lu"
        "}"
        "}",

        (unsigned long long)health_data->uptime_seconds,
        (unsigned long)health_data->free_heap,
        (unsigned long)health_data->minimum_free_heap,
        (unsigned long)health_data->largest_free_block,
        reset_reason,
        wifi_status->connected ? "true" : "false",
        wifi_status->ssid,
        wifi_status->rssi,
        (unsigned long)wifi_status->reconnect_count
    );

    if (written < 0 || (size_t)written >= buffer_size)
    {
        return ESP_ERR_INVALID_SIZE;
    }

    return ESP_OK;
}