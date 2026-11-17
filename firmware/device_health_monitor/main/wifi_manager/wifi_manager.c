#include <string.h>
#include <stdbool.h>

#include "wifi_manager.h"
#include "../system_config/system_config.h"

#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_netif.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "nvs_flash.h"

static const char *TAG = "WIFI_MANAGER";

static volatile bool wifi_connected = false;
static volatile uint32_t reconnect_count = 0;

static uint32_t reconnect_attempt = 0;

static esp_timer_handle_t reconnect_timer = NULL;
static bool wifi_initialized = false;


/* Schedule Wi-Fi reconnection with exponential backoff */
static void schedule_reconnect(void)
{
    if (reconnect_timer == NULL)
    {
        return;
    }

    uint32_t delay_ms = WIFI_RECONNECT_BASE_DELAY_MS;

    uint32_t shift = reconnect_attempt > 5U
                         ? 5U
                         : reconnect_attempt;

    delay_ms <<= shift;

    if (delay_ms > WIFI_RECONNECT_MAX_DELAY_MS)
    {
        delay_ms = WIFI_RECONNECT_MAX_DELAY_MS;
    }

    reconnect_attempt++;

    ESP_LOGW(TAG,
             "Scheduling reconnect in %lu ms (Attempt %lu)",
             (unsigned long)delay_ms,
             (unsigned long)reconnect_attempt);

    if (esp_timer_is_active(reconnect_timer))
    {
        esp_timer_stop(reconnect_timer);
    }

    esp_err_t ret = esp_timer_start_once(
        reconnect_timer,
        (uint64_t)delay_ms * 1000ULL
    );

    if (ret != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to schedule reconnect: %s",
                 esp_err_to_name(ret));
    }
}


/* Reconnection timer callback */
static void reconnect_timer_callback(void *arg)
{
    (void)arg;

    if (!wifi_connected)
    {
        ESP_LOGI(TAG, "Attempting Wi-Fi reconnection...");

        esp_err_t ret = esp_wifi_connect();

        if (ret != ESP_OK)
        {
            ESP_LOGW(TAG, "Reconnect request failed: %s",
                     esp_err_to_name(ret));
        }
    }
}


/* Handle Wi-Fi and IP events */
static void wifi_event_handler(
    void *arg,
    esp_event_base_t event_base,
    int32_t event_id,
    void *event_data)
{
    (void)arg;

    if (event_base == WIFI_EVENT &&
        event_id == WIFI_EVENT_STA_START)
    {
        ESP_LOGI(TAG, "Connecting to Wi-Fi...");

        esp_err_t ret = esp_wifi_connect();

        if (ret != ESP_OK)
        {
            ESP_LOGE(TAG, "Initial connection failed: %s",
                     esp_err_to_name(ret));

            schedule_reconnect();
        }
    }

    else if (event_base == WIFI_EVENT &&
             event_id == WIFI_EVENT_STA_DISCONNECTED)
    {
        wifi_connected = false;
        reconnect_count++;

        ESP_LOGW(TAG, "Wi-Fi disconnected");

        schedule_reconnect();
    }

    else if (event_base == IP_EVENT &&
             event_id == IP_EVENT_STA_GOT_IP)
    {
        wifi_connected = true;
        reconnect_attempt = 0;

        if (reconnect_timer != NULL &&
            esp_timer_is_active(reconnect_timer))
        {
            esp_timer_stop(reconnect_timer);
        }

        ip_event_got_ip_t *event =
            (ip_event_got_ip_t *)event_data;

        if (event != NULL)
        {
            ESP_LOGI(TAG, "Wi-Fi connected successfully");

            ESP_LOGI(TAG, "IP Address: " IPSTR,
                     IP2STR(&event->ip_info.ip));
        }
    }
}


