# Implementation Tasks: Disaster Resilience System MVP

## Sprint Overview

**Priority Order**: Backend Core → Personal Preparedness → Family Safety → Community Reports → SMS Alerts with Reply → Admin Website → Testing

**Estimated Total Time**: 32-38 hours

---

## Phase 1: Backend Foundation (Hours 0-6)

### Task 1: Project Setup & Environment ⚡ CRITICAL
**Priority**: P0 | **Estimated**: 1 hour | **Dependencies**: None

**Subtasks**:
1. Verify FastAPI project structure
2. Confirm Supabase connection
3. Set up environment variables (.env) for Twilio
4. Install Twilio SDK
5. Test health check endpoint

**Acceptance Criteria**:
- [ ] FastAPI server runs on localhost:8000
- [ ] Supabase connection successful
- [ ] Twilio credentials configured
- [ ] Health check endpoint returns 200

**Code Snippet**:
```python
# Add to requirements.txt
twilio==8.10.0
```

---

### Task 2: Database Schema Verification
**Priority**: P0 | **Estimated**: 1 hour | **Dependencies**: Task 1

**Subtasks**:
1. Verify all tables exist in Supabase
2. Confirm PostGIS extension enabled
3. Test spatial indexes
4. Verify evacuation_centres table exists
5. Run seed script for evacuation centers
6. Verify family_groups and family_members tables

**Acceptance Criteria**:
- [ ] All required tables exist
- [ ] PostGIS functions work (ST_DWithin, ST_Distance)
- [ ] Evacuation centers seeded with sample data
- [ ] Can query nearby evacuation centers
- [ ] Family tables ready

**Command**:
```bash
python backend_fastapi/scripts/seed_risk_map.py
```

---

### Task 3: Authentication System
**Priority**: P0 | **Estimated**: 2 hours | **Dependencies**: Task 2

**Subtasks**:
1. Verify existing auth endpoints
2. Add admin role to users table
3. Create admin authentication endpoint
4. Implement JWT token generation for admin
5. Create `get_current_admin` dependency

**Endpoints**:
- `POST /api/v1/admin/login`
- `GET /api/v1/admin/me`

**Acceptance Criteria**:
- [ ] Admin can login with credentials
- [ ] JWT token generated and validated
- [ ] Admin endpoints require admin role
- [ ] Regular users cannot access admin endpoints

---

## Phase 2: Personal Preparedness (Hours 6-11)

### Task 4: Personal Preparedness Checklist Endpoints
**Priority**: P0 | **Estimated**: 2 hours | **Dependencies**: Task 3

**Endpoints**:
- `POST /api/v1/preparedness/checklist`
- `GET /api/v1/preparedness/checklist`
- `PATCH /api/v1/preparedness/checklist/{item_id}/toggle`
- `GET /api/v1/preparedness/score`

**Subtasks**:
1. Create endpoint to add checklist item
2. Get user's checklist with categories
3. Toggle item completion status
4. Calculate overall preparedness score
5. Return status message based on score

**Acceptance Criteria**:
- [ ] User can add personal checklist items
- [ ] Items categorized (supplies, training, planning)
- [ ] Can toggle completion status
- [ ] Score calculated as (completed / total) * 100
- [ ] Status message: "Excellent" (80-100%), "Good" (60-79%), "Needs Improvement" (<60%)
- [ ] Returns within 400ms

---

### Task 5: Educational Content Endpoints
**Priority**: P1 | **Estimated**: 1.5 hours | **Dependencies**: Task 4

**Endpoints**:
- `GET /api/v1/preparedness/education`
- `GET /api/v1/preparedness/education/{topic_id}`
- `POST /api/v1/preparedness/education/{topic_id}/view`

**Subtasks**:
1. Create static educational content data
2. Endpoint to list all topics
3. Endpoint to get topic details with external links
4. Track viewed resources per user
5. Categorize by topic (before/during/after flood)

**Acceptance Criteria**:
- [ ] Returns list of educational topics
- [ ] Each topic has title, description, external links
- [ ] Supports both static content and external URLs
- [ ] Tracks which resources user has viewed
- [ ] Returns within 300ms

