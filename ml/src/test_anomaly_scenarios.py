import pandas as pd

from anomaly_detector import DeviceAnomalyDetector


def main():

    print("\nLoading trained ML model...")

    detector = DeviceAnomalyDetector()
    detector.load_model()

    scenarios = pd.DataFrame([
        {
            "free_heap": 224200,
            "minimum_free_heap": 216000,
            "wifi_rssi": -50,
            "wifi_reconnect_count": 0,
            "uptime_seconds": 1500
        },
        {
            "free_heap": 10000,
            "minimum_free_heap": 5000,
            "wifi_rssi": -50,
            "wifi_reconnect_count": 0,
            "uptime_seconds": 1500
        },
        {
            "free_heap": 224200,
            "minimum_free_heap": 216000,
            "wifi_rssi": -95,
            "wifi_reconnect_count": 10,
            "uptime_seconds": 1500
        },
        {
            "free_heap": 5000,
            "minimum_free_heap": 2000,
            "wifi_rssi": -95,
            "wifi_reconnect_count": 15,
            "uptime_seconds": 10
        }
    ])

    scenario_names = [
        "Normal Device",
        "Low Memory",
        "Poor Wi-Fi",
        "Combined Fault Scenario"
    ]

    print("\nTesting Synthetic Scenarios...")

    results = detector.predict(scenarios)

    results.insert(0, "scenario", scenario_names)

    print("\n========== SCENARIO TEST RESULTS ==========")

    print(
        results[
            [
                "scenario",
                "anomaly_score",
                "status"
            ]
        ].to_string(index=False)
    )


if __name__ == "__main__":
    main()