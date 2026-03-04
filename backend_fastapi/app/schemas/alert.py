"""Pydantic schemas for alert endpoints."""

from pydantic import BaseModel, Field


class PingResponse(BaseModel):
    message: str = "pong"
    service: str = "alerts"


class PredictRequest(BaseModel):
    """Request body for the /alerts/predict endpoint."""

    features: list[float] = Field(
        ...,
        min_length=1,
        description="List of numeric feature values for the prediction model.",
        examples=[[0.5, 1.2, 3.4, 0.8]],
    )


class PredictResponse(BaseModel):
    """Response body for the /alerts/predict endpoint."""

    risk_score: float = Field(
        ..., ge=0.0, le=1.0, description="Predicted risk score between 0 and 1."
    )
    model: str = Field(..., description="Name of the model used.")
    model_version: str = Field(..., description="Version of the model used.")