**Sample Data**:
```python
EDUCATIONAL_TOPICS = [
    {
        "id": "flood-escape",
        "title": "How to Escape During Floods",
        "description": "Learn the safest ways to evacuate during a flood",
        "category": "during_flood",
        "content": "Move to higher ground immediately...",
        "external_links": [
            {"title": "NADMA Flood Safety Guide", "url": "https://..."},
            {"title": "Flood Escape Video", "url": "https://youtube.com/..."}
        ]
    },
    # ... more topics
]
```

---

### Task 6: Evacuation Center Map Endpoint
**Priority**: P1 | **Estimated**: 1.5 hours | **Dependencies**: Task 2

**Endpoint**: `GET /api/v1/preparedness/evacuation-centers/nearby`

**Subtasks**:
1. Query evacuation centers within 20km
2. Calculate distance using Haversine
3. Sort by distance
4. Return with map coordinates
5. Use existing risk_zones.py functions

**Acceptance Criteria**:
- [ ] Returns centers within 20km
- [ ] Sorted by distance
- [ ] Includes name, address, capacity, phone, distance
- [ ] Returns coordinates for map display
- [ ] Returns within 500ms

---

## Phase 3: Family Safety (Hours 11-16)

### Task 7: Family Group Management Endpoints
**Priority**: P0 | **Estimated**: 2 hours | **Dependencies**: Task 3

**Endpoints**:
- `POST /api/v1/family/groups`
- `GET /api/v1/family/groups/my`
- `POST /api/v1/family/members`
- `GET /api/v1/family/members`
- `PATCH /api/v1/family/members/{member_id}`

**Subtasks**:
1. Create family group endpoint
2. Get user's family group
3. Add family member with phone validation
4. List family members
5. Update family member info

**Acceptance Criteria**:
- [ ] User can create one family group
- [ ] Can add multiple family members
- [ ] Phone numbers validated (E.164 format)
- [ ] Returns only user's own family group
- [ ] Returns within 400ms

---

### Task 8: Family Safety Status Endpoints
**Priority**: P0 | **Estimated**: 1.5 hours | **Dependencies**: Task 7

**Endpoints**:
- `PATCH /api/v1/family/members/{member_id}/status`
- `GET /api/v1/family/status`

**Subtasks**:
1. Update family member safety status
2. Support SAFE, DANGER, UNKNOWN statuses
3. Record timestamp of status change
4. Get all family members' current status
5. Add visual status indicators

**Acceptance Criteria**:
- [ ] Can update status to SAFE, DANGER, or UNKNOWN
- [ ] Timestamp recorded for each change
- [ ] Returns updated status within 300ms
- [ ] Only shows user's own family status
- [ ] Visual indicators: ✓ SAFE, ⚠️ DANGER, ⏳ UNKNOWN

---

### Task 9: Family Status Notification
**Priority**: P1 | **Estimated**: 1.5 hours | **Dependencies**: Task 8

**Subtasks**:
1. When status updated, notify other family members
2. Use existing notification system (FCM)
3. Include member name and new status
4. Handle notification failures gracefully

**Acceptance Criteria**:
- [ ] Family members notified when status changes
- [ ] Notification includes member name and status
- [ ] Works for both app and SMS status updates
- [ ] Logs notification delivery status

---

## Phase 4: Community Reports (Hours 16-21)

### Task 10: Report Submission Endpoint ⚡ CRITICAL
**Priority**: P0 | **Estimated**: 1.5 hours | **Dependencies**: Task 3

**Endpoint**: `POST /api/v1/reports/submit`

**Subtasks**:
1. Validate report data (type, location, description)
2. Create report record with pending status
3. Store vulnerable_person flag
4. Return report ID immediately
5. Test with all report types

**Acceptance Criteria**:
- [ ] Accepts flood, landslide, blocked_road, medical_emergency
- [ ] Validates coordinates
- [ ] Returns within 500ms
- [ ] Stores submitter user ID
- [ ] Vulnerable person flag supported

---

### Task 11: Report Retrieval Endpoints
**Priority**: P0 | **Estimated**: 1.5 hours | **Dependencies**: Task 10

**Endpoints**:
- `GET /api/v1/reports/nearby`
- `GET /api/v1/reports/{report_id}`

**Subtasks**:
1. Get nearby reports with radius filter
2. Calculate distance using Haversine
3. Get single report by ID
4. Support pagination
5. Filter by type and status

**Acceptance Criteria**:
- [ ] Returns reports within radius
- [ ] Sorted by distance
- [ ] Includes distance_km
- [ ] Filter by type and status
- [ ] Returns within 500ms

---

### Task 12: Vouch & Helpful Endpoints
**Priority**: P1 | **Estimated**: 1.5 hours | **Dependencies**: Task 11

**Endpoints**:
- `POST /api/v1/reports/{id}/vouch`
- `DELETE /api/v1/reports/{id}/vouch`
- `POST /api/v1/reports/{id}/helpful`
- `DELETE /api/v1/reports/{id}/helpful`

**Subtasks**:
1. Add vouch endpoint (community members vouch for reports they witness)
2. Remove vouch endpoint
3. Add helpful marking endpoint
4. Remove helpful marking endpoint
5. Prevent duplicates

**Acceptance Criteria**:
- [ ] Vouch count increments/decrements
- [ ] Helpful count increments/decrements
- [ ] Returns 409 on duplicate
- [ ] Returns within 300ms
- [ ] Includes current user's status
- [ ] Only community members can vouch (not verify)
- [ ] Vouch count helps admins identify legitimate reports

---

### Task 13: Report Lifecycle Management
**Priority**: P1 | **Estimated**: 1 hour | **Dependencies**: Task 12

**Endpoints**:
- `PATCH /api/v1/reports/{id}/resolve`
- `PATCH /api/v1/reports/{id}/reject`
- Background job: auto-expire old reports

**Subtasks**:
1. Resolve report endpoint (moderator only)
2. Reject report endpoint with reason
3. Create APScheduler job for auto-expiry
4. Test status transitions

**Acceptance Criteria**:
- [ ] Only moderators can resolve/reject
- [ ] Rejection requires reason
- [ ] Auto-expire after 7 days
- [ ] Status changes logged

---

## Phase 5: SMS Alerts with Reply (Hours 21-28)

### Task 14: Twilio SMS Service ⚡ CRITICAL
**Priority**: P0 | **Estimated**: 2 hours | **Dependencies**: Task 1

**File**: `app/services/twilio_service.py`

**Subtasks**:
1. Create Twilio client wrapper
2. Implement send_flood_alert method
3. Format message with reply instructions
4. Query nearest evacuation center
5. Handle delivery failures

**Acceptance Criteria**:
- [ ] Can send SMS via Twilio
- [ ] Message includes location, distance, shelter info
- [ ] Includes reply instructions (SAFE or DANGER)
- [ ] Logs delivery status
- [ ] Handles errors gracefully

**SMS Format**:
```
🚨 FLOOD ALERT

Location: Kampung Sungai Lui
Distance: 3.2 km from your home

Reply:
SAFE - I evacuated safely
DANGER - I need help

Nearest shelter: Dewan Komuniti (2.5km)
Phone: 019-234-5678
```

---

### Task 15: SMS Reply Webhook ⚡ CRITICAL
**Priority**: P0 | **Estimated**: 2.5 hours | **Dependencies**: Task 14

**Endpoint**: `POST /api/v1/sms/webhook`

**Subtasks**:
1. Create Twilio webhook endpoint
2. Parse incoming SMS (phone number, message body)
3. Identify user by phone number
4. Extract safety status (SAFE or DANGER)
5. Update family member status
6. Send confirmation SMS
7. Validate webhook signature

**Acceptance Criteria**:
- [ ] Receives Twilio webhook POST requests
- [ ] Identifies user by phone number
- [ ] Parses "SAFE" or "DANGER" (case-insensitive)
- [ ] Updates family member safety status
- [ ] Sends confirmation SMS
- [ ] Returns TwiML response within 5 seconds
- [ ] Validates webhook signature

**Code Snippet**:
```python
@router.post("/sms/webhook")
async def handle_sms_reply(
    From: str = Form(...),
    Body: str = Form(...)
):
    # Find user by phone
    user = find_user_by_phone(From)
    
    # Parse status
    status = parse_safety_status(Body)  # SAFE or DANGER
    
    # Update family member status
    update_family_member_status(user.id, status)
    
    # Send confirmation
    confirmation = f"Status updated to {status}. Your family has been notified."
    
    return Response(
        content=f'<?xml version="1.0" encoding="UTF-8"?><Response><Message>{confirmation}</Message></Response>',
        media_type="application/xml"
    )
```

