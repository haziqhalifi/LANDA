"""Alert-related API endpoints."""

from fastapi import APIRouter

from app.schemas.alert import PingResponse

router = APIRouter()


@router.get("/ping", response_model=PingResponse)
async def ping():
    """Simple liveness probe for the alerts service."""
    return PingResponse(message="pong", service="alerts")
