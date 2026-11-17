#ifndef HTTP_CLIENT_H
#define HTTP_CLIENT_H

#include "esp_err.h"

/**
 * Send device telemetry to the backend using HTTP POST.
 *
 * @param server_url   Backend telemetry API URL.
 * @param json_payload JSON formatted telemetry data.
 *
 * @return ESP_OK on success, otherwise an ESP error code.
 */
esp_err_t http_client_post_telemetry(
    const char *server_url,
    const char *json_payload
);

#endif /* HTTP_CLIENT_H */