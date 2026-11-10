from anomaly_detector import DeviceAnomalyDetector
from health_rules import check_device_health


class HybridDeviceDetector:

    def __init__(self):
        self.ml_detector = DeviceAnomalyDetector()
        self.ml_detector.load_model()

    def predict(self, telemetry, features):

        # Machine Learning predictions
        ml_results = self.ml_detector.predict(features)

        # Rule-based health predictions
        rule_results = check_device_health(telemetry)

        # Combine both results
        results = telemetry.copy()

        results["anomaly_score"] = ml_results["anomaly_score"].values

        results["ml_status"] = ml_results["status"].values

        results["health_status"] = rule_results["health_status"].values

        results["health_issues"] = rule_results["issues"].values

        # Final hybrid status
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
            axis=1
        )

        return results