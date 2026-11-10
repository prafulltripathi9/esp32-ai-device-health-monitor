import pandas as pd

from data_loader import fetch_telemetry
from preprocessing import prepare_features
from anomaly_detector import DeviceAnomalyDetector


def main():

    print("\nFetching ESP32 telemetry...")

    df = fetch_telemetry("ESP32_001")

    if df.empty:
        print("No telemetry records found!")
        return

    print(f"Total records: {len(df)}")

    print("\nPreparing ML features...")

    features = prepare_features(df)

    print("\nLoading trained ML model...")

    detector = DeviceAnomalyDetector()
    detector.load_model()

    print("\nEvaluating model...")

    results = detector.predict(features)

    # Prediction distribution
    print("\n========== MODEL EVALUATION ==========")

    print("\nPrediction Distribution:")

    distribution = results["status"].value_counts()

    print(distribution)

    # Anomaly percentage
    anomaly_count = (results["anomaly"] == -1).sum()

    anomaly_percentage = (anomaly_count / len(results)) * 100

    print(f"\nAnomaly Count: {anomaly_count}")
    print(f"Anomaly Percentage: {anomaly_percentage:.2f}%")

    # Anomaly score statistics
    print("\nAnomaly Score Statistics:")

    print(results["anomaly_score"].describe())

    # Display detected anomalies
    print("\nLatest Detected Anomalies:")

    anomalies = results[results["status"] == "Anomaly"]

    print(
        anomalies[
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

    print("\nModel evaluation completed!")


if __name__ == "__main__":
    main()