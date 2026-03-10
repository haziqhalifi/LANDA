"""Preparedness database layer: personal checklist, educational views, evacuation centres."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from app.core.geo import haversine
from app.db.supabase_client import get_client


# ── Personal Checklist ────────────────────────────────────────────────────────

def create_checklist_item(*, user_id: str, item_name: str,
                           category: str = "general", notes: str = "") -> dict:
    sb = get_client()
    row = {
        "id": str(uuid.uuid4()), "user_id": user_id, "item_name": item_name,
        "category": category, "completed": False, "notes": notes,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    return sb.table("personal_checklist").insert(row).execute().data[0]


def get_user_checklist(user_id: str) -> list[dict]:
    sb = get_client()
    return (
        sb.table("personal_checklist")
        .select("*").eq("user_id", user_id)
        .order("category").order("item_name")
        .execute().data or []
    )


def toggle_checklist_item(item_id: str, *, completed: bool) -> dict | None:
    sb = get_client()
    now = datetime.now(timezone.utc).isoformat()
    updates = {
        "completed": completed,
        "completed_at": now if completed else None,
    }
    res = sb.table("personal_checklist").update(updates).eq("id", item_id).execute()
    return res.data[0] if res.data else None


def delete_checklist_item(item_id: str) -> bool:
    sb = get_client()
    sb.table("personal_checklist").delete().eq("id", item_id).execute()
    return True


def seed_default_checklist(user_id: str, default_items: list[dict]) -> None:
    """Bulk-insert the default 18 preparedness items for a new user (single round-trip)."""
    sb = get_client()
    now = datetime.now(timezone.utc).isoformat()
    rows = [
        {
            "id":              str(uuid.uuid4()),
            "user_id":         user_id,
            "item_name":       item["item_name"],
            "category":        item["category"],
            "completed":       False,
            "notes":           "",
            "linked_topic_id": item.get("linked_topic_id"),
            "created_at":      now,
        }
        for item in default_items
    ]
    sb.table("personal_checklist").insert(rows).execute()


def autocomplete_linked_item(user_id: str, topic_id: str) -> None:
    """Mark the checklist item linked to topic_id as completed (if not already)."""
    sb = get_client()
    now = datetime.now(timezone.utc).isoformat()
    sb.table("personal_checklist").update(
        {"completed": True, "completed_at": now}
    ).eq("user_id", user_id).eq("linked_topic_id", topic_id).eq("completed", False).execute()


# ── Educational Content Views ─────────────────────────────────────────────────

def mark_topic_viewed(user_id: str, topic_id: str) -> None:
    sb = get_client()
    try:
        sb.table("educational_content_views").insert({
            "id": str(uuid.uuid4()), "user_id": user_id, "topic_id": topic_id,
            "viewed_at": datetime.now(timezone.utc).isoformat(),
        }).execute()
    except Exception:
        pass  # Already viewed (UNIQUE constraint)


def get_viewed_topics(user_id: str) -> set[str]:
    sb = get_client()
    res = sb.table("educational_content_views").select("topic_id").eq("user_id", user_id).execute()
    return {r["topic_id"] for r in (res.data or [])}


# ── Evacuation Centres ────────────────────────────────────────────────────────

def get_nearby_evacuation_centres(
    latitude: float,
    longitude: float,
    radius_km: float = 20.0,
    limit: int = 10,
) -> list[dict]:
    """Return evacuation centres within radius_km, sorted by distance."""
    sb = get_client()
    rows = sb.table("evacuation_centres").select("*").eq("active", True).execute().data or []

    nearby = []
    for row in rows:
        dist = haversine(latitude, longitude, row["latitude"], row["longitude"])
        if dist <= radius_km:
            nearby.append({**row, "distance_km": round(dist, 3)})

    nearby.sort(key=lambda r: r["distance_km"])
    return nearby[:limit]


def get_nearest_evacuation_centre(latitude: float, longitude: float) -> dict | None:
    results = get_nearby_evacuation_centres(latitude, longitude, radius_km=50.0, limit=1)
    return results[0] if results else None
