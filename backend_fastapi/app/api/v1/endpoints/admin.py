"""Admin endpoints — report moderation and statistics."""

from __future__ import annotations

import hashlib
import logging
from datetime import datetime, timezone, timedelta

import jwt
from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.core.config import ADMIN_JWT_SECRET
from app.db import admin as admin_db
from app.db import reports as report_db

logger = logging.getLogger(__name__)
router = APIRouter()
_bearer = HTTPBearer()

_ALGO = "HS256"
_EXPIRY_HOURS = 24


# ── Auth helpers ──────────────────────────────────────────────────────────────

def _hash(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()


def _make_token(username: str) -> str:
    exp = datetime.now(timezone.utc) + timedelta(hours=_EXPIRY_HOURS)
    return jwt.encode({"sub": username, "exp": exp}, ADMIN_JWT_SECRET, algorithm=_ALGO)


def _verify_token(credentials: HTTPAuthorizationCredentials = Depends(_bearer)) -> str:
    try:
        payload = jwt.decode(credentials.credentials, ADMIN_JWT_SECRET, algorithms=[_ALGO])
        return payload["sub"]
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")


# ── Login / Register ──────────────────────────────────────────────────────────

@router.post("/login")
async def admin_login(body: dict) -> dict:
    username = body.get("username", "").strip()
    password = body.get("password", "")
    if not username or not password:
        raise HTTPException(status_code=422, detail="Username and password required")
    row = admin_db.get_admin_by_username(username)
    if not row or row["password_hash"] != _hash(password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = _make_token(username)
    return {"access_token": token, "token_type": "bearer", "expires_in": _EXPIRY_HOURS * 3600}


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def admin_register(body: dict) -> dict:
    username = body.get("username", "").strip()
    password = body.get("password", "")
    if not username or len(password) < 6:
        raise HTTPException(status_code=422, detail="Username required and password must be ≥6 characters")
    if admin_db.get_admin_by_username(username):
        raise HTTPException(status_code=409, detail="Username already taken")
    admin_db.create_admin_user(username=username, password_hash=_hash(password))
    token = _make_token(username)
    return {"access_token": token, "token_type": "bearer", "expires_in": _EXPIRY_HOURS * 3600}


@router.get("/me")
async def admin_me(sub: str = Depends(_verify_token)) -> dict:
    return {"username": sub, "role": "admin"}


# ── Report management ─────────────────────────────────────────────────────────

@router.get("/reports")
async def list_reports(
    report_status: str  = Query(default=None),
    report_type:   str  = Query(default=None),
    search:        str  = Query(default=None),
    limit:         int  = Query(default=50, ge=1, le=200),
    offset:        int  = Query(default=0,  ge=0),
    sub: str = Depends(_verify_token),
) -> dict:
    status_filter = [report_status] if report_status else None
    rows = report_db.get_all_reports(
        status_filter=status_filter,
        report_type=report_type,
        search=search,
        limit=limit,
        offset=offset,
    )
    return {"reports": rows, "total": len(rows)}


@router.get("/reports/{report_id}")
async def get_report(report_id: str, sub: str = Depends(_verify_token)) -> dict:
    row = report_db.get_report(report_id)
    if not row:
        raise HTTPException(status_code=404, detail="Report not found")
    return row


@router.post("/reports/{report_id}/approve")
async def approve_report(report_id: str, sub: str = Depends(_verify_token)) -> dict:
    row = report_db.get_report(report_id)
    if not row:
        raise HTTPException(status_code=404, detail="Report not found")
    updated = report_db.validate_report(report_id, validated_by="admin")
    return {"message": "Report approved", "report": updated}


@router.post("/reports/{report_id}/reject")
async def reject_report(report_id: str, body: dict, sub: str = Depends(_verify_token)) -> dict:
    reason = body.get("reason", "")
    if not reason:
        raise HTTPException(status_code=422, detail="Rejection reason required")
    row = report_db.get_report(report_id)
    if not row:
        raise HTTPException(status_code=404, detail="Report not found")
    updated = report_db.reject_report(report_id, resolved_by="admin", reason=reason)
    return {"message": "Report rejected", "report": updated}


@router.post("/reports/{report_id}/resolve")
async def resolve_report(report_id: str, sub: str = Depends(_verify_token)) -> dict:
    row = report_db.get_report(report_id)
    if not row:
        raise HTTPException(status_code=404, detail="Report not found")
    updated = report_db.resolve_report(report_id, resolved_by="admin")
    return {"message": "Report resolved", "report": updated}


@router.delete("/reports/{report_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_report(report_id: str, sub: str = Depends(_verify_token)) -> None:
    row = report_db.get_report(report_id)
    if not row:
        raise HTTPException(status_code=404, detail="Report not found")
    report_db.delete_report(report_id)


@router.get("/stats")
async def get_stats(sub: str = Depends(_verify_token)) -> dict:
    return report_db.get_report_stats()


# ── SMS alert dispatch ─────────────────────────────────────────────────────────

@router.post("/reports/{report_id}/send-sms")
async def send_sms_alert(report_id: str, sub: str = Depends(_verify_token)) -> dict:
    """Broadcast a flood SMS to all users within 10km of the validated report."""
    row = report_db.get_report(report_id)
    if not row:
        raise HTTPException(status_code=404, detail="Report not found")
    if row.get("status") != "validated":
        raise HTTPException(status_code=400, detail="Report must be validated before sending an SMS alert")
    from app.services.notifications import broadcast_flood_report
    result = await broadcast_flood_report(row)
    logger.info("Admin %s triggered SMS broadcast for report %s: %s", sub, report_id, result)
    return result


# ── Rescue requests ────────────────────────────────────────────────────────────

@router.get("/rescue-requests")
async def get_rescue_requests(sub: str = Depends(_verify_token)) -> list[dict]:
    """Return unacknowledged DANGER replies with the sender's last-known location."""
    from app.db.supabase_client import get_client
    from app.db.devices import get_device
    sb = get_client()
    rows = (
        sb.table("sms_alerts")
        .select("*")
        .eq("reply_status", "danger")
        .eq("rescue_acknowledged", False)
        .order("reply_at", desc=True)
        .execute().data or []
    )
    result = []
    for row in rows:
        device = get_device(row["user_id"]) if row.get("user_id") else None
        result.append({
            **row,
            "device_latitude":  device["latitude"]  if device else None,
            "device_longitude": device["longitude"] if device else None,
        })
    return result


@router.post("/rescue-requests/{alert_id}/acknowledge")
async def acknowledge_rescue(alert_id: str, sub: str = Depends(_verify_token)) -> dict:
    """Mark a rescue request as handled by the rescue team."""
    from app.db.supabase_client import get_client
    sb = get_client()
    sb.table("sms_alerts").update({"rescue_acknowledged": True}).eq("id", alert_id).execute()
    logger.info("Admin %s acknowledged rescue request %s", sub, alert_id)
    return {"message": "Rescue request acknowledged"}
