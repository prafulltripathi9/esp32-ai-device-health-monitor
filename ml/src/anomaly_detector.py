import pandas as pd
import joblib

from pathlib import Path
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
from sklearn.utils.validation import check_is_fitted


class DeviceAnomalyDetector:

    def __init__(self):

        # Get ML project directory
        self.model_dir = Path(__file__).resolve().parent.parent / "models"

        # Model file paths
        self.model_path = self.model_dir / "isolation_forest.pkl"
        self.scaler_path = self.model_dir / "scaler.pkl"

        # Initialize StandardScaler
        self.scaler = StandardScaler()

        # Initialize Isolation Forest
        self.model = IsolationForest(
            n_estimators=100,
            contamination=0.02,
            random_state=42
        )

        self.is_trained = False

    # Train ML model
    def train(self, features: pd.DataFrame):

        if features.empty:
            raise ValueError("Training dataset is empty!")

        # Scale input features
        scaled_features = self.scaler.fit_transform(features)

        # Train Isolation Forest
        self.model.fit(scaled_features)

        self.is_trained = True

        print("Isolation Forest model trained successfully!")

        # Automatically save model
        self.save_model()

    # Save trained model and scaler
    def save_model(self):

        if not self.is_trained:
            raise RuntimeError("Model must be trained before saving!")

        # Create models directory if it does not exist
        self.model_dir.mkdir(parents=True, exist_ok=True)

        # Save Isolation Forest model
        joblib.dump(self.model, self.model_path)

        # Save StandardScaler
        joblib.dump(self.scaler, self.scaler_path)

        print("\nML model saved successfully!")
        print(f"Model: {self.model_path}")
        print(f"Scaler: {self.scaler_path}")

    # Load previously trained model
    def load_model(self):

        if not self.model_path.exists():
            raise FileNotFoundError("Trained ML model not found!")

        if not self.scaler_path.exists():
            raise FileNotFoundError("Trained scaler not found!")

        # Load saved objects
        self.model = joblib.load(self.model_path)
        self.scaler = joblib.load(self.scaler_path)

        # Verify loaded objects
        check_is_fitted(self.model)
        check_is_fitted(self.scaler)

        self.is_trained = True

        print("ML model and scaler loaded successfully!")

    # Detect anomalies
    def predict(self, features: pd.DataFrame):

        if not self.is_trained:
            raise RuntimeError("Train or load the model before prediction!")

        # Apply previously fitted scaler
        scaled_features = self.scaler.transform(features)

        # Predict anomalies
        predictions = self.model.predict(scaled_features)

        # Calculate anomaly scores
        scores = self.model.decision_function(scaled_features)

        # Prepare results
        results = features.copy()

        results["anomaly"] = predictions
        results["anomaly_score"] = scores

        results["status"] = results["anomaly"].map({
            1: "Normal",
            -1: "Anomaly"
        })

        return results