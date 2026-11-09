#include <stddef.h>

#include "device_monitor.h"

#include "esp_heap_caps.h"
#include "esp_timer.h"
#include "esp_log.h"
#include "esp_system.h"

static const char *TAG = "DEVICE_MONITOR";


esp_err_t device_monitor_init(void)
{
    ESP_LOGI(TAG, "Device Monitor initialized successfully");

    return ESP_OK;
}



//Device monitor get health function
esp_err_t device_monitor_get_health(device_health_data_t *health_data)
{
    if (health_data == NULL)
    {
        return ESP_ERR_INVALID_ARG;
    }

    health_data->free_heap = esp_get_free_heap_size();

    health_data->minimum_free_heap = esp_get_minimum_free_heap_size();

    health_data->largest_free_block =
        heap_caps_get_largest_free_block(MALLOC_CAP_8BIT);

    health_data->uptime_seconds =
        (uint64_t)(esp_timer_get_time() / 1000000ULL);

    health_data->reset_reason = esp_reset_reason();

    return ESP_OK;
}