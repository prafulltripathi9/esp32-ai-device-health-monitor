#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <stdbool.h>
#include <stdint.h>

#include "esp_err.h"

/* Wi-Fi connection status and metrics */
typedef struct
{
    bool connected;
    int8_t rssi;
    char ssid[33];
    uint32_t reconnect_count;

} wifi_status_t;


/* Initialize Wi-Fi in station mode */
esp_err_t wifi_manager_init(
    const char *ssid,
    const char *password
);


/* Get current Wi-Fi connection status */
esp_err_t wifi_manager_get_status(
    wifi_status_t *status
);

#endif /* WIFI_MANAGER_H */