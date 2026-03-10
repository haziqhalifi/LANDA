"""Preparedness endpoints: personal checklist, educational content, evacuation centres."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.api.v1.dependencies import get_current_user
from app.db import preparedness as prep_db
from app.schemas.preparedness import (
    ChecklistItemCreate, ChecklistItemOut, ChecklistSummaryOut,
    EducationalTopicOut, EvacuationCentreOut, ExternalLink,
)
from app.schemas.user import UserOut

router = APIRouter()

EDUCATIONAL_TOPICS: list[dict] = [
    {
        "id": "before-flood-prep",
        "title": "Before a Flood: Preparing Your Home",
        "description": "Essential steps to protect your home and family before floods hit",
        "category": "before_flood",
        "content": "Prepare an emergency kit with 3 days of supplies. Know your evacuation route. Store important documents in waterproof containers. Elevate electrical appliances. Sign up for local emergency alerts.",
        "external_links": [
            {"title": "FEMA Ready.gov — Prepare for a Flood", "url": "https://www.ready.gov/floods"},
            {"title": "CDC — Preparing for Floods", "url": "https://www.cdc.gov/floods/safety/index.html"},
            {"title": "OSHA — Flood Preparedness", "url": "https://www.osha.gov/flood/preparedness"},
        ],
    },
    {
        "id": "during-flood-escape",
        "title": "How to Escape During a Flood",
        "description": "Safe evacuation procedures during an active flood event",
        "category": "during_flood",
        "content": "Move to higher ground immediately. Never walk or drive through floodwaters. If trapped, go to the highest floor and signal for help. Follow official evacuation orders.",
        "external_links": [
            {"title": "NOAA National Weather Service — Flood Safety", "url": "https://www.weather.gov/safety/flood"},
            {"title": "American Red Cross — Flood Safety & Evacuation", "url": "https://www.redcross.org/get-help/how-to-prepare-for-emergencies/types-of-emergencies/flood.html"},
            {"title": "SDSU Extension — What to Do During a Flood", "url": "https://extension.sdstate.edu/flood-preparedness"},
        ],
    },
    {
        "id": "during-flood-survival",
        "title": "Flood Survival Basics",
        "description": "What to do if you are caught in floodwaters",
        "category": "during_flood",
        "content": "Stay calm. Call 999 or 991 (APM) for rescue. Use your phone torch to signal rescuers at night. Conserve phone battery. Do not drink floodwater.",
        "external_links": [
            {"title": "WHO — Floods and Health Risks", "url": "https://www.who.int/health-topics/floods"},
            {"title": "Malaysian Red Crescent Society", "url": "https://www.redcrescent.org.my"},
            {"title": "PreventionWeb — Flood Disaster Knowledge Hub", "url": "https://www.preventionweb.net"},
        ],
    },
    {
        "id": "after-flood-return",
        "title": "Returning Home After a Flood",
        "description": "Safety precautions when returning home after flooding",
        "category": "after_flood",
        "content": "Wait for official all-clear before returning. Check for structural damage. Do not turn on electricity until checked. Discard food that contacted floodwater. Clean and disinfect all surfaces.",
        "external_links": [
            {"title": "American Red Cross — Returning Home After a Flood", "url": "https://www.redcross.org/about-us/news-and-events/news/20-Red-Cross-Safety-Steps-for-Returning-Home-After-the-Flood.html"},
            {"title": "OSHA — Flood Response & Recovery", "url": "https://www.osha.gov/flood/response"},
            {"title": "Susquehanna Flood Forecasting — Before, During & After", "url": "https://www.susquehannafloodforecasting.org/before-during-after.html"},
        ],
    },
    {
        "id": "emergency-supplies-kit",
        "title": "Building Your Emergency Supply Kit",
        "description": "What to include in your 72-hour emergency go-bag",
        "category": "general",
        "content": "Include: 3 litres of water per person per day, non-perishable food for 3 days, first aid kit, torchlight, whistle, manual can opener, local maps, phone charger, documents in waterproof bag.",
        "external_links": [
            {"title": "FEMA Ready.gov — Build an Emergency Supply Kit", "url": "https://www.ready.gov/kit"},
            {"title": "Red Cross — Disaster Survival Kit Supplies", "url": "https://www.redcross.org/get-help/how-to-prepare-for-emergencies/survival-kit-supplies.html"},
            {"title": "BOMBA — Malaysia Fire & Rescue Department", "url": "https://www.bomba.gov.my"},
        ],
    },
    {
        "id": "family-emergency-plan",
        "title": "Creating a Family Emergency Plan",
        "description": "How to plan and communicate your family emergency response",
        "category": "general",
        "content": "Discuss with family: where to meet if separated, who is the emergency contact, where nearest evacuation centre is. Practice your evacuation route. Teach children to call 999.",
        "external_links": [
            {"title": "FEMA Ready.gov — Make a Family Emergency Plan", "url": "https://www.ready.gov/plan"},
            {"title": "Red Cross — How to Make an Emergency Plan", "url": "https://www.redcross.org/get-help/how-to-prepare-for-emergencies/make-a-plan.html"},
            {"title": "UNICEF — Child & Family Emergency Safety", "url": "https://www.unicef.org"},
        ],
    },
]

_TOPICS_BY_ID: dict[str, dict] = {t["id"]: t for t in EDUCATIONAL_TOPICS}

DEFAULT_CHECKLIST_ITEMS: list[dict] = [
    # ── Supplies (5) ──────────────────────────────────────────────────────────
    {"item_name": "Store 3 litres of water per person per day (3-day supply)", "category": "supplies", "linked_topic_id": None},
    {"item_name": "Prepare non-perishable food for 3 days",                   "category": "supplies", "linked_topic_id": None},
    {"item_name": "Pack a first-aid kit in your emergency bag",               "category": "supplies", "linked_topic_id": None},
    {"item_name": "Keep a torchlight and spare batteries",                    "category": "supplies", "linked_topic_id": None},
    {"item_name": "Store important documents in a waterproof bag",            "category": "supplies", "linked_topic_id": None},
    # ── Planning (5) ──────────────────────────────────────────────────────────
    {"item_name": "Know the location of your nearest evacuation centre",      "category": "planning", "linked_topic_id": None},
    {"item_name": "Plan your evacuation route with all family members",       "category": "planning", "linked_topic_id": None},
    {"item_name": "Identify a family emergency meeting point",                "category": "planning", "linked_topic_id": None},
    {"item_name": "Save emergency numbers: Police 999, APM 991",              "category": "planning", "linked_topic_id": None},
    {"item_name": "Sign up for local flood alert notifications",              "category": "planning", "linked_topic_id": None},
    # ── Training (2) ──────────────────────────────────────────────────────────
    {"item_name": "Learn basic first aid (CPR, wound care)",                  "category": "training", "linked_topic_id": None},
    {"item_name": "Practice your evacuation route with family",               "category": "training", "linked_topic_id": None},
    # ── Education — linked to Learn tab topics (6) ────────────────────────────
    {"item_name": "Read: Before a Flood — Preparing Your Home",              "category": "general",  "linked_topic_id": "before-flood-prep"},
    {"item_name": "Read: How to Escape During a Flood",                      "category": "general",  "linked_topic_id": "during-flood-escape"},
    {"item_name": "Read: Flood Survival Basics",                             "category": "general",  "linked_topic_id": "during-flood-survival"},
    {"item_name": "Read: Returning Home After a Flood",                      "category": "general",  "linked_topic_id": "after-flood-return"},
    {"item_name": "Read: Building Your Emergency Supply Kit",                "category": "general",  "linked_topic_id": "emergency-supplies-kit"},
    {"item_name": "Read: Creating a Family Emergency Plan",                  "category": "general",  "linked_topic_id": "family-emergency-plan"},
]


def _topic_out(topic: dict, viewed_ids: set[str]) -> EducationalTopicOut:
    return EducationalTopicOut(
        id=topic["id"],
        title=topic["title"],
        description=topic["description"],
        category=topic["category"],
        content=topic["content"],
        external_links=[ExternalLink(**lnk) for lnk in topic["external_links"]],
        user_viewed=topic["id"] in viewed_ids,
    )


def _score_message(score: float) -> str:
    if score >= 80:
        return "Excellent Preparedness"
    if score >= 60:
        return "Good Preparedness"
    return "Needs Improvement"


@router.get("/checklist", response_model=ChecklistSummaryOut)
async def get_checklist(current_user: UserOut = Depends(get_current_user)) -> ChecklistSummaryOut:
    items = prep_db.get_user_checklist(current_user.id)
    if not items:
        prep_db.seed_default_checklist(current_user.id, DEFAULT_CHECKLIST_ITEMS)
        items = prep_db.get_user_checklist(current_user.id)
    done  = sum(1 for i in items if i["completed"])
    total = len(items)
    score = round((done / total * 100) if total > 0 else 0.0, 1)
    return ChecklistSummaryOut(
        total_items=total, completed_items=done, score_percent=score,
        status_message=_score_message(score),
        items=[ChecklistItemOut(**i) for i in items],
    )


@router.post("/checklist", response_model=ChecklistItemOut, status_code=status.HTTP_201_CREATED)
async def add_checklist_item(body: ChecklistItemCreate, current_user: UserOut = Depends(get_current_user)) -> ChecklistItemOut:
    row = prep_db.create_checklist_item(
        user_id=current_user.id, item_name=body.item_name,
        category=body.category, notes=body.notes,
    )
    return ChecklistItemOut(**row)


@router.patch("/checklist/{item_id}/toggle", response_model=ChecklistItemOut)
async def toggle_item(item_id: str, completed: bool = Query(...), current_user: UserOut = Depends(get_current_user)) -> ChecklistItemOut:
    updated = prep_db.toggle_checklist_item(item_id, completed=completed)
    if not updated:
        raise HTTPException(status_code=404, detail="Checklist item not found")
    return ChecklistItemOut(**updated)


@router.delete("/checklist/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_item(item_id: str, current_user: UserOut = Depends(get_current_user)) -> None:
    prep_db.delete_checklist_item(item_id)


@router.get("/score")
async def get_score(current_user: UserOut = Depends(get_current_user)) -> dict:
    items = prep_db.get_user_checklist(current_user.id)
    if not items:
        prep_db.seed_default_checklist(current_user.id, DEFAULT_CHECKLIST_ITEMS)
        items = prep_db.get_user_checklist(current_user.id)
    done  = sum(1 for i in items if i["completed"])
    total = len(items)
    score = round((done / total * 100) if total > 0 else 0.0, 1)
    return {"score_percent": score, "status_message": _score_message(score), "completed": done, "total": total}


@router.get("/education", response_model=list[EducationalTopicOut])
async def list_education(current_user: UserOut = Depends(get_current_user)) -> list[EducationalTopicOut]:
    viewed = prep_db.get_viewed_topics(current_user.id)
    return [_topic_out(t, viewed) for t in EDUCATIONAL_TOPICS]


@router.get("/education/{topic_id}", response_model=EducationalTopicOut)
async def get_education_topic(topic_id: str, current_user: UserOut = Depends(get_current_user)) -> EducationalTopicOut:
    topic = _TOPICS_BY_ID.get(topic_id)
    if not topic:
        raise HTTPException(status_code=404, detail="Topic not found")
    viewed = prep_db.get_viewed_topics(current_user.id)
    return _topic_out(topic, viewed)


@router.post("/education/{topic_id}/view", status_code=status.HTTP_204_NO_CONTENT)
async def mark_viewed(topic_id: str, current_user: UserOut = Depends(get_current_user)) -> None:
    if topic_id not in _TOPICS_BY_ID:
        raise HTTPException(status_code=404, detail="Topic not found")
    prep_db.mark_topic_viewed(current_user.id, topic_id)
    prep_db.autocomplete_linked_item(current_user.id, topic_id)


@router.get("/evacuation-centres/nearby", response_model=list[EvacuationCentreOut])
async def nearby_evacuation_centres(
    latitude:  float = Query(..., ge=-90,  le=90),
    longitude: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(default=20.0, gt=0, le=100),
    current_user: UserOut = Depends(get_current_user),
) -> list[EvacuationCentreOut]:
    rows = prep_db.get_nearby_evacuation_centres(latitude, longitude, radius_km)
    return [EvacuationCentreOut(**r) for r in rows]