---

### Task 16: Government Flood Warning Monitor
**Priority**: P0 | **Estimated**: 2 hours | **Dependencies**: Task 14

**File**: `app/services/met_malaysia.py`

**Subtasks**:
1. Create MetMalaysia API client
2. Fetch warnings endpoint
3. Parse and store in government_alerts table
4. Identify affected users
5. Trigger SMS notifications

**API**: `https://api.data.gov.my/weather/warning`

**Acceptance Criteria**:
- [ ] Fetches warnings every 5 minutes
- [ ] Stores warnings in database
- [ ] Identifies users within affected area
- [ ] Triggers SMS to affected users
- [ ] Logs fetch timestamp

---

### Task 17: SMS Alert Background Jobs
**Priority**: P0 | **Estimated**: 1.5 hours | **Dependencies**: Tasks 14, 15, 16

**File**: `app/scheduler.py`

**Subtasks**:
1. Set up APScheduler
2. Create job for MetMalaysia monitoring (every 5 min)
3. Create job for community flood report monitoring (every 2 min)
4. Create job for auto-expiring old reports (daily)
5. Add error handling and logging

**Acceptance Criteria**:
- [ ] Scheduler starts with FastAPI
- [ ] Jobs run on schedule
- [ ] Monitors government warnings
- [ ] Monitors validated flood reports
- [ ] Sends SMS to users within 10km
- [ ] No duplicate alerts within 1 hour
- [ ] Notifies family members when status updated via SMS

---

## Phase 6: Admin Website (Hours 28-33)

### Task 18: Admin API Endpoints
**Priority**: P1 | **Estimated**: 2 hours | **Dependencies**: Task 3

**Endpoints**:
- `GET /api/v1/admin/reports`
- `GET /api/v1/admin/reports/{id}`
- `POST /api/v1/admin/reports/{id}/approve`
- `POST /api/v1/admin/reports/{id}/reject`
- `POST /api/v1/admin/reports/{id}/resolve`
- `DELETE /api/v1/admin/reports/{id}`
- `GET /api/v1/admin/stats`

**Subtasks**:
1. List reports with filters (status, type, search)
2. Get single report details with vouch count
3. Approve report (change to validated) - ADMIN ONLY
4. Reject report with reason - ADMIN ONLY
5. Resolve report - ADMIN ONLY
6. Delete report
7. Get statistics

**Acceptance Criteria**:
- [ ] Requires admin authentication
- [ ] Supports pagination
- [ ] Filter by status and type
- [ ] Search by location/description
- [ ] Returns within 1 second
- [ ] Statistics include counts by type
- [ ] Displays vouch count to help identify legitimate reports
- [ ] Only admins can approve/validate reports

---

### Task 19: Admin Website Frontend
**Priority**: P1 | **Estimated**: 3 hours | **Dependencies**: Task 18

**Files**:
- `admin_website/index.html`
- `admin_website/login.html`
- `admin_website/css/admin.css`
- `admin_website/js/auth.js`
- `admin_website/js/reports.js`
- `admin_website/js/api.js`

**Subtasks**:
1. Create HTML layout with Tailwind CSS
2. Implement login page
3. Create reports table with filters
4. Add action buttons (approve, reject, resolve, delete)
5. Implement report details modal
6. Add pagination

**Acceptance Criteria**:
- [ ] Admin can login
- [ ] Reports displayed in table
- [ ] Can filter by status and type
- [ ] Can search reports
- [ ] Action buttons work
- [ ] Confirmation dialogs for destructive actions
- [ ] Responsive design

---

## Phase 7: Testing & Polish (Hours 33-38)

### Task 20: End-to-End Testing
**Priority**: P1 | **Estimated**: 3 hours | **Dependencies**: All previous tasks

**Test Scenarios**:
1. User creates preparedness checklist → score calculated
2. User adds family members → appears in roster
3. User submits report → appears in nearby feed
4. User vouches for report → vouch count increments
5. Admin approves report → status changes to validated
6. Flood report validated → SMS sent to nearby users
7. User replies "SAFE" to SMS → family status updated
8. User replies "DANGER" to SMS → flagged for assistance
9. Government warning detected → SMS sent to affected users
10. Family member updates status in app → others notified
11. Community member cannot verify report (only vouch)
12. Admin can see vouch count to identify legitimate reports

