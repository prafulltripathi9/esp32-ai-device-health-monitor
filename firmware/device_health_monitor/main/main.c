#include <stdio.h>
#include "http_client.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "wifi_credentials.h"
#include "esp_log.h"
#include "esp_err.h"

#include "device_monitor.h"
#include "wifi_manager.h"
#include "telemetry.h"

static const char *TAG = "MAIN";


#define BACKEND_URL "http://10.157.170.254:8000/api/v1/telemetry"

static const char *get_reset_reason_name(esp_reset_reason_t reason)
{
    switch (reason)
    {
    case ESP_RST_POWERON:
        return "Power-on Reset";

    case ESP_RST_SW:
        return "Software Reset";

    case ESP_RST_PANIC:
        return "Panic Reset";

    case ESP_RST_INT_WDT:
        return "Interrupt Watchdog Reset";

    case ESP_RST_TASK_WDT:
        return "Task Watchdog Reset";

    case ESP_RST_WDT:
        return "Other Watchdog Reset";

    case ESP_RST_DEEPSLEEP:
        return "Deep Sleep Reset";

    case ESP_RST_BROWNOUT:
        return "Brownout Reset";

    case ESP_RST_SDIO:
        return "SDIO Reset";

    default:
        return "Unknown Reset";
    }
}

void app_main(void)
{
    ESP_LOGI(TAG, "Starting ESP32 Device Health Monitor");

    ESP_ERROR_CHECK(device_monitor_init());

    ESP_ERROR_CHECK(
        wifi_manager_init(WIFI_SSID, WIFI_PASSWORD));

    device_health_data_t health_data;
    wifi_status_t wifi_status;

    char json_buffer[512];

    while (1)
    {
        esp_err_t result = device_monitor_get_health(&health_data);

        if (result == ESP_OK)
        {
            ESP_LOGI(TAG, "---------- DEVICE HEALTH ----------");

            ESP_LOGI(TAG, "Free Heap: %lu bytes",
                     (unsigned long)health_data.free_heap);

            ESP_LOGI(TAG, "Minimum Free Heap: %lu bytes",
                     (unsigned long)health_data.minimum_free_heap);

            ESP_LOGI(TAG, "Largest Free Block: %lu bytes",
                     (unsigned long)health_data.largest_free_block);

            ESP_LOGI(TAG, "Uptime: %llu seconds",
                     (unsigned long long)health_data.uptime_seconds);

            ESP_LOGI(TAG, "Reset Reason: %s",
                     get_reset_reason_name(health_data.reset_reason));

            // Collect Wi-Fi information
            esp_err_t wifi_result =
                wifi_manager_get_status(&wifi_status);

            if (wifi_result == ESP_OK)
            {
                ESP_LOGI(TAG, "---------- WIFI STATUS ----------");

                ESP_LOGI(TAG, "Connected: %s",
                         wifi_status.connected ? "Yes" : "No");

                if (wifi_status.connected)
                {
                    ESP_LOGI(TAG, "SSID: %s", wifi_status.ssid);
                    ESP_LOGI(TAG, "RSSI: %d dBm", wifi_status.rssi);
                }

                ESP_LOGI(TAG, "Reconnect Count: %lu",
                         (unsigned long)wifi_status.reconnect_count);

                // Generate JSON telemetry
                esp_err_t telemetry_result =
                    telemetry_generate_json(
                        &health_data,
                        &wifi_status,
                        json_buffer,
                        sizeof(json_buffer));

                if (telemetry_result == ESP_OK)
                {
                    ESP_LOGI(TAG, "---------- JSON TELEMETRY ----------");
                    ESP_LOGI(TAG, "%s", json_buffer);

                    // Send telemetry to backend
                    if (wifi_status.connected)
                    {
                        ESP_LOGI(TAG, "Sending telemetry to backend...");

                        esp_err_t http_result = http_client_post_telemetry(
                            BACKEND_URL,
                            json_buffer);

                        if (http_result == ESP_OK)
                        {
                            ESP_LOGI(TAG, "Telemetry uploaded successfully");
                        }
                        else
                        {
                            ESP_LOGE(TAG, "Telemetry upload failed: %s",
                                     esp_err_to_name(http_result));
                        }
                    }
                    else
                    {
                        ESP_LOGW(TAG, "Wi-Fi disconnected. Skipping upload.");
                    }
                }
                else
                {
                    ESP_LOGE(TAG, "Telemetry generation failed: %s",
                             esp_err_to_name(telemetry_result));
                }
            }
            else
            {
                ESP_LOGE(TAG, "Failed to collect Wi-Fi status");
            }
        }
        else
        {
            ESP_LOGE(TAG, "Failed to collect device health");
        }

        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}