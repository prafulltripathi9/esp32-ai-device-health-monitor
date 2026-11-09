#ifndef HTTP_CLIENT_H
#define HTTP_CLIENT_H

#include "esp_err.h"

esp_err_t http_client_post_telemetry(
    const char *server_url,
    const char *json_payload
);

#endif