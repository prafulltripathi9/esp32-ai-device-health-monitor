import pandas as pd


def inspect_telemetry(df: pd.DataFrame):

    print("\n========== DATASET INFORMATION ==========")

    print(f"Total Records: {len(df)}")

    print("\nDataset Columns:")
    print(df.columns.tolist())

    print("\nMissing Values:")
    print(df.isnull().sum())

    print("\nDuplicate Records:")
    print(df.duplicated().sum())

    print("\nStatistical Summary:")
    print(df.describe())

    return df

def prepare_features(df: pd.DataFrame):
    df = df.copy()

    df["wifi_connected"] = df["wifi_connected"].astype(int)

    features = [
        "free_heap",
        "minimum_free_heap",
        "wifi_rssi",
        "wifi_reconnect_count",
        "uptime_seconds"
    ]

    return df[features]