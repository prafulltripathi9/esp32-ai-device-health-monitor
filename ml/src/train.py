from data_loader import fetch_telemetry
from preprocessing import prepare_features
from anomaly_detector import DeviceAnomalyDetector


def main():

    # Step 1: Fetch ESP32 telemetry
    print("\nFetching ESP32 telemetry...")

    df = fetch_telemetry("ESP32_001")

    if df.empty:
        print("No telemetry records found!")
        return

    print(f"Total telemetry records: {len(df)}")

    # Step 2: Prepare ML features
    print("\nPreparing ML features...")

    features = prepare_features(df)

    if len(features) < 10:
        raise ValueError("Insufficient data for training and testing!")

    print(f"Total ML features: {features.shape[1]}")

    # Step 3: Chronological 80:20 split
    split_index = int(len(features) * 0.80)

    train_features = features.iloc[:split_index].copy()
    test_features = features.iloc[split_index:].copy()

    print("\n========== DATASET SPLIT ==========")

    print(f"Training records: {len(train_features)}")
    print(f"Testing records: {len(test_features)}")

    # Step 4: Train model only on training data
    print("\nTraining Isolation Forest...")

    detector = DeviceAnomalyDetector()

    detector.train(train_features)

    # Step 5: Evaluate on unseen testing data
    print("\nEvaluating on unseen testing data...")

    results = detector.predict(test_features)

    print("\n========== TEST RESULTS ==========")

    print(results["status"].value_counts())

    print("\nAnomaly Percentage:")

    anomaly_percentage = (
        (results["anomaly"] == -1).sum() / len(results)
    ) * 100

    print(f"{anomaly_percentage:.2f}%")

    print("\nLatest 10 Predictions:")

    print(
        results[
            [
                "free_heap",
                "minimum_free_heap",
                "wifi_rssi",
                "wifi_reconnect_count",
                "anomaly_score",
                "status",
            ]
        ].tail(10).to_string(index=False)
    )

    print("\nML training and testing completed successfully!")


if __name__ == "__main__":
    main()
