#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#include "esp_err.h"

typedef struct
{
    bool connected;
    int8_t rssi;
    char ssid[33];
    uint32_t reconnect_count;

}wifi_status_t;

// Initialize Wi-Fi
esp_err_t wifi_manager_init(const char *ssid, const char *password);

// Get current Wi-Fi status
esp_err_t wifi_manager_get_status(wifi_status_t *status);

#endif // WIFI_MANAGER_H