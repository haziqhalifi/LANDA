"""APScheduler background jobs.

Jobs:
  fetch_metmalaysia    every 5 minutes  — fetch gov flood warnings
  monitor_flood_reports every 2 minutes — send SMS for newly validated flood reports
  expire_old_reports   daily at midnight

NOTE: The sync Supabase client calls are wrapped in asyncio.to_thread()
so they run in a thread pool and do NOT block the async event loop.
"""

from __future__ import annotations

import asyncio
import logging

from apscheduler.schedulers.asyncio import AsyncIOScheduler

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()


async def _job_fetch_metmalaysia() -> None:
    try:
        from app.services import met_malaysia
        # Fetch is already async (uses httpx AsyncClient)
        n = await met_malaysia.fetch_and_store_warnings()
        logger.info("[scheduler] MetMalaysia: %d warnings stored", n)
    except Exception as exc:
        logger.error("[scheduler] MetMalaysia failed: %s", exc)


async def _job_monitor_flood_reports() -> None:
    """Send Twilio SMS flood alerts for reports validated in the last 2 minutes."""
    try:
        from app.services.notifications import broadcast_flood_report
        from app.db import reports as report_db

        # Run sync DB call in a thread to avoid blocking the event loop
        recent = await asyncio.to_thread(
            report_db.get_validated_flood_reports_since, minutes=2
        )
        for report in recent:
            try:
                await broadcast_flood_report(report)
            except Exception as exc:
                logger.error(
                    "[scheduler] broadcast failed for report %s: %s",
                    report["id"], exc,
                )
    except Exception as exc:
        logger.error("[scheduler] monitor_flood_reports failed: %s", exc)


async def _job_expire_old_reports() -> None:
    try:
        from app.db import reports as report_db
        # Run sync DB call in a thread
        n = await asyncio.to_thread(report_db.expire_old_reports)
        logger.info("[scheduler] Expired %d old reports", n)
    except Exception as exc:
        logger.error("[scheduler] expire_old_reports failed: %s", exc)


def start_scheduler() -> None:
    scheduler.add_job(_job_fetch_metmalaysia,     "interval", minutes=5,  id="metmalaysia")
    scheduler.add_job(_job_monitor_flood_reports, "interval", minutes=2,  id="flood_monitor")
    scheduler.add_job(_job_expire_old_reports,    "cron",     hour=0, minute=0, id="expire")
    scheduler.start()
    logger.info("[scheduler] Started — 3 jobs registered")


def stop_scheduler() -> None:
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("[scheduler] Stopped")