/* Initialize Wi-Fi */
esp_err_t wifi_manager_init(
    const char *ssid,
    const char *password)
{
    if (ssid == NULL ||
        password == NULL ||
        strlen(ssid) == 0 ||
        strlen(ssid) > 32 ||
        strlen(password) >= 64)
    {
        return ESP_ERR_INVALID_ARG;
    }

    if (wifi_initialized)
    {
        ESP_LOGW(TAG, "Wi-Fi already initialized");
        return ESP_OK;
    }

    /* Initialize NVS */
    esp_err_t ret = nvs_flash_init();

    if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
        ret == ESP_ERR_NVS_NEW_VERSION_FOUND)
    {
        ret = nvs_flash_erase();

        if (ret != ESP_OK)
        {
            return ret;
        }

        ret = nvs_flash_init();
    }

    if (ret != ESP_OK)
    {
        return ret;
    }

    /* Initialize network interface */
    ret = esp_netif_init();

    if (ret != ESP_OK &&
        ret != ESP_ERR_INVALID_STATE)
    {
        return ret;
    }

    ret = esp_event_loop_create_default();

    if (ret != ESP_OK &&
        ret != ESP_ERR_INVALID_STATE)
    {
        return ret;
    }

    if (esp_netif_create_default_wifi_sta() == NULL)
    {
        ESP_LOGE(TAG, "Failed to create Wi-Fi station interface");
        return ESP_FAIL;
    }

    /* Initialize Wi-Fi driver */
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();

    ret = esp_wifi_init(&cfg);

    if (ret != ESP_OK)
    {
        return ret;
    }

    /* Create reconnect timer */
    const esp_timer_create_args_t timer_args = {
        .callback = reconnect_timer_callback,
        .arg = NULL,
        .name = "wifi_reconnect"
    };

    ret = esp_timer_create(
        &timer_args,
        &reconnect_timer
    );

    if (ret != ESP_OK)
    {
        return ret;
    }

    /* Register Wi-Fi event handler */
    ret = esp_event_handler_register(
        WIFI_EVENT,
        ESP_EVENT_ANY_ID,
        &wifi_event_handler,
        NULL
    );

    if (ret != ESP_OK)
    {
        return ret;
    }

    /* Register IP event handler */
    ret = esp_event_handler_register(
        IP_EVENT,
        IP_EVENT_STA_GOT_IP,
        &wifi_event_handler,
        NULL
    );

    if (ret != ESP_OK)
    {
        return ret;
    }

    /* Configure Wi-Fi credentials */
    wifi_config_t wifi_config = {0};

    memcpy(
        wifi_config.sta.ssid,
        ssid,
        strlen(ssid)
    );

    memcpy(
        wifi_config.sta.password,
        password,
        strlen(password)
    );

    /* Configure station mode */
    ret = esp_wifi_set_mode(WIFI_MODE_STA);

    if (ret != ESP_OK)
    {
        return ret;
    }

    ret = esp_wifi_set_storage(WIFI_STORAGE_RAM);

    if (ret != ESP_OK)
    {
        return ret;
    }

    ret = esp_wifi_set_config(
        WIFI_IF_STA,
        &wifi_config
    );

    if (ret != ESP_OK)
    {
        return ret;
    }

    /* Start Wi-Fi */
    ret = esp_wifi_start();

    if (ret != ESP_OK)
    {
        return ret;
    }

    wifi_initialized = true;

    ESP_LOGI(TAG, "Wi-Fi Manager initialized successfully");

    return ESP_OK;
}


/* Get current Wi-Fi status */
esp_err_t wifi_manager_get_status(
    wifi_status_t *status)
{
    if (status == NULL)
    {
        return ESP_ERR_INVALID_ARG;
    }

    memset(status, 0, sizeof(wifi_status_t));

    status->connected = wifi_connected;
    status->reconnect_count = reconnect_count;

    if (wifi_connected)
    {
        wifi_ap_record_t ap_info;

        esp_err_t ret = esp_wifi_sta_get_ap_info(&ap_info);

        if (ret == ESP_OK)
        {
            status->rssi = ap_info.rssi;

            memcpy(
                status->ssid,
                ap_info.ssid,
                sizeof(status->ssid) - 1
            );

            status->ssid[sizeof(status->ssid) - 1] = '\0';
        }
        else
        {
            status->connected = false;
        }
    }

    return ESP_OK;
}