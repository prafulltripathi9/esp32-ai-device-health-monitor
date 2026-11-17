#ifndef TELEMETRY_H
#define TELEMETRY_H

#include <stddef.h>

#include "esp_err.h"
#include "device_monitor.h"
#include "wifi_manager.h"

/**
 * Generate device telemetry in JSON format.
 *
 * @param health_data Device health metrics.
 * @param wifi_status Wi-Fi connection metrics.
 * @param json_buffer Output JSON buffer.
 * @param buffer_size Size of output buffer.
 *
 * @return ESP_OK on success, otherwise ESP error code.
 */
esp_err_t telemetry_generate_json(
    const device_health_data_t *health_data,
    const wifi_status_t *wifi_status,
    char *json_buffer,
    size_t buffer_size
);

#endif /* TELEMETRY_H */