from data_loader import fetch_telemetry
from preprocessing import prepare_features
from anomaly_detector import DeviceAnomalyDetector


def main():

    # Step 1: Fetch latest telemetry
    print("\nFetching ESP32 telemetry...")

    df = fetch_telemetry("ESP32_001")

    if df.empty:
        print("No telemetry records found!")
        return

    print(f"Total records fetched: {len(df)}")

    # Step 2: Prepare ML features
    print("\nPreparing ML features...")

    features = prepare_features(df)

    # Step 3: Load trained model
    print("\nLoading saved ML model...")

    detector = DeviceAnomalyDetector()
    detector.load_model()

    # Step 4: Predict anomalies
    print("\nDetecting anomalies...")

    results = detector.predict(features)

    # Step 5: Display summary
    print("\nPrediction Summary:")
    print(results["status"].value_counts())

    # Step 6: Display latest predictions
    print("\nLatest 10 Predictions:")

    print(
        results[
            [
                "free_heap",
                "minimum_free_heap",
                "wifi_rssi",
                "wifi_reconnect_count",
                "anomaly_score",
                "status"
            ]
        ].tail(10).to_string(index=False)
    )

    print("\nPrediction completed successfully!")


if __name__ == "__main__":
    main()