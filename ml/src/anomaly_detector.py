import pandas as pd
import joblib

from pathlib import Path
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
from sklearn.utils.validation import check_is_fitted


class DeviceAnomalyDetector:

    def __init__(self):

        self.model_dir = Path(__file__).resolve().parent.parent / "models"

        self.model_path = self.model_dir / "isolation_forest.pkl"
        self.scaler_path = self.model_dir / "scaler.pkl"

        self.scaler = StandardScaler()

        self.model = IsolationForest(
            n_estimators=100,
            contamination=0.02,
            random_state=42
        )

        self.is_trained = False

    # Train model using training data
    def train(self, features: pd.DataFrame):

        if features.empty:
            raise ValueError("Training dataset is empty!")

        if len(features) < 2:
            raise ValueError("At least two training records are required!")

        # Fit scaler only on training data
        scaled_features = self.scaler.fit_transform(features)

        # Train Isolation Forest
        self.model.fit(scaled_features)

        self.is_trained = True

        print("Isolation Forest model trained successfully!")

        self.save_model()

    # Save model and scaler
    def save_model(self):

        if not self.is_trained:
            raise RuntimeError("Model must be trained before saving!")

        self.model_dir.mkdir(parents=True, exist_ok=True)

        joblib.dump(self.model, self.model_path)
        joblib.dump(self.scaler, self.scaler_path)

        print("\nML model saved successfully!")

    # Load trained model
    def load_model(self):

        if not self.model_path.exists():
            raise FileNotFoundError("Trained ML model not found!")

        if not self.scaler_path.exists():
            raise FileNotFoundError("Trained scaler not found!")

        self.model = joblib.load(self.model_path)
        self.scaler = joblib.load(self.scaler_path)

        check_is_fitted(self.model)
        check_is_fitted(self.scaler)

        self.is_trained = True

        print("ML model and scaler loaded successfully!")

    # Predict anomalies
    def predict(self, features: pd.DataFrame):

        if not self.is_trained:
            raise RuntimeError("Train or load the model before prediction!")

        if features.empty:
            raise ValueError("Prediction dataset is empty!")

        # Use previously fitted scaler
        scaled_features = self.scaler.transform(features)

        predictions = self.model.predict(scaled_features)

        scores = self.model.decision_function(scaled_features)

        results = features.copy()

        results["anomaly"] = predictions
        results["anomaly_score"] = scores

        results["status"] = results["anomaly"].map({
            1: "Normal",
            -1: "Anomaly"
        })

        return results