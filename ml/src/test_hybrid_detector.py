from data_loader import fetch_telemetry
from preprocessing import prepare_features
from hybrid_detector import HybridDeviceDetector


def main():

    print("\nFetching ESP32 telemetry...")

    telemetry = fetch_telemetry("ESP32_001")

    if telemetry.empty:
        print("No telemetry records found!")
        return

    print(f"Total records: {len(telemetry)}")

    print("\nPreparing ML features...")

    features = prepare_features(telemetry)

    print("\nInitializing Hybrid Detection Engine...")

    detector = HybridDeviceDetector()

    print("\nRunning Hybrid Health Detection...")

    results = detector.predict(telemetry, features)

    print("\n========== HYBRID DETECTION SUMMARY ==========")

    print("\nFinal Health Status:")

    print(results["final_status"].value_counts())

    print("\nML Detection Summary:")

    print(results["ml_status"].value_counts())

    print("\nRule-Based Health Summary:")

    print(results["health_status"].value_counts())

    print("\nLatest 10 Device Health Results:")

    columns = [
        "free_heap",
        "wifi_rssi",
        "wifi_reconnect_count",
        "anomaly_score",
        "ml_status",
        "health_status",
        "final_status"
    ]

    print(results[columns].tail(10).to_string(index=False))

    print("\nHybrid Detection Completed Successfully!")


if __name__ == "__main__":
    main()