"""Disaster Resilience AI — FastAPI Backend.

Run with:
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
"""

from contextlib import asynccontextmanager

import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.v1.endpoints import alerts, auth, devices, family, preparedness, profile, reports, risk_map, warnings
from app.api.v1.endpoints import admin, sms
from app.scheduler import start_scheduler, stop_scheduler


@asynccontextmanager
async def lifespan(app: FastAPI):
    start_scheduler()
    yield
    stop_scheduler()


app = FastAPI(
    title="Disaster Resilience AI API",
    version="2.0.0",
    description="REST API for disaster alerts, community reports, personal preparedness, and family safety.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*", "null"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routes ──────────────────────────────────────────────────────────────────

app.include_router(alerts.router,        prefix="/api/v1/alerts",        tags=["alerts"])
app.include_router(auth.router,          prefix="/api/v1/auth",           tags=["auth"])
app.include_router(warnings.router,      prefix="/api/v1/warnings",       tags=["warnings"])
app.include_router(devices.router,       prefix="/api/v1/devices",        tags=["devices"])
app.include_router(risk_map.router,      prefix="/api/v1/risk-map",       tags=["risk-map"])
app.include_router(profile.router,       prefix="/api/v1/profile",        tags=["profile"])
app.include_router(reports.router,       prefix="/api/v1/reports",        tags=["reports"])
app.include_router(preparedness.router,  prefix="/api/v1/preparedness",   tags=["preparedness"])
app.include_router(family.router,        prefix="/api/v1/family",         tags=["family"])
app.include_router(admin.router,         prefix="/api/v1/admin",          tags=["admin"])
app.include_router(sms.router,           prefix="/api/v1/sms",            tags=["sms"])

# ── Admin static site (served from /admin-ui — same origin, no CORS issues) ──
_admin_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "admin_website"))
if os.path.isdir(_admin_dir):
    app.mount("/admin-ui", StaticFiles(directory=_admin_dir, html=True), name="admin-ui")


@app.get("/", tags=["health"])
async def health_check():
    return {"status": "ok", "service": "disaster-resilience-ai-backend", "version": "2.0.0"}
