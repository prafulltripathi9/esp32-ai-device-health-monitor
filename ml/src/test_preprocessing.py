from data_loader import fetch_telemetry
from preprocessing import prepare_features


def main():
    print("\nFetching ESP32 telemetry...")

    df = fetch_telemetry("ESP32_001")

    if df.empty:
        print("No telemetry records found!")
        return

    features = prepare_features(df)

    print("\n========== TELEMETRY HEALTH RANGES ==========")

    columns = [
        "free_heap",
        "minimum_free_heap",
        "wifi_rssi",
        "wifi_reconnect_count",
        "uptime_seconds",
    ]

    for column in columns:
        print(f"\n{column}")
        print(f"Minimum: {features[column].min()}")
        print(f"Maximum: {features[column].max()}")
        print(f"Average: {features[column].mean():.2f}")
        print(f"Standard Deviation: {features[column].std():.2f}")

    print("\n========== FEATURE ANALYSIS ==========")

    print("\nFeature Statistics:")
    print(features.describe().to_string())

    print("\nUnique Values Per Feature:")
    print(features.nunique())

    print("\nStandard Deviation Per Feature:")
    print(features.std())

    print("\nConstant Features:")

    constant_features = [
        column
        for column in features.columns
        if features[column].nunique() <= 1
    ]

    print(constant_features)

    print("\nFeature Correlations:")
    print(features.corr().round(3).to_string())


if __name__ == "__main__":
    main()