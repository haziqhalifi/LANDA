"""Pydantic schemas for family groups and safety check-in."""

from __future__ import annotations

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field, field_validator


class FamilySafetyStatus(str, Enum):
    unknown    = "unknown"
    safe       = "safe"
    needs_help = "needs_help"   # stored as needs_help in DB; displayed as DANGER in UI


# ── Family Groups ─────────────────────────────────────────────────────────────

class FamilyMemberIn(BaseModel):
    name:         str = Field(..., min_length=1, max_length=200)
    phone_number: str = Field(default="", max_length=20)
    relationship: str = Field(default="", max_length=50)


class FamilyGroupCreate(BaseModel):
    name:    str                  = Field(default="My Family", max_length=100)
    members: list[FamilyMemberIn] = Field(default_factory=list)

    @field_validator('members')
    @classmethod
    def at_least_one_member(cls, v: list) -> list:
        if len(v) < 1:
            raise ValueError('At least one member is required to create a family group.')
        return v


class FamilyGroupRename(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)


class FamilyMemberOut(BaseModel):
    id:            str
    group_id:      str
    name:          str
    phone_number:  str
    relationship:  str
    safety_status: str
    last_updated:  datetime


class FamilyGroupOut(BaseModel):
    id:             str
    leader_user_id: str
    name:           str
    members:        list[FamilyMemberOut]
    created_at:     datetime


# ── Status Update ─────────────────────────────────────────────────────────────

class FamilyCheckin(BaseModel):
    member_id: str
    status:    FamilySafetyStatus
    source:    str = Field(default="app", max_length=20)  # "app" | "sms"


class FamilyCheckinOut(BaseModel):
    member_id:     str
    safety_status: str
    last_updated:  datetime
    leader_notified: bool = False


# ── Member Update ─────────────────────────────────────────────────────────────

class FamilyMemberUpdate(BaseModel):
    name:         str | None = Field(default=None, min_length=1, max_length=200)
    phone_number: str | None = Field(default=None, max_length=20)
    relationship: str | None = Field(default=None, max_length=50)
