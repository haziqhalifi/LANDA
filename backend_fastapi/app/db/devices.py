"""In-memory user-location and device-registration store.

Tracks each user's last-known location, FCM push token,
and phone number for SMS fallback.

NOTE: Data is lost on server restart.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import TypedDict


class DeviceRecord(TypedDict):
    user_id: str
    latitude: float | None
    longitude: float | None
    fcm_token: str | None
    phone_number: str | None
    updated_at: datetime | None


# Keyed by user_id
_devices: dict[str, DeviceRecord] = {}


# ── Helpers ──────────────────────────────────────────────────────────────────

def _ensure(user_id: str) -> DeviceRecord:
    """Return the existing record or create a blank one."""
    if user_id not in _devices:
        _devices[user_id] = {
            "user_id": user_id,
            "latitude": None,
            "longitude": None,
            "fcm_token": None,
            "phone_number": None,
            "updated_at": None,
        }
    return _devices[user_id]


def update_location(user_id: str, latitude: float, longitude: float) -> DeviceRecord:
    rec = _ensure(user_id)
    rec["latitude"] = latitude
    rec["longitude"] = longitude
    rec["updated_at"] = datetime.now(timezone.utc)
    return rec


def register_device(
    user_id: str,
    fcm_token: str | None = None,
    phone_number: str | None = None,
) -> DeviceRecord:
    rec = _ensure(user_id)
    if fcm_token is not None:
        rec["fcm_token"] = fcm_token
    if phone_number is not None:
        rec["phone_number"] = phone_number
    rec["updated_at"] = datetime.now(timezone.utc)
    return rec


def get_device(user_id: str) -> DeviceRecord | None:
    return _devices.get(user_id)


def get_all_devices_with_location() -> list[DeviceRecord]:
    """Return every device record that has a known location."""
    return [d for d in _devices.values() if d["latitude"] is not None]
