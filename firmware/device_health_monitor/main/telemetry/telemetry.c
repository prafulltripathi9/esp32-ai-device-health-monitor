#include <stdio.h>
#include <string.h>

#include "telemetry.h"
#include "../system_config/system_config.h"
/* Escape special characters for valid JSON strings */
static esp_err_t json_escape_string(
    const char *input,
    char *output,
    size_t output_size)
{
    if (input == NULL || output == NULL || output_size == 0)
    {
        return ESP_ERR_INVALID_ARG;
    }

    size_t index = 0;

    for (size_t i = 0; input[i] != '\0'; i++)
    {
        const char *escape = NULL;
        char unicode_escape[7];

        switch (input[i])
        {
            case '"':
                escape = "\\\"";
                break;

            case '\\':
                escape = "\\\\";
                break;

            case '\n':
                escape = "\\n";
                break;

            case '\r':
                escape = "\\r";
                break;

            case '\t':
                escape = "\\t";
                break;

            default:
                if ((unsigned char)input[i] < 0x20)
                {
                    snprintf(
                        unicode_escape,
                        sizeof(unicode_escape),
                        "\\u%04x",
                        (unsigned char)input[i]
                    );

                    escape = unicode_escape;
                }
                break;
        }

        if (escape != NULL)
        {
            size_t length = strlen(escape);

            if (index + length >= output_size)
            {
                return ESP_ERR_INVALID_SIZE;
            }

            memcpy(output + index, escape, length);
            index += length;
        }
        else
        {
            if (index + 1 >= output_size)
            {
                return ESP_ERR_INVALID_SIZE;
            }

            output[index++] = input[i];
        }
    }

    output[index] = '\0';

    return ESP_OK;
}


/* Convert ESP32 reset reason into readable text */
static const char *get_reset_reason(
    esp_reset_reason_t reason)
{
    switch (reason)
    {
        case ESP_RST_POWERON:
            return "POWERON";

        case ESP_RST_SW:
            return "SOFTWARE";

        case ESP_RST_PANIC:
            return "PANIC";

        case ESP_RST_INT_WDT:
            return "INT_WDT";

        case ESP_RST_TASK_WDT:
            return "TASK_WDT";

        case ESP_RST_WDT:
            return "WDT";

        case ESP_RST_DEEPSLEEP:
            return "DEEPSLEEP";

        case ESP_RST_BROWNOUT:
            return "BROWNOUT";

        case ESP_RST_SDIO:
            return "SDIO";

        default:
            return "UNKNOWN";
    }
}


/* Generate device telemetry JSON */
esp_err_t telemetry_generate_json(
    const device_health_data_t *health_data,
    const wifi_status_t *wifi_status,
    char *json_buffer,
    size_t buffer_size)
{
    if (health_data == NULL ||
        wifi_status == NULL ||
        json_buffer == NULL ||
        buffer_size == 0)
    {
        return ESP_ERR_INVALID_ARG;
    }

    json_buffer[0] = '\0';

    char escaped_ssid[33 * 6 + 1];

    esp_err_t err = json_escape_string(
        wifi_status->ssid,
        escaped_ssid,
        sizeof(escaped_ssid)
    );

    if (err != ESP_OK)
    {
        return err;
    }

    int written = snprintf(
        json_buffer,
        buffer_size,

        "{"
        "\"device_id\":\"%s\","
        "\"uptime_seconds\":%llu,"
        "\"free_heap\":%lu,"
        "\"minimum_free_heap\":%lu,"
        "\"largest_free_block\":%lu,"
        "\"reset_reason\":\"%s\","
        "\"wifi\":{"
        "\"connected\":%s,"
        "\"ssid\":\"%s\","
        "\"rssi\":%d,"
        "\"reconnect_count\":%lu"
        "}"
        "}",

        SYSTEM_DEVICE_ID,

        (unsigned long long)health_data->uptime_seconds,
        (unsigned long)health_data->free_heap,
        (unsigned long)health_data->minimum_free_heap,
        (unsigned long)health_data->largest_free_block,

        get_reset_reason(health_data->reset_reason),

        wifi_status->connected ? "true" : "false",
        escaped_ssid,
        (int)wifi_status->rssi,
        (unsigned long)wifi_status->reconnect_count
    );

    if (written < 0 || (size_t)written >= buffer_size)
    {
        json_buffer[0] = '\0';
        return ESP_ERR_INVALID_SIZE;
    }

    return ESP_OK;
}