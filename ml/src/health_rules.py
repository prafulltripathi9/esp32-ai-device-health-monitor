import pandas as pd


def check_device_health(telemetry: pd.DataFrame):

    results = []

    for _, row in telemetry.iterrows():

        issues = []

        # Memory health check
        if row["free_heap"] < 20000:
            issues.append("Critical: Very low free heap")

        elif row["free_heap"] < 40000:
            issues.append("Warning: Low free heap")

        # Wi-Fi signal check
        if row["wifi_rssi"] < -85:
            issues.append("Critical: Very weak Wi-Fi signal")

        elif row["wifi_rssi"] < -70:
            issues.append("Warning: Weak Wi-Fi signal")

        # Wi-Fi reconnection check
        if row["wifi_reconnect_count"] >= 5:
            issues.append("Warning: Excessive Wi-Fi reconnections")

        # Final health status
        if any(issue.startswith("Critical") for issue in issues):
            status = "Critical"

        elif issues:
            status = "Warning"

        else:
            status = "Healthy"

        results.append({
            "health_status": status,
            "issues": issues
        })

    return pd.DataFrame(results, index=telemetry.index)