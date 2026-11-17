from data_loader import fetch_telemetry
from preprocessing import prepare_features
from anomaly_detector import DeviceAnomalyDetector


DEVICE_ID = "ESP32_001"
TRAIN_RATIO = 0.80


def main():

    # Step 1: Fetch telemetry
    print("\nFetching ESP32 telemetry...")

    df = fetch_telemetry(DEVICE_ID)

    if df.empty:
        raise ValueError("No telemetry records found!")

    print(f"Total records: {len(df)}")

    # Step 2: Prepare ML features
    print("\nPreparing ML features...")

    features = prepare_features(df)

    if len(features) < 10:
        raise ValueError(
            "At least 10 records are required for evaluation."
        )

    # Step 3: Use chronological 20% test data
    split_index = int(len(features) * TRAIN_RATIO)

    test_features = features.iloc[split_index:].copy()

    if test_features.empty:
        raise ValueError("Testing dataset is empty.")

    print(f"Testing records: {len(test_features)}")

    # Step 4: Load trained model
    print("\nLoading trained ML model...")

    detector = DeviceAnomalyDetector()
    detector.load_model()

    # Step 5: Evaluate unseen data
    print("\nEvaluating model on unseen data...")

    results = detector.predict(test_features)

    if results.empty:
        raise ValueError("Model returned empty predictions.")

    # Prediction distribution
    print("\n========== MODEL EVALUATION ==========")

    print("\nPrediction Distribution:")

    distribution = results["status"].value_counts()

    print(distribution)

    # Anomaly percentage
    anomaly_count = (results["anomaly"] == -1).sum()

    normal_count = (results["anomaly"] == 1).sum()

    anomaly_percentage = (
        anomaly_count / len(results)
    ) * 100

    print(f"\nTotal Test Records: {len(results)}")
    print(f"Anomaly Count: {anomaly_count}")
    print(f"Normal Count: {normal_count}")
    print(f"Anomaly Percentage: {anomaly_percentage:.2f}%")

    # Anomaly score statistics
    print("\nAnomaly Score Statistics:")

    print(results["anomaly_score"].describe())

    # Display detected anomalies
    print("\nLatest Detected Anomalies:")

    anomalies = results[
        results["status"] == "Anomaly"
    ]

    if anomalies.empty:
        print("No anomalies detected in test data.")

    else:
        print(
            anomalies[
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

    print("\nModel evaluation completed!")


if __name__ == "__main__":
    main()