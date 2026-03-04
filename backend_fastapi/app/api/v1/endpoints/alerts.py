"""Alert-related API endpoints."""

from fastapi import APIRouter

from app.schemas.alert import PredictRequest, PredictResponse, PingResponse

# NOTE: To import ai_models, either:
#   1) pip install -e ../ai_models   (editable install), or
#   2) set PYTHONPATH to include the repo root:
#      export PYTHONPATH="${PYTHONPATH}:$(pwd)/.."
from ai_models import predict_risk

router = APIRouter()


@router.get("/ping", response_model=PingResponse)
async def ping():
    """Simple liveness probe for the alerts service."""
    return PingResponse(message="pong", service="alerts")


@router.post("/predict", response_model=PredictResponse)
async def predict(request: PredictRequest):
    """Run a disaster-risk prediction using the AI model.

    Accepts a list of numeric features and returns a risk score.
    """
    result = predict_risk({"features": request.features})
    return PredictResponse(
        risk_score=result["risk_score"],
        model=result["model"],
        model_version=result["model_version"],
    )
