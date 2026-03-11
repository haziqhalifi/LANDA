"""Admin authentication database layer."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from app.db.supabase_client import get_client


def get_admin_by_username(username: str) -> dict | None:
    sb = get_client()
    res = sb.table("admin_users").select("*").eq("username", username).limit(1).execute()
    return res.data[0] if res.data else None


def create_admin_user(*, username: str, password_hash: str) -> dict:
    sb = get_client()
    row = {
        "id": str(uuid.uuid4()),
        "username": username,
        "password_hash": password_hash,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    return sb.table("admin_users").insert(row).execute().data[0]
