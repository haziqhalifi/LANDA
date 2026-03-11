"""MetMalaysia API client — fetches official weather warnings from api.data.gov.my.

Data flow:
  Scheduler (every 5 min)
    → fetch_and_store_warnings()
      → GET https://api.data.gov.my/weather/warning/
      → parse + upsert into government_alerts table (Supabase)

End-users then query GET /api/v1/warnings/nearby/ which reads from government_alerts.

Real API response shape (each item):
{
  "warning_issue": {"issued": "...", "title_bm": "...", "title_en": "..."},
  "valid_from":    "2026-03-09T16:00:00",
  "valid_to":      "2026-03-16T00:00:00",
  "heading_en":    "Warning on Strong Wind and Rough Seas (Third Category)",
  "heading_bm":    "...",
  "text_en":       "Strong northeasterly winds over 60 kmph ...",
  "text_bm":       "...",
  "instruction_en": null,
  "instruction_bm": null,
}
"""

from __future__ import annotations

import asyncio
import hashlib
import logging
import uuid
from datetime import datetime, timezone

import httpx

logger = logging.getLogger(__name__)

_BASE_URL = "https://api.data.gov.my/weather/warning/"
_TIMEOUT  = 20  # seconds


def _severity_from_heading(heading: str) -> str:
    """Map MetMalaysia warning heading to a simple severity label."""
    h = (heading or "").lower()
    if any(k in h for k in ("third category", "third", "extreme", "danger")):
        return "high"
    if any(k in h for k in ("second category", "second", "severe")):
        return "medium"
    if any(k in h for k in ("first category", "first", "alert", "thunderstorm", "rain")):
        return "low"
    return "info"


def _make_dedup_id(item: dict) -> str:
    """Create a stable UUID-v5 from (heading_en + valid_from) for deduplication."""
    key = (item.get("heading_en") or "") + "|" + (item.get("valid_from") or "")
    return str(uuid.uuid5(uuid.NAMESPACE_URL, key))


def _parse_warning(item: dict) -> dict:
    """Convert a MetMalaysia API item into a government_alerts row."""
    warning_issue = item.get("warning_issue") or {}
    issued_at = warning_issue.get("issued", "")
    title_en = warning_issue.get("title_en", "")

    heading_en  = item.get("heading_en") or title_en or "MetMalaysia Warning"
    text_en     = item.get("text_en") or ""
    valid_from  = item.get("valid_from") or ""
    valid_to    = item.get("valid_to") or ""

    # Area extracted from text: many warnings reference a sea / region in the text
    area = heading_en  # Use heading as area label; no lat/lon available

    return {
        "id":         _make_dedup_id(item),
        "source":     "metmalaysia",
        "area":       area,
        "severity":   _severity_from_heading(heading_en),
        "latitude":   None,   # MetMalaysia warnings are regional, no point-lat
        "longitude":  None,
        "raw_data":   {
            "heading_en":     heading_en,
            "heading_bm":     item.get("heading_bm", ""),
            "text_en":        text_en,
            "text_bm":        item.get("text_bm", ""),
            "instruction_en": item.get("instruction_en"),
            "valid_from":     valid_from,
            "valid_to":       valid_to,
            "issued_at":      issued_at,
            "title_en":       title_en,
        },
        "fetched_at": datetime.now(timezone.utc).isoformat(),
        "active": True,
    }


def _upsert_warnings_sync(rows: list[dict]) -> int:
    """Synchronous Supabase upsert — runs in a thread pool from async callers."""
    from app.db.supabase_client import get_client
    if not rows:
        return 0
    sb = get_client()
    stored = 0
    for row in rows:
        try:
            # Upsert on id — no duplicate inserts on repeated fetch
            sb.table("government_alerts").upsert(row, on_conflict="id").execute()
            stored += 1
        except Exception as exc:
            logger.warning("Failed to upsert MetMalaysia warning (id=%s): %s", row.get("id"), exc)
    return stored


async def fetch_and_store_warnings() -> int:
    """Fetch current MetMalaysia warnings and upsert into government_alerts.

    Returns the number of rows upserted.
    Safe to call from an async context (e.g. APScheduler async job) because
    the synchronous Supabase calls run in asyncio.to_thread().
    """
    # ── 1. Fetch from MetMalaysia (fully async) ───────────────────────────────
    try:
        async with httpx.AsyncClient(timeout=_TIMEOUT, follow_redirects=True) as client:
            resp = await client.get(_BASE_URL)
            resp.raise_for_status()
            data = resp.json()
    except Exception as exc:
        logger.warning("MetMalaysia fetch failed: %s", exc)
        return 0

    # ── 2. Parse ──────────────────────────────────────────────────────────────
    items = data if isinstance(data, list) else data.get("data", [])
    if not items:
        logger.info("MetMalaysia: no warnings returned")
        return 0

    rows = []
    for item in items:
        try:
            rows.append(_parse_warning(item))
        except Exception as exc:
            logger.warning("MetMalaysia: failed to parse item: %s — %s", item, exc)

    # ── 3. Upsert in thread pool (avoids blocking the async event loop) ───────
    stored = await asyncio.to_thread(_upsert_warnings_sync, rows)
    logger.info("MetMalaysia: upserted %d/%d warnings", stored, len(rows))
    return stored


def get_active_warnings(area_keywords: list[str] | None = None) -> list[dict]:
    """Return recent MetMalaysia warnings (last 24 hours), optionally filtered by keywords.

    Synchronous — safe to call from FastAPI endpoint handlers (sync DB layer).
    """
    from datetime import timedelta
    from app.db.supabase_client import get_client
    sb = get_client()
    cutoff = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()
    res = (
        sb.table("government_alerts")
        .select("*")
        .eq("source", "metmalaysia")
        .gte("fetched_at", cutoff)
        .order("fetched_at", desc=True)
        .execute()
    )
    rows = res.data or []
    if area_keywords:
        rows = [
            r for r in rows
            if any(kw.lower() in (r.get("area") or "").lower() for kw in area_keywords)
        ]
    return rows