**Acceptance Criteria**:
- [ ] All scenarios pass
- [ ] No crashes or errors
- [ ] Performance meets requirements
- [ ] SMS delivery confirmed
- [ ] SMS replies processed correctly
- [ ] Family notifications work

---

### Task 21: Demo Data Preparation
**Priority**: P1 | **Estimated**: 1.5 hours | **Dependencies**: Task 20

**Subtasks**:
1. Create demo user accounts with families
2. Create sample preparedness checklists
3. Create sample reports (all types)
4. Create sample educational content
5. Seed evacuation centers
6. Prepare demo script

**Acceptance Criteria**:
- [ ] Demo data realistic
- [ ] Covers all features
- [ ] Can demonstrate full workflow
- [ ] Data geographically consistent
- [ ] Family groups set up

---

### Task 22: Documentation
**Priority**: P2 | **Estimated**: 0.5 hour | **Dependencies**: Task 21

**Documents to Update**:
1. README.md (setup instructions)
2. API documentation (update Swagger)
3. Twilio webhook setup guide
4. SMS reply format documentation

**Acceptance Criteria**:
- [ ] Clear setup instructions
- [ ] API endpoints documented
- [ ] Twilio setup explained
- [ ] SMS reply format documented

---

## Removed Tasks (Not in MVP)

The following tasks have been removed as they are out of scope:

❌ **Village/School Resilience Metrics**: Removed - using personal preparedness instead
❌ **Emergency Drill Scheduling**: Removed - drills mentioned only in educational content
❌ **Drill Participation Tracking**: Removed entirely
❌ **Student Roster Management**: Removed - using family roster instead
❌ **Resilience Metric History**: Removed - no village-level tracking
❌ **River Discharge Monitoring**: Removed - not needed
❌ **Telegram Scraper**: Removed - not needed
❌ **Confidence Scoring Algorithm**: Removed - not needed
❌ **Gemini Integration**: Removed - not needed
❌ **Telegram Bot**: Removed - using SMS instead
❌ **SCHARMS Flood Zones**: Removed - not needed

---

## Critical Path (Minimum Viable Demo)

If time is limited, focus on these tasks in order:

1. **Task 1**: Project setup (1h)
2. **Task 2**: Database verification (1h)
3. **Task 3**: Authentication (2h)
4. **Task 7**: Family group management (2h)
5. **Task 8**: Family safety status (1.5h)
6. **Task 10**: Report submission (1.5h)
7. **Task 11**: Report retrieval (1.5h)
8. **Task 14**: Twilio SMS service (2h)
9. **Task 15**: SMS reply webhook (2.5h)
10. **Task 16**: Government warning monitor (2h)
11. **Task 17**: SMS background jobs (1.5h)
12. **Task 18**: Admin API endpoints (2h)

**Total**: ~21.5 hours (core functionality)

---

## Daily Milestones

### Day 1 (8 hours):
- ✅ Backend foundation complete
- ✅ Personal preparedness endpoints working
- ✅ Family safety management working

### Day 2 (8 hours):
- ✅ Community reports complete
- ✅ SMS alerts with reply working
- ✅ Government warning monitoring active

### Day 3 (8 hours):
- ✅ Admin website complete
- ✅ End-to-end testing passed
- ✅ Demo data prepared

---

## Success Metrics

- [ ] Users can track personal preparedness with checklist
- [ ] Users can access educational content about floods
- [ ] Users can add family members and track their safety
- [ ] Family members can update status via app or SMS reply
- [ ] Users can submit and verify community reports
- [ ] Community members can vouch for reports they witness
- [ ] Only admins can officially verify/approve reports
- [ ] Vouch count helps admins identify legitimate reports
- [ ] Nearby reports displayed within 500ms
- [ ] SMS alerts sent within 2 minutes of flood detection
- [ ] SMS replies processed within 30 seconds
- [ ] Family members notified when status changes
- [ ] Admin can approve/reject reports via web interface
- [ ] Evacuation centers displayed on map
- [ ] No drill participation tracking
- [ ] No village/school-level metrics
