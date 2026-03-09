"""Twilio SMS webhook endpoint — processes safety status replies."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Form, Request, Response

from app.db import family as family_db

logger = logging.getLogger(__name__)
router = APIRouter()

_SAFE_KEYWORDS    = {"safe", "selamat", "ok", "okay"}
_DANGER_KEYWORDS  = {"danger", "help", "bahaya", "tolong", "sos"}


def _parse_status(body: str) -> str | None:
    """Return 'safe', 'needs_help', or None if unrecognised."""
    word = body.strip().lower()
    if word in _SAFE_KEYWORDS:
        return "safe"
    if word in _DANGER_KEYWORDS:
        return "needs_help"
    return None


def _twiml(message: str) -> Response:
    xml = f'<?xml version="1.0" encoding="UTF-8"?><Response><Message>{message}</Message></Response>'
    return Response(content=xml, media_type="application/xml")


@router.post("/webhook")
async def sms_webhook(
    request: Request,
    From: str = Form(...),
    Body: str = Form(...),
) -> Response:
    logger.info("SMS reply from %s: %s", From, Body[:60])

    # Find family member by phone number
    member = family_db.find_member_by_phone(From)
    if not member:
        logger.warning("Unregistered phone replied: %s", From)
        return _twiml("Your number is not registered. Download the Resilience AI app to register.")

    new_status = _parse_status(Body)
    if new_status is None:
        return _twiml(
            "Reply not recognised. Please reply:\n"
            "SAFE - if you are safe\n"
            "DANGER - if you need help"
        )

    # Update family member status in DB
    family_db.update_member_status(member["id"], safety_status=new_status)
    logger.info("Updated %s (%s) status to %s via SMS", member["name"], From, new_status)

    # Record reply on the outgoing SMS alert row so admin rescue panel can see it
    try:
        from app.services.twilio_service import record_sms_reply
        record_sms_reply(From, new_status)
    except Exception as exc:
        logger.warning("record_sms_reply failed: %s", exc)

    # Notify family group leader via FCM (best effort)
    try:
        group = family_db.get_family_group(member["group_id"])
        if group:
            from app.services.notifications import _send_push
            from app.db.devices import get_device
            leader_device = get_device(group["leader_user_id"])
            if leader_device and leader_device.get("fcm_token"):
                label = "SAFE" if new_status == "safe" else "DANGER"
                _send_push(
                    leader_device["fcm_token"],
                    "Family Safety Update",
                    f"{member['name']} replied {label} via SMS",
                    {"type": "family_sms_reply"},
                )
    except Exception as exc:
        logger.warning("FCM notify failed: %s", exc)

    label = "SAFE" if new_status == "safe" else "DANGER - help requested"
    return _twiml(
        f"Status updated to {label}. Your family has been notified. Stay safe."
    )
