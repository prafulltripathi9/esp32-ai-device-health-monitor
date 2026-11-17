import logging

from data_loader import fetch_telemetry
from preprocessing import prepare_features
from anomaly_detector import DeviceAnomalyDetector


logger = logging.getLogger(__name__)

DEVICE_ID = "ESP32_001"
TRAIN_RATIO = 0.80
MINIMUM_RECORDS = 10


def main():

    # Step 1: Fetch ESP32 telemetry
    print("\nFetching ESP32 telemetry...")

    df = fetch_telemetry(DEVICE_ID)

    if df.empty:
        raise ValueError("No telemetry records found!")

    print(f"Total telemetry records: {len(df)}")

    # Step 2: Prepare ML features
    print("\nPreparing ML features...")

    features = prepare_features(df)

    if len(features) < MINIMUM_RECORDS:
        raise ValueError(
            f"At least {MINIMUM_RECORDS} records are required "
            "for training and testing."
        )

    print(f"Total ML features: {features.shape[1]}")
    print(f"Feature columns: {features.columns.tolist()}")

    # Step 3: Chronological 80:20 split
    split_index = int(len(features) * TRAIN_RATIO)

    train_features = features.iloc[:split_index].copy()
    test_features = features.iloc[split_index:].copy()

    if train_features.empty or test_features.empty:
        raise ValueError(
            "Training or testing dataset is empty."
        )

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

    if results.empty:
        raise ValueError("Model returned empty test predictions.")

    print("\n========== TEST RESULTS ==========")

    print(results["status"].value_counts())

    # Calculate detected anomaly percentage
    anomaly_count = (results["anomaly"] == -1).sum()

    anomaly_percentage = (
        anomaly_count / len(results)
    ) * 100

    print("\n========== ANOMALY SUMMARY ==========")

    print(f"Total test records: {len(results)}")
    print(f"Detected anomalies: {anomaly_count}")
    print(f"Detected normal records: {len(results) - anomaly_count}")
    print(f"Anomaly percentage: {anomaly_percentage:.2f}%")

    print("\nLatest 10 Predictions:")

    display_columns = [
        "free_heap",
        "minimum_free_heap",
        "wifi_rssi",
        "wifi_reconnect_count",
        "anomaly_score",
        "status",
    ]

    print(
        results[display_columns]
        .tail(10)
        .to_string(index=False)
    )

    print("\nML training and testing completed successfully!")


if __name__ == "__main__":
    main()