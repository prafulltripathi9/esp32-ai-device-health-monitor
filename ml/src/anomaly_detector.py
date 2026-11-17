import logging
import math
import joblib
import pandas as pd

from pathlib import Path
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
from sklearn.utils.validation import check_is_fitted


logger = logging.getLogger(__name__)


class DeviceAnomalyDetector:

    def __init__(self):

        self.model_dir = Path(__file__).resolve().parent.parent / "models"

        self.model_path = self.model_dir / "isolation_forest.pkl"
        self.scaler_path = self.model_dir / "scaler.pkl"

        self.scaler = StandardScaler()

        self.model = IsolationForest(
            n_estimators=100,
            contamination=0.02,
            random_state=42,
        )

        self.is_trained = False

        self.feature_columns = None

    # Validate input features
    def _validate_features(self, features: pd.DataFrame):

        if not isinstance(features, pd.DataFrame):
            raise TypeError("Features must be a pandas DataFrame.")

        if features.empty:
            raise ValueError("Feature dataset is empty.")

        if features.columns.empty:
            raise ValueError("No feature columns provided.")

        if not features.columns.is_unique:
            raise ValueError("Duplicate feature columns found.")

        if features.isnull().any().any():
            raise ValueError("Feature dataset contains missing values.")

        if not all(
            pd.api.types.is_numeric_dtype(dtype)
            for dtype in features.dtypes
        ):
            raise ValueError("All ML features must be numeric.")

        if not features.map(
            lambda value: math.isfinite(float(value))
        ).all().all():
            raise ValueError("Feature dataset contains invalid values.")

    # Train model using training data
    def train(self, features: pd.DataFrame):

        self._validate_features(features)

        if len(features) < 2:
            raise ValueError(
                "At least two training records are required."
            )

        self.feature_columns = list(features.columns)

        # Fit scaler only on training data
        scaled_features = self.scaler.fit_transform(features)

        # Train Isolation Forest
        self.model.fit(scaled_features)

        self.is_trained = True

        logger.info("Isolation Forest model trained successfully.")

        self.save_model()

    # Save model and scaler
    def save_model(self):

        if not self.is_trained:
            raise RuntimeError(
                "Model must be trained before saving."
            )

        self.model_dir.mkdir(
            parents=True,
            exist_ok=True,
        )

        joblib.dump(self.model, self.model_path)
        joblib.dump(self.scaler, self.scaler_path)

        logger.info("ML model and scaler saved successfully.")

    # Load trained model
    def load_model(self):

        if not self.model_path.exists():
            raise FileNotFoundError(
                f"Trained ML model not found: {self.model_path}"
            )

        if not self.scaler_path.exists():
            raise FileNotFoundError(
                f"Trained scaler not found: {self.scaler_path}"
            )

        try:
            model = joblib.load(self.model_path)
            scaler = joblib.load(self.scaler_path)

            check_is_fitted(model)
            check_is_fitted(scaler)

            if not hasattr(model, "n_features_in_"):
                raise ValueError("Loaded model has no feature information.")

            if not hasattr(scaler, "n_features_in_"):
                raise ValueError("Loaded scaler has no feature information.")

            if model.n_features_in_ != scaler.n_features_in_:
                raise ValueError(
                    "Model and scaler feature counts do not match."
                )

            self.model = model
            self.scaler = scaler

            self.feature_columns = getattr(
                scaler,
                "feature_names_in_",
                None,
            )

            self.is_trained = True

            logger.info("ML model and scaler loaded successfully.")

        except Exception:
            self.is_trained = False
            logger.exception("Failed to load ML model or scaler.")
            raise

    # Predict anomalies
    def predict(self, features: pd.DataFrame):

        if not self.is_trained:
            raise RuntimeError(
                "Train or load the model before prediction."
            )

        self._validate_features(features)

        # Verify feature count and order
        if self.feature_columns is not None:
            if list(features.columns) != list(self.feature_columns):
                raise ValueError(
                    "Prediction features do not match training features."
                )

        elif features.shape[1] != self.scaler.n_features_in_:
            raise ValueError(
                "Prediction feature count does not match training data."
            )

        # Use previously fitted scaler
        scaled_features = self.scaler.transform(features)

        # Predict anomalies
        predictions = self.model.predict(scaled_features)

        scores = self.model.decision_function(scaled_features)

        if not all(math.isfinite(float(score)) for score in scores):
            raise ValueError("Model returned invalid anomaly scores.")

        results = features.copy()

        results["anomaly"] = predictions

        results["anomaly_score"] = scores

        results["status"] = results["anomaly"].map({
            1: "Normal",
            -1: "Anomaly",
        })

        if results["status"].isnull().any():
            raise ValueError("Model returned unknown prediction labels.")

        return results