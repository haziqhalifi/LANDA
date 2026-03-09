"""Pydantic schemas for personal preparedness checklist and educational content."""

from __future__ import annotations

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class ChecklistCategory(str, Enum):
    supplies = "supplies"
    training = "training"
    planning = "planning"
    general  = "general"


# ── Personal Checklist ────────────────────────────────────────────────────────

class ChecklistItemCreate(BaseModel):
    item_name: str = Field(..., min_length=1, max_length=200)
    category:  str = Field(default="general", max_length=50)
    notes:     str = Field(default="", max_length=500)


class ChecklistItemOut(BaseModel):
    id:              str
    user_id:         str
    item_name:       str
    category:        str
    completed:       bool
    completed_at:    datetime | None
    notes:           str
    linked_topic_id: str | None = None
    created_at:      datetime


class ChecklistSummaryOut(BaseModel):
    total_items:     int
    completed_items: int
    score_percent:   float
    status_message:  str
    items:           list[ChecklistItemOut]


# ── Educational Content ───────────────────────────────────────────────────────

class ExternalLink(BaseModel):
    title: str
    url:   str


class EducationalTopicOut(BaseModel):
    id:             str
    title:          str
    description:    str
    category:       str   # before_flood | during_flood | after_flood | general
    content:        str
    external_links: list[ExternalLink]
    user_viewed:    bool = False


# ── Evacuation Centre ─────────────────────────────────────────────────────────

class EvacuationCentreOut(BaseModel):
    id:                str
    name:              str
    address:           str = ""
    latitude:          float
    longitude:         float
    capacity:          int = 0
    current_occupancy: int = 0
    contact_phone:     str | None = None
    active:            bool = True
    distance_km:       float = 0.0

    model_config = {"from_attributes": True}
