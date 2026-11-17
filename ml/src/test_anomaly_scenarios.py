import pandas as pd

from anomaly_detector import DeviceAnomalyDetector


def main():

    print("\nLoading trained ML model...")

    detector = DeviceAnomalyDetector()
    detector.load_model()

    # Synthetic test scenarios
    scenarios = pd.DataFrame([
        {
            "free_heap": 224200,
            "minimum_free_heap": 216000,
            "wifi_rssi": -50,
            "wifi_reconnect_count": 0,
            "uptime_seconds": 1500,
        },
        {
            "free_heap": 10000,
            "minimum_free_heap": 5000,
            "wifi_rssi": -50,
            "wifi_reconnect_count": 0,
            "uptime_seconds": 1500,
        },
        {
            "free_heap": 224200,
            "minimum_free_heap": 216000,
            "wifi_rssi": -95,
            "wifi_reconnect_count": 10,
            "uptime_seconds": 1500,
        },
        {
            "free_heap": 5000,
            "minimum_free_heap": 2000,
            "wifi_rssi": -95,
            "wifi_reconnect_count": 15,
            "uptime_seconds": 10,
        },
    ])

    scenario_names = [
        "Normal Device",
        "Low Memory",
        "Poor Wi-Fi",
        "Combined Fault Scenario",
    ]

    print("\nTesting Synthetic Scenarios...")

    # Run predictions
    results = detector.predict(scenarios)

    # Validate prediction output
    required_columns = [
        "anomaly_score",
        "anomaly",
        "status",
    ]

    for column in required_columns:
        if column not in results.columns:
            raise ValueError(
                f"Missing prediction column: {column}"
            )

    if len(results) != len(scenarios):
        raise ValueError(
            "Prediction count does not match scenario count."
        )

    results.insert(0, "scenario", scenario_names)

    # Display results
    print("\n========== SCENARIO TEST RESULTS ==========")

    print(
        results[
            [
                "scenario",
                "anomaly_score",
                "status",
            ]
        ].to_string(index=False)
    )

    # Scenario summary
    print("\n========== TEST SUMMARY ==========")

    for _, row in results.iterrows():

        scenario = row["scenario"]
        status = row["status"]
        score = row["anomaly_score"]

        if status == "Anomaly":
            result = "ANOMALY DETECTED"
        else:
            result = "CLASSIFIED AS NORMAL"

        print(
            f"{scenario}: {result} | Score: {score:.6f}"
        )

    print("\nSynthetic scenario testing completed.")

    print(
        "Note: These results are model predictions, "
        "not verified accuracy measurements."
    )


if __name__ == "__main__":
    main()