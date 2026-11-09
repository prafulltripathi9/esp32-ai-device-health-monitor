#ifndef DEVICE_MONITOR_H
#define DEVICE_MONITOR_H

#include <stdint.h>
#include <stdbool.h>

#include"esp_err.h"
#include"esp_system.h"

typedef struct
{
    // Memory Metrics
    uint32_t free_heap;
    uint32_t minimum_free_heap;
    uint32_t largest_free_block;

    // System Metrics
    uint64_t uptime_seconds;
    esp_reset_reason_t reset_reason;

    // Wi-Fi Metrics
    bool wifi_connected;
    int8_t wifi_rssi;
    char wifi_ssid[33];
    uint32_t wifi_reconnect_count;

} device_health_data_t;

esp_err_t device_monitor_init(void);

esp_err_t  device_monitor_get_health(device_health_data_t *health_data);

#endif //DEVICE_MONITOR_H