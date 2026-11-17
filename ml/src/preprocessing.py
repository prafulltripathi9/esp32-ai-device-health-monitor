import pandas as pd


# Features used by both model training and backend prediction
REQUIRED_FEATURES = [
    "free_heap",
    "minimum_free_heap",
    "wifi_rssi",
    "wifi_reconnect_count",
    "uptime_seconds",
]


def inspect_telemetry(df: pd.DataFrame):

    if not isinstance(df, pd.DataFrame):
        raise TypeError("Input must be a pandas DataFrame.")

    print("\n========== DATASET INFORMATION ==========")

    print(f"Total Records: {len(df)}")

    print("\nDataset Columns:")
    print(df.columns.tolist())

    print("\nMissing Values:")
    print(df.isnull().sum())

    print("\nDuplicate Records:")
    print(df.duplicated().sum())

    if df.empty:
        print("\nDataset is empty. Statistical summary unavailable.")
        return df

    print("\nStatistical Summary:")
    print(df.describe())

    return df


def prepare_features(df: pd.DataFrame):

    if not isinstance(df, pd.DataFrame):
        raise TypeError("Input must be a pandas DataFrame.")

    if df.empty:
        raise ValueError("Cannot prepare features from an empty dataset.")

    # Check required columns
    missing_columns = [
        column
        for column in REQUIRED_FEATURES
        if column not in df.columns
    ]

    if missing_columns:
        raise ValueError(
            f"Missing required features: {missing_columns}"
        )

    # Select only required ML features
    features = df[REQUIRED_FEATURES].copy()

    # Validate numeric values
    for column in REQUIRED_FEATURES:

        features[column] = pd.to_numeric(
            features[column],
            errors="coerce",
        )

    # Check missing values
    if features.isnull().any().any():
        raise ValueError(
            "Feature dataset contains missing or non-numeric values."
        )

    # Check infinite values
    if not features.map(
        lambda value: abs(float(value)) != float("inf")
    ).all().all():
        raise ValueError(
            "Feature dataset contains infinite values."
        )

    return features