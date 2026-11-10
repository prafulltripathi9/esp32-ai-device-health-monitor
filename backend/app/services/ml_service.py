import sys
from pathlib import Path

import pandas as pd

# Project root directory
PROJECT_ROOT = Path(__file__).resolve().parents[3]

# ML source directory
ML_SOURCE = PROJECT_ROOT / "ml" / "src"

# Add ML source to Python import path
sys.path.insert(0, str(ML_SOURCE))

from hybrid_detector import HybridDeviceDetector


class MLHealthService:

    def __init__(self):
        self.detector = HybridDeviceDetector()

    def analyze_device(self, telemetry):

        # Convert database telemetry into DataFrame
        telemetry_df = pd.DataFrame([{
            "free_heap": telemetry.free_heap,
            "minimum_free_heap": telemetry.minimum_free_heap,
            "largest_free_block": telemetry.largest_free_block,
            "wifi_rssi": telemetry.wifi_rssi,
            "wifi_reconnect_count": telemetry.wifi_reconnect_count,
            "uptime_seconds": telemetry.uptime_seconds,
            "wifi_connected": telemetry.wifi_connected
        }])

        # Prepare ML features
        features = telemetry_df[
            [
                "free_heap",
                "minimum_free_heap",
                "wifi_rssi",
                "wifi_reconnect_count",
                "uptime_seconds"
            ]
        ]

        # Run hybrid detection
        results = self.detector.predict(
            telemetry_df,
            features
        )

        result = results.iloc[0]

        return {
            "health_status": result["final_status"],
            "ml_status": result["ml_status"],
            "anomaly_score": float(result["anomaly_score"]),
            "issues": result["health_issues"]
        }


# Initialize service
ml_health_service = MLHealthService()