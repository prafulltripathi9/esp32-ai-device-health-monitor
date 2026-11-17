import pandas as pd

from anomaly_detector import DeviceAnomalyDetector
from health_rules import check_device_health


class HybridDeviceDetector:

    def __init__(self):
        self.ml_detector = DeviceAnomalyDetector()
        self.ml_detector.load_model()

    def predict(self, telemetry, features):

        if telemetry is None or telemetry.empty:
            raise ValueError("Telemetry data cannot be empty.")

        if features is None or features.empty:
            raise ValueError("ML features cannot be empty.")

        if len(telemetry) != len(features):
            raise ValueError(
                "Telemetry and feature row counts do not match."
            )

        # Machine Learning predictions
        ml_results = self.ml_detector.predict(features)

        if ml_results is None or len(ml_results) != len(telemetry):
            raise ValueError("Invalid ML prediction results.")

        required_ml_columns = ["anomaly_score", "status"]

        for column in required_ml_columns:
            if column not in ml_results.columns:
                raise ValueError(
                    f"Missing ML prediction column: {column}"
                )

        # Rule-based health predictions
        rule_results = check_device_health(telemetry)

        if rule_results is None or len(rule_results) != len(telemetry):
            raise ValueError("Invalid health rule results.")

        required_rule_columns = ["health_status", "issues"]

        for column in required_rule_columns:
            if column not in rule_results.columns:
                raise ValueError(
                    f"Missing health rule column: {column}"
                )

        # Combine results
        results = telemetry.copy()

        results["anomaly_score"] = ml_results[
            "anomaly_score"
        ].values

        results["ml_status"] = ml_results[
            "status"
        ].values

        results["health_status"] = rule_results[
            "health_status"
        ].values

        results["health_issues"] = rule_results[
            "issues"
        ].values

        # Determine final hybrid health status
        def determine_status(row):

            if row["health_status"] == "Critical":
                return "Critical"

            if row["health_status"] == "Warning":
                return "Warning"

            if row["ml_status"] == "Anomaly":
                return "Unusual Behaviour"

            return "Healthy"

        results["final_status"] = results.apply(
            determine_status,
            axis=1,
        )

        return results