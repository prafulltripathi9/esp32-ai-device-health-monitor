from data_loader import fetch_telemetry
from preprocessing import prepare_features
from anomaly_detector import DeviceAnomalyDetector


def main():

    # Step 1: Fetch telemetry
    print("\nFetching ESP32 telemetry...")

    df = fetch_telemetry("ESP32_001")

    if df.empty:
        print("No telemetry records found!")
        return

    print(f"Total records: {len(df)}")

    # Step 2: Prepare ML features
    print("\nPreparing ML features...")

    features = prepare_features(df)

    print(f"Total ML features: {features.shape[1]}")

    # Step 3: Train model
    print("\nTraining Isolation Forest...")

    detector = DeviceAnomalyDetector()

    detector.train(features)

    # Model and scaler are automatically saved by train()

    # Step 4: Make predictions
    print("\nDetecting anomalies...")

    results = detector.predict(features)

    print("\nDetection Summary:")
    print(results["status"].value_counts())

    print("\nLatest 10 Predictions:")

    print(
        results[
            [
                "free_heap",
                "wifi_rssi",
                "wifi_reconnect_count",
                "anomaly_score",
                "status"
            ]
        ].tail(10).to_string(index=False)
    )

    # Step 5: Test saved model loading
    print("\nTesting saved model loading...")

    loaded_detector = DeviceAnomalyDetector()

    loaded_detector.load_model()

    # Predict using loaded model
    loaded_results = loaded_detector.predict(features.tail(10))

    print("\nPredictions using loaded model:")

    print(
        loaded_results[
            ["free_heap", "wifi_rssi", "anomaly_score", "status"]
        ].to_string(index=False)
    )

    print("\nML training and model loading completed successfully!")


if __name__ == "__main__":
    main()