#include <stddef.h>
#include <string.h>

#include "device_monitor.h"

#include "esp_heap_caps.h"
#include "esp_timer.h"
#include "esp_log.h"
#include "esp_system.h"

static const char *TAG = "DEVICE_MONITOR";


/* Initialize Device Monitor */
esp_err_t device_monitor_init(void)
{
    ESP_LOGI(TAG, "Initializing Device Monitor");

    ESP_LOGI(TAG, "Device Monitor initialized successfully");

    return ESP_OK;
}


/* Collect ESP32 device health metrics */
esp_err_t device_monitor_get_health(device_health_data_t *health_data)
{
    if (health_data == NULL)
    {
        ESP_LOGE(TAG, "Invalid health data pointer");
        return ESP_ERR_INVALID_ARG;
    }

    /* Clear previous data */
    memset(health_data, 0, sizeof(device_health_data_t));

    /* Memory Metrics */
    health_data->free_heap =
        (uint32_t)esp_get_free_heap_size();

    health_data->minimum_free_heap =
        (uint32_t)esp_get_minimum_free_heap_size();

    health_data->largest_free_block =
        (uint32_t)heap_caps_get_largest_free_block(
            MALLOC_CAP_8BIT
        );

    /* System Metrics */
    health_data->uptime_seconds =
        (uint64_t)(esp_timer_get_time() / 1000000ULL);

    health_data->reset_reason = esp_reset_reason();

    ESP_LOGD(TAG, "Device health metrics collected");

    return ESP_OK;
}