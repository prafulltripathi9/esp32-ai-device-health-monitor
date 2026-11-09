#include <string.h>

#include "wifi_manager.h"

#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_netif.h"
#include "esp_log.h"
#include "nvs_flash.h"

static const char *TAG = "WIFI_MANAGER";

static bool wifi_connected = false;
static uint32_t reconnect_count = 0;

// Handle Wi-Fi and IP events
static void wifi_event_handler(
    void *arg,
    esp_event_base_t event_base,
    int32_t event_id,
    void *event_data)
{
    if (event_base == WIFI_EVENT &&
        event_id == WIFI_EVENT_STA_START)
    {
        ESP_LOGI(TAG, "Connecting to Wi-Fi...");
        esp_wifi_connect();
    }

    else if (event_base == WIFI_EVENT &&
             event_id == WIFI_EVENT_STA_DISCONNECTED)
    {
        wifi_connected = false;
        reconnect_count++;

        ESP_LOGW(TAG, "Wi-Fi disconnected. Reconnecting...");
        esp_wifi_connect();
    }

    else if (event_base == IP_EVENT &&
             event_id == IP_EVENT_STA_GOT_IP)
    {
        wifi_connected = true;

        ip_event_got_ip_t *event =
            (ip_event_got_ip_t *)event_data;

        ESP_LOGI(TAG, "Wi-Fi connected successfully");
        ESP_LOGI(TAG, "IP Address: " IPSTR,
                 IP2STR(&event->ip_info.ip));
    }
}


// Initialize Wi-Fi
esp_err_t wifi_manager_init(
    const char *ssid,
    const char *password)
{
    if (ssid == NULL || password == NULL ||
        strlen(ssid) == 0 ||
        strlen(ssid) > 32 ||
        strlen(password) >= 64)
    {
        return ESP_ERR_INVALID_ARG;
    }

    // Initialize NVS
    esp_err_t ret = nvs_flash_init();

    if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
        ret == ESP_ERR_NVS_NEW_VERSION_FOUND)
    {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }

    if (ret != ESP_OK)
        return ret;

    // Initialize network interface
    ESP_ERROR_CHECK(esp_netif_init());

    ESP_ERROR_CHECK(esp_event_loop_create_default());

    esp_netif_create_default_wifi_sta();

    // Initialize Wi-Fi driver
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();

    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(
        esp_event_handler_register(
            WIFI_EVENT,
            ESP_EVENT_ANY_ID,
            &wifi_event_handler,
            NULL));

    ESP_ERROR_CHECK(
        esp_event_handler_register(
            IP_EVENT,
            IP_EVENT_STA_GOT_IP,
            &wifi_event_handler,
            NULL));

    // Configure Wi-Fi credentials
    wifi_config_t wifi_config = {0};

    memcpy(wifi_config.sta.ssid, ssid, strlen(ssid));
    memcpy(wifi_config.sta.password, password, strlen(password));

    // Set station mode
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));

    ESP_ERROR_CHECK(
        esp_wifi_set_storage(WIFI_STORAGE_RAM));

    ESP_ERROR_CHECK(
        esp_wifi_set_config(
            WIFI_IF_STA,
            &wifi_config));

    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "Wi-Fi Manager initialized");

    return ESP_OK;
}


// Get current Wi-Fi status
esp_err_t wifi_manager_get_status(wifi_status_t *status)
{
    if (status == NULL)
        return ESP_ERR_INVALID_ARG;

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

            memcpy(status->ssid,
                   ap_info.ssid,
                   sizeof(status->ssid) - 1);
        }
    }

    return ESP_OK;
}