from data_loader import fetch_telemetry
from preprocessing import prepare_features
from hybrid_detector import HybridDeviceDetector


DEVICE_ID = "ESP32_001"


def main():

    # Step 1: Fetch telemetry
    print("\nFetching ESP32 telemetry...")

    telemetry = fetch_telemetry(DEVICE_ID)

    if telemetry.empty:
        raise ValueError("No telemetry records found!")

    print(f"Total records: {len(telemetry)}")

    # Step 2: Prepare ML features
    print("\nPreparing ML features...")

    features = prepare_features(telemetry)

    if len(telemetry) != len(features):
        raise ValueError(
            "Telemetry and feature counts do not match."
        )

    # Step 3: Initialize Hybrid Detection Engine
    print("\nInitializing Hybrid Detection Engine...")

    detector = HybridDeviceDetector()

    # Step 4: Run Hybrid Detection
    print("\nRunning Hybrid Health Detection...")

    results = detector.predict(telemetry, features)

    if results.empty:
        raise ValueError("Hybrid detector returned empty results.")

    # Validate output columns
    required_columns = [
        "anomaly_score",
        "ml_status",
        "health_status",
        "health_issues",
        "final_status",
    ]

    missing_columns = [
        column
        for column in required_columns
        if column not in results.columns
    ]

    if missing_columns:
        raise ValueError(
            f"Missing hybrid result columns: {missing_columns}"
        )

    if results[required_columns].isnull().any().any():
        raise ValueError(
            "Hybrid detection returned missing values."
        )

    # Step 5: Display summaries
    print("\n========== HYBRID DETECTION SUMMARY ==========")

    print("\nFinal Health Status:")
    print(results["final_status"].value_counts())

    print("\nML Detection Summary:")
    print(results["ml_status"].value_counts())

    print("\nRule-Based Health Summary:")
    print(results["health_status"].value_counts())

    # Step 6: Display latest results
    print("\nLatest 10 Device Health Results:")

    columns = [
        "free_heap",
        "wifi_rssi",
        "wifi_reconnect_count",
        "anomaly_score",
        "ml_status",
        "health_status",
        "final_status",
    ]

    print(
        results[columns]
        .tail(10)
        .to_string(index=False)
    )

    print("\n========== HYBRID DETECTION COMPLETED ==========")

    print(f"Total analyzed records: {len(results)}")

    print("\nHybrid Detection Completed Successfully!")


if __name__ == "__main__":
    main()