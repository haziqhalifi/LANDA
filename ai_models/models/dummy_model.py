"""Dummy placeholder model for disaster risk prediction."""

import numpy as np


class DummyModel:
    """A placeholder ML model that returns random risk scores.

    Replace this with a real trained model (e.g. scikit-learn, PyTorch)
    once training data is available.
    """

    def __init__(self):
        self.model_name = "DummyRiskModel"
        self.version = "0.1.0"

    def predict(self, features: np.ndarray) -> np.ndarray:
        """Return a random risk score between 0 and 1 for each input sample.

        Args:
            features: A 2-D numpy array of shape (n_samples, n_features).

        Returns:
            A 1-D numpy array of predicted risk scores in [0, 1].
        """
        n_samples = features.shape[0]
        return np.random.default_rng().random(n_samples)
