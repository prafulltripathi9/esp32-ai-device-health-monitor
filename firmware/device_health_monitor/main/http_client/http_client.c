#include <string.h>
#include <limits.h>

#include "http_client.h"
#include "esp_http_client.h"
#include "esp_log.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "HTTP_CLIENT";

/* HTTP Configuration */
#define HTTP_TIMEOUT_MS       10000
#define HTTP_MAX_RETRIES      3
#define HTTP_RETRY_DELAY_MS   1000

static esp_err_t http_event_handler(
    esp_http_client_event_t *event)
{
    if (event == NULL)
    {
        return ESP_FAIL;
    }

    switch (event->event_id)
    {
        case HTTP_EVENT_ON_CONNECTED:
            ESP_LOGI(TAG, "Connected to backend");
            break;

        case HTTP_EVENT_ON_DATA:
            if (event->data != NULL && event->data_len > 0)
            {
                ESP_LOGD(TAG, "Server response received: %d bytes",
                         event->data_len);
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
    if (server_url == NULL || server_url[0] == '\0' ||
        json_payload == NULL || json_payload[0] == '\0')
    {
        ESP_LOGE(TAG, "Invalid URL or JSON payload");
        return ESP_ERR_INVALID_ARG;
    }

    size_t payload_length = strlen(json_payload);

    if (payload_length > INT_MAX)
    {
        ESP_LOGE(TAG, "JSON payload is too large");
        return ESP_ERR_INVALID_SIZE;
    }

    esp_http_client_config_t config = {
        .url = server_url,
        .method = HTTP_METHOD_POST,
        .event_handler = http_event_handler,
        .timeout_ms = HTTP_TIMEOUT_MS,
    };

    esp_http_client_handle_t client =
        esp_http_client_init(&config);

    if (client == NULL)
    {
        ESP_LOGE(TAG, "Failed to initialize HTTP client");
        return ESP_FAIL;
    }

    esp_err_t err = esp_http_client_set_header(
        client,
        "Content-Type",
        "application/json"
    );

    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to set HTTP header");
        esp_http_client_cleanup(client);
        return err;
    }

    err = esp_http_client_set_post_field(
        client,
        json_payload,
        (int)payload_length
    );

    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to set POST payload");
        esp_http_client_cleanup(client);
        return err;
    }

    /* Perform HTTP request with retry mechanism */

    for (int attempt = 1; attempt <= HTTP_MAX_RETRIES; attempt++)
    {
        ESP_LOGI(TAG, "Sending telemetry (Attempt %d/%d)",
                 attempt, HTTP_MAX_RETRIES);

        err = esp_http_client_perform(client);

        if (err == ESP_OK)
        {
            int status_code =
                esp_http_client_get_status_code(client);

            ESP_LOGI(TAG, "HTTP Status Code: %d", status_code);

            if (status_code >= 200 && status_code < 300)
            {
                ESP_LOGI(TAG, "Telemetry uploaded successfully");
                err = ESP_OK;
                break;
            }

            ESP_LOGE(TAG, "Backend returned HTTP error: %d",
                     status_code);

            /*
             * Retry only temporary errors:
             * 408 = Request Timeout
             * 429 = Too Many Requests
             * 5xx = Server errors
             */

            if (status_code != 408 &&
                status_code != 429 &&
                status_code < 500)
            {
                ESP_LOGE(TAG, "Non-retryable HTTP error");
                err = ESP_FAIL;
                break;
            }

            err = ESP_FAIL;
        }
        else
        {
            ESP_LOGE(TAG, "HTTP request failed: %s",
                     esp_err_to_name(err));
        }

        /* Wait before next retry */

        if (attempt < HTTP_MAX_RETRIES)
        {
            int delay_ms = HTTP_RETRY_DELAY_MS * attempt;

            ESP_LOGW(TAG, "Retrying in %d ms...", delay_ms);

            vTaskDelay(pdMS_TO_TICKS(delay_ms));
        }
    }

    esp_http_client_cleanup(client);

    return err;
}