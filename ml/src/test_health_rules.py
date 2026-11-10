import pandas as pd

from health_rules import check_device_health


def main():

    scenarios = pd.DataFrame([
        {
            "free_heap": 224200,
            "wifi_rssi": -50,
            "wifi_reconnect_count": 0
        },
        {
            "free_heap": 30000,
            "wifi_rssi": -50,
            "wifi_reconnect_count": 0
        },
        {
            "free_heap": 224200,
            "wifi_rssi": -80,
            "wifi_reconnect_count": 0
        },
        {
            "free_heap": 10000,
            "wifi_rssi": -90,
            "wifi_reconnect_count": 6
        }
    ])

    names = [
        "Normal Device",
        "Low Memory",
        "Weak Wi-Fi",
        "Combined Critical Issues"
    ]

    results = check_device_health(scenarios)

    results.insert(0, "scenario", names)

    print("\n========== RULE-BASED HEALTH TEST ==========")

    print(results.to_string(index=False))


if __name__ == "__main__":
    main()