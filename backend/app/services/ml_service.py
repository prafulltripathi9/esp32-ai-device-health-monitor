import sys
import logging
import math
from pathlib import Path

import pandas as pd

logger = logging.getLogger(__name__)

# Project root directory
PROJECT_ROOT = Path(__file__).resolve().parents[3]

# ML source directory
ML_SOURCE = PROJECT_ROOT / "ml" / "src"

# Add ML source to Python import path
if str(ML_SOURCE) not in sys.path:
    sys.path.insert(0, str(ML_SOURCE))

from hybrid_detector import HybridDeviceDetector


class MLHealthService:

    def __init__(self):
        self.detector = None
        self._initialize_detector()

    def _initialize_detector(self):
        """Initialize the ML detector safely."""
        try:
            self.detector = HybridDeviceDetector()
            logger.info("ML detector initialized successfully.")

        except Exception:
            self.detector = None
            logger.exception("Failed to initialize ML detector.")

    def analyze_device(self, telemetry):

        if self.detector is None:
            raise RuntimeError("ML detector is not available.")

        # Convert database telemetry into DataFrame
        telemetry_df = pd.DataFrame([{
            "free_heap": telemetry.free_heap,
            "minimum_free_heap": telemetry.minimum_free_heap,
            "largest_free_block": telemetry.largest_free_block,
            "wifi_rssi": telemetry.wifi_rssi,
            "wifi_reconnect_count": telemetry.wifi_reconnect_count,
            "uptime_seconds": telemetry.uptime_seconds,
            "wifi_connected": telemetry.wifi_connected,
        }])

        # Prepare ML features
        features = telemetry_df[
            [
                "free_heap",
                "minimum_free_heap",
                "wifi_rssi",
                "wifi_reconnect_count",
                "uptime_seconds",
            ]
        ]

        try:
            # Run hybrid detection
            results = self.detector.predict(
                telemetry_df,
                features,
            )

            if results is None or results.empty:
                raise ValueError("ML detector returned empty results.")

            result = results.iloc[0]

            required_columns = [
                "final_status",
                "ml_status",
                "anomaly_score",
                "health_issues",
            ]

            missing_columns = [
                column
                for column in required_columns
                if column not in results.columns
            ]

            if missing_columns:
                raise ValueError(
                    f"Missing ML result columns: {missing_columns}"
                )

            # Validate anomaly score
            anomaly_score = float(result["anomaly_score"])

            if not math.isfinite(anomaly_score):
                raise ValueError("Invalid anomaly score returned by ML model.")

            # Normalize health issues
            issues = result["health_issues"]

            if issues is None:
                issues = []
            elif isinstance(issues, str):
                issues = [issues]
            elif not isinstance(issues, (list, tuple)):
                issues = [str(issues)]

            return {
                "health_status": str(result["final_status"]),
                "ml_status": str(result["ml_status"]),
                "anomaly_score": anomaly_score,
                "issues": list(issues),
            }

        except Exception:
            logger.exception(
                "ML prediction failed for device: %s",
                getattr(telemetry, "device_id", "unknown"),
            )
            raise


# Initialize service
ml_health_service = MLHealthService()