#include <string.h>

#include "http_client.h"
#include "esp_http_client.h"
#include "esp_log.h"

static const char *TAG = "HTTP_CLIENT";

static esp_err_t http_event_handler(
    esp_http_client_event_t *event)
{
    switch (event->event_id)
    {
        case HTTP_EVENT_ON_CONNECTED:
            ESP_LOGI(TAG, "Connected to backend");
            break;

        case HTTP_EVENT_ON_DATA:
            if (event->data != NULL && event->data_len > 0)
            {
                ESP_LOGI(TAG, "Server Response: %.*s",
                         event->data_len,
                         (char *)event->data);
            }
            break;

        case HTTP_EVENT_DISCONNECTED:
            ESP_LOGI(TAG, "Disconnected from backend");
            break;

        default:
            break;
    }

    return ESP_OK;
}

esp_err_t http_client_post_telemetry(
    const char *server_url,
    const char *json_payload)
{
    if (server_url == NULL || json_payload == NULL)
    {
        return ESP_ERR_INVALID_ARG;
    }

    esp_http_client_config_t config = {
        .url = server_url,
        .method = HTTP_METHOD_POST,
        .event_handler = http_event_handler,
        .timeout_ms = 10000,
    };

    esp_http_client_handle_t client =
        esp_http_client_init(&config);

    if (client == NULL)
    {
        ESP_LOGE(TAG, "Failed to initialize HTTP client");
        return ESP_FAIL;
    }

    esp_http_client_set_header(
        client,
        "Content-Type",
        "application/json"
    );

    esp_http_client_set_post_field(
        client,
        json_payload,
        strlen(json_payload)
    );

    esp_err_t err = esp_http_client_perform(client);

    if (err == ESP_OK)
    {
        int status_code = esp_http_client_get_status_code(client);

        ESP_LOGI(TAG, "HTTP Status Code: %d", status_code);

        if (status_code >= 200 && status_code < 300)
        {
            ESP_LOGI(TAG, "Telemetry sent successfully");
        }
        else
        {
            ESP_LOGE(TAG, "Backend returned HTTP error: %d",
                     status_code);

            err = ESP_FAIL;
        }
    }
    else
    {
        ESP_LOGE(TAG, "HTTP POST failed: %s",
                 esp_err_to_name(err));
    }

    esp_http_client_cleanup(client);

    return err;
}