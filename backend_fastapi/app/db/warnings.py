"""In-memory warning store.

NOTE: Data is lost on server restart.
      Replace with a real database for production.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import TypedDict


class WarningRecord(TypedDict):
    id: str
    title: str
    description: str
    hazard_type: str          # HazardType enum value
    alert_level: str          # AlertLevel enum value
    latitude: float
    longitude: float
    radius_km: float
    source: str
    created_at: datetime
    active: bool


# Primary store — keyed by warning id
_warnings: dict[str, WarningRecord] = {}


# ── CRUD helpers ──────────────────────────────────────────────────────────────

def create_warning(
    *,
    title: str,
    description: str,
    hazard_type: str,
    alert_level: str,
    latitude: float,
    longitude: float,
    radius_km: float,
    source: str,
) -> WarningRecord:
    """Insert a new warning and return the record."""
    record: WarningRecord = {
        "id": str(uuid.uuid4()),
        "title": title,
        "description": description,
        "hazard_type": hazard_type,
        "alert_level": alert_level,
        "latitude": latitude,
        "longitude": longitude,
        "radius_km": radius_km,
        "source": source,
        "created_at": datetime.now(timezone.utc),
        "active": True,
    }
    _warnings[record["id"]] = record
    return record


def get_warning(warning_id: str) -> WarningRecord | None:
    return _warnings.get(warning_id)


def list_warnings(
    *,
    active_only: bool = True,
    hazard_type: str | None = None,
    alert_level: str | None = None,
) -> list[WarningRecord]:
    """Return warnings optionally filtered by active status, hazard, or level."""
    results = list(_warnings.values())
    if active_only:
        results = [w for w in results if w["active"]]
    if hazard_type:
        results = [w for w in results if w["hazard_type"] == hazard_type]
    if alert_level:
        results = [w for w in results if w["alert_level"] == alert_level]
    # Newest first
    results.sort(key=lambda w: w["created_at"], reverse=True)
    return results


def deactivate_warning(warning_id: str) -> WarningRecord | None:
    """Mark a warning as inactive (resolved / expired)."""
    record = _warnings.get(warning_id)
    if record:
        record["active"] = False
    return record


def get_all_active_warnings() -> list[WarningRecord]:
    """Return every active warning (used when resolving user-local alerts)."""
    return [w for w in _warnings.values() if w["active"]]
