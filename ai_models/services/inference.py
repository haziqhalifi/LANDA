"""High-level inference service that wraps ML models."""

from __future__ import annotations

import numpy as np

from ai_models.models.dummy_model import DummyModel

# Singleton model instance (lazy-loaded)
_model: DummyModel | None = None


def _get_model() -> DummyModel:
    global _model
    if _model is None:
        _model = DummyModel()
    return _model


def predict_risk(input_data: dict) -> dict:
    """Run a risk prediction using the current model.

    Args:
        input_data: A dict with a key ``"features"`` containing a list of
            numeric feature values, e.g.::

                {"features": [0.5, 1.2, 3.4]}

    Returns:
        A dict with ``"risk_score"`` (float) and ``"model"`` metadata.
    """
    model = _get_model()

    features = np.array(input_data.get("features", [0.0])).reshape(1, -1)
    prediction = model.predict(features)

    return {
        "risk_score": float(prediction[0]),
        "model": model.model_name,
        "model_version": model.version,
    }
