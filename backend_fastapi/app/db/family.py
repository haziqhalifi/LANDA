"""Family groups and safety status database layer."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from app.db.supabase_client import get_client


def create_family_group(*, leader_user_id: str, name: str = "My Family") -> dict:
    sb = get_client()
    row = {
        "id": str(uuid.uuid4()), "leader_user_id": leader_user_id,
        "name": name, "created_at": datetime.now(timezone.utc).isoformat(),
    }
    return sb.table("family_groups").insert(row).execute().data[0]


def get_family_group(group_id: str) -> dict | None:
    sb = get_client()
    res = sb.table("family_groups").select("*").eq("id", group_id).limit(1).execute()
    return res.data[0] if res.data else None


def get_groups_by_leader(leader_user_id: str) -> list[dict]:
    sb = get_client()
    return sb.table("family_groups").select("*").eq("leader_user_id", leader_user_id).execute().data or []


def add_family_member(*, group_id: str, name: str,
                       phone_number: str = "", relationship: str = "") -> dict:
    sb = get_client()
    row = {
        "id": str(uuid.uuid4()), "group_id": group_id, "name": name,
        "phone_number": phone_number, "relationship": relationship,
        "safety_status": "unknown",
        "last_updated": datetime.now(timezone.utc).isoformat(),
    }
    return sb.table("family_members").insert(row).execute().data[0]


def get_family_members(group_id: str) -> list[dict]:
    sb = get_client()
    return sb.table("family_members").select("*").eq("group_id", group_id).execute().data or []


def get_family_member(member_id: str) -> dict | None:
    sb = get_client()
    res = sb.table("family_members").select("*").eq("id", member_id).limit(1).execute()
    return res.data[0] if res.data else None


def update_member_status(member_id: str, *, safety_status: str) -> dict | None:
    sb = get_client()
    res = sb.table("family_members").update({
        "safety_status": safety_status,
        "last_updated": datetime.now(timezone.utc).isoformat(),
    }).eq("id", member_id).execute()
    return res.data[0] if res.data else None


def update_member_info(member_id: str, *, name: str | None = None,
                        phone_number: str | None = None,
                        relationship: str | None = None) -> dict | None:
    sb = get_client()
    updates: dict = {"last_updated": datetime.now(timezone.utc).isoformat()}
    if name is not None:
        updates["name"] = name
    if phone_number is not None:
        updates["phone_number"] = phone_number
    if relationship is not None:
        updates["relationship"] = relationship
    res = sb.table("family_members").update(updates).eq("id", member_id).execute()
    return res.data[0] if res.data else None


def delete_family_member(member_id: str) -> bool:
    sb = get_client()
    sb.table("family_members").delete().eq("id", member_id).execute()
    return True


def delete_family_group(group_id: str) -> bool:
    """Delete a family group and all its members."""
    sb = get_client()
    # Delete all members first (foreign key)
    sb.table("family_members").delete().eq("group_id", group_id).execute()
    sb.table("family_groups").delete().eq("id", group_id).execute()
    return True


def rename_family_group(group_id: str, *, name: str) -> dict | None:
    """Rename a family group."""
    sb = get_client()
    res = (
        sb.table("family_groups")
        .update({"name": name})
        .eq("id", group_id)
        .select()
        .execute()
    )
    return res.data[0] if res.data else None


def find_member_by_phone(phone_number: str) -> dict | None:
    """Used by SMS webhook to identify who replied."""
    sb = get_client()
    res = sb.table("family_members").select("*").eq("phone_number", phone_number).limit(1).execute()
    return res.data[0] if res.data else None
