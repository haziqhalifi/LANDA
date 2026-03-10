# MVP Design: Disaster Resilience & Community Intelligence System

## Executive Summary

**Problem**: Rural communities face natural disasters but lack accessible early warning and preparedness systems. Current solutions require:
- Multiple government apps (user fatigue)
- Google Maps literacy (many can't read maps)
- No community-driven reporting
- No personal preparedness education or tracking

**Solution**: Community-focused disaster resilience system that:
- **Personal Preparedness**: Individual checklist tracking and educational content about flood safety
- **Family Safety Roster**: Track safety status of user's own family members during emergencies
- **Community Report Center**: Users report and verify incidents (flood, landslide, blocked road, medical emergency)
- **SMS Flood Alerts with Reply**: Twilio notifications when flood is detected near user's location, with SMS reply for safety status
- Works offline with local SQLite cache
- Uses simple icons + colors (no map reading required)

**Target Users**: Rural ASEAN communities (primary: Malaysia), individual users and their families, all ages

**MVP Scope**: Personal preparedness tracking, family safety monitoring, community reporting with verification, SMS flood alerts with reply via Twilio

---

## Core Features

### Feature 1: Personal Preparedness & Education

**Purpose**: Help individual users track their personal disaster preparedness and learn about flood safety

**Key Components**:

#### 1. Personal Preparedness Checklist
Individual user tracks their own preparedness tasks:
- ✅ Emergency Supply Kit (Completed)
- ✅ First Aid Training (Completed)
- ⚠️ Evacuation Plan (Pending)
- ⚠️ Emergency Contacts List (Pending)

Categories:
- Supplies (emergency kits, food, water, medical)
- Training (first aid, evacuation knowledge)
- Planning (evacuation routes, emergency contacts)

**Resilience Scorecard**:
- Overall score calculated from personal checklist completion
- Display: "85% READY" with visual indicator
- Green = Excellent (80-100%)
- Yellow = Needs Work (50-79%)
- Red = Critical (<50%)

#### 2. Educational Content
Educational material about flood safety with external links:
- **How to Escape During Floods**: Step-by-step evacuation procedures
  - "Read More" links to external websites and videos
- **Emergency Basics**: What to do before, during, and after floods
  - Links to government resources (NADMA, MetMalaysia)
- **Safety Tips**: Flood safety best practices
  - Video tutorials and infographics
- **Drill Information**: What emergency drills are and why they're important
  - Links to drill procedure guides (educational only, no scheduling)

**Content Structure**:
- Topic title and description
- Static content summary
- External resource links (websites, videos, PDFs)
- "Read More" buttons that open external sources
- Track which resources user has viewed

#### 3. Evacuation Center Map
- Display nearest evacuation centers on a map
- Show distance from user's current location
- Include center name, address, capacity, contact phone
- Sort by distance (nearest first)
- Query centers within 20km radius

**UI Reference**: Personal preparedness dashboard with checklist, educational content, and evacuation map

---

### Feature 2: Family Safety Roster

**Purpose**: Enable users to monitor their own family members' safety status during emergencies

**Key Components**:

#### 1. Family Group Management
- User creates one family group
- Add family members with:
  - Name
  - Phone number (for SMS notifications)
  - Relationship (e.g., "Mother", "Brother", "Daughter")
- Edit family member information
- Remove family members

#### 2. Safety Status Tracking
During emergencies, family members show safety status:
- ✓ **SAFE**: Family member confirmed safe
- ⚠️ **DANGER**: Family member needs help
- ⏳ **UNKNOWN**: Status not yet updated

**Status Update Methods**:
1. **Via App**: Family member opens app and updates their status
2. **Via SMS Reply**: Family member replies to flood alert SMS with "SAFE" or "DANGER"

**SMS Reply Flow**:
1. Flood alert sent to all users in affected area
2. User receives SMS: "Reply SAFE if evacuated safely, or DANGER if you need help"
3. User replies with "SAFE" or "DANGER"
4. System updates user's safety status
5. All family members in user's family group are notified

#### 3. Family Safety Dashboard
- List all family members with current safety status
- Visual indicators: ✓ SAFE (green), ⚠️ DANGER (red), ⏳ UNKNOWN (gray)
- Last updated timestamp for each member
- Notification when family member updates status
- Only shows user's own family members (not other users' families)

**UI Reference**: Family roster screen showing family members with safety status indicators

---

### Feature 3: Community Report Center

**Purpose**: Enable community-driven disaster reporting and verification

**Report Types**:
1. 🌊 **Water Rising / Flood**
2. 🏔️ **Landslide**
3. 🚧 **Road Blocked**
4. 🏥 **Medical Emergency**

**Key Components**:

#### 1. Submit Report Screen
- Large icon buttons for each incident type
- Description text field
- Location input (auto-detect or manual entry)
- "Vulnerable Person Help" toggle (priority rescue alert)
- "Send Incident Report" button
- Current location display (e.g., "Kampung Melayu, Jakarta")

**UI Reference**: See screenshot 2 (Submit Report screen)

#### 2. Verified Nearby Reports Feed
Live feed showing community reports:

Example reports:
- **Bridge Overflow** - 2H AGO
  - "Village Sector 4. Water level rising rapidly. Avoid river crossing."
  - ✓ Admin Verified badge (only admins can verify)
  - 👥 12 Vouches (community members vouched for this)
  - 📍 Location
  
- **Tree Down on Route 12** - 15M AGO
  - "Large palm tree blocking motorbike path. Locals working on it."
  - 👥 5 Vouches
  - 👍 8 Helpful

Features:
- Sort by distance (nearest first)
- Filter by report type
- Show time elapsed since report
- Display admin verification status
- Display vouch count (community support)
- Show helpful count

**UI Reference**: See screenshot 3 (Community Intelligence screen)

#### 3. Verification System
- Only admins can officially verify/approve reports (change status to validated)
- Community members can vouch for reports they personally witness
- Community members can mark reports as "Helpful"
- Vouch count displayed on each report
- Vouch count helps admins identify legitimate reports
- Prevent duplicate vouches (one per user per report)

**Vouch vs Verify**:
- **Vouch**: Community members say "I saw this too" or "This is real"
- **Verify**: Only admins can officially approve and change status to validated
- High vouch count signals to admins that a report is likely legitimate

#### 4. Report Lifecycle
Status flow:
- **Pending**: Just submitted, awaiting admin review
- **Validated**: Admin has officially verified and approved
- **Resolved**: Incident cleared/resolved
- **Rejected**: False report or spam (admin decision)
- **Expired**: Auto-expire after 7 days if unresolved

**Community Role**: Community members vouch for reports to help admins identify legitimate ones
**Admin Role**: Only admins can officially verify/approve reports (change status to validated)

---

### Feature 4: SMS Flood Alerts with Reply (Twilio)

**Purpose**: Notify users via SMS when flood is detected near their location and process their safety status replies

**How It Works**:

#### 1. Flood Detection
System monitors:
- Government flood warnings (MetMalaysia API)
- Community flood reports (from Feature 3)
- User's home location proximity to flood incidents

#### 2. SMS Notification via Twilio
Sent automatically when flood detected within 10km of user's home:

```
🚨 FLOOD ALERT

Location: Kampung Sungai Lui, Hulu Langat
Distance: 3.2 km from your home

Action: Move to higher ground immediately

Reply:
SAFE - I evacuated safely
DANGER - I need help

Nearest shelter: Dewan Orang Ramai Kampung Baru (500m)
Phone: 019-234-5678

Stay safe!
```

#### 3. SMS Reply Processing
**User replies to SMS**:
- Reply "SAFE" → System updates user's safety status to SAFE
- Reply "DANGER" → System updates user's safety status to DANGER and flags for priority assistance
- Case-insensitive (safe, SAFE, Safe all work)

**After processing reply**:
1. System updates user's family member record with new safety status
2. All family members in user's family group receive notification
3. User receives confirmation SMS: "Status updated to SAFE. Your family has been notified."

**Twilio Webhook**:
- Endpoint: `POST /api/v1/sms/webhook`
- Receives incoming SMS from Twilio
- Parses phone number and message body
- Identifies user by phone number
- Extracts safety status (SAFE or DANGER)
- Updates family member status
- Returns TwiML response within 5 seconds

#### 4. User Registration
- Users register with phone number and home address
- System geocodes address for proximity checks
- SMS sent automatically when flood conditions met
- No app needed to receive alerts (SMS works on any phone)

#### 5. Twilio Integration
- Use Twilio API for SMS delivery
- Support international phone numbers (E.164 format)
- Track delivery status
- Handle failures with retry logic
- Validate webhook signature to prevent spoofing

---

### Feature 5: Admin Verification Website

**Purpose**: Web-based admin panel to verify, approve, or reject community reports

**Key Components**:

#### 1. Admin Dashboard
- Simple web interface (HTML + CSS + JavaScript)
- Login with admin credentials
- Overview of pending reports

#### 2. Report Management Table
Display all reports with columns:
- **ID**: Short report ID (first 8 chars)
- **Type**: Icon + label (🌊 Flood, 🏔️ Landslide, 🚧 Road Blocked, 🏥 Medical)
- **Location**: Location name
- **Description**: Report text (truncated)
- **Submitted**: Time ago (e.g., "2 hours ago")
- **Status**: Badge (Pending, Validated, Rejected, Resolved)
- **Vouches**: Count (e.g., "12 vouches" - helps identify legitimate reports)
- **Actions**: Buttons (Approve, Reject, Resolve, Delete)

**Note**: Vouch count helps admins prioritize which reports to review first

#### 3. Report Actions
- **Approve**: Change status to "validated" (admin only)
- **Reject**: Prompt for reason, change status to "rejected" (admin only)
- **Resolve**: Mark incident as resolved (admin only)
- **Delete**: Permanently remove report (with confirmation)

**Admin Authority**: Only admins can change report status. Community members can only vouch.

#### 4. Filter & Search
- Filter by status (All, Pending, Validated, Rejected, Resolved)
- Filter by type (All, Flood, Landslide, Road Blocked, Medical)
- Search by location or description
- Sort by date (newest first)

#### 5. Report Details Modal
Click on report to view full details:
- Complete description
- Exact location (lat/lon)
- Submitter info (user ID, phone)
- Timestamp
- Vouch list (users who vouched for this report)
- Helpful count
- Map view (optional)

**Vouch List**: Shows which community members vouched, helping admin assess legitimacy

**Tech Stack**:
- Frontend: HTML, CSS, JavaScript (vanilla or simple framework)
- Backend: FastAPI endpoints (already exist)
- Authentication: Simple JWT token or session-based
- Styling: Tailwind CSS or Bootstrap for quick UI

**UI Mockup**:
```
┌─────────────────────────────────────────────────────────────┐
│  Admin Panel - Report Verification                    Logout │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Filters: [All Status ▼] [All Types ▼] [Search...      🔍]  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ ID      │ Type  │ Location      │ Status   │ Actions  │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │ a3f2b1c │ 🌊    │ Kampung Lui   │ Pending  │ ✓ ✗ ✔ 🗑 │  │
│  │ 2h ago  │ Flood │ Water rising  │ 12 vouch │          │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │ 9d4e5f6 │ 🚧    │ Route 12      │ Validated│ ✔ 🗑     │  │
│  │ 15m ago │ Road  │ Tree blocking │ 8 vouch  │          │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │ 7c8b9a0 │ 🏥    │ Village Hall  │ Resolved │ 🗑       │  │
│  │ 1d ago  │ Medical│ Emergency    │ 3 vouch  │          │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  Showing 3 of 45 reports                    [1] 2 3 4 5 >   │
└─────────────────────────────────────────────────────────────┘

Legend:
✓ = Approve (Admin only)
✗ = Reject (Admin only)
✔ = Resolve (Admin only)
🗑 = Delete
```

---

## Removed Features (Not in MVP)

The following features are **NOT** included in this refocused MVP:

❌ Telegram bot integration for family check-ins
❌ Telegram channel scraping for social media data
❌ AI-powered confidence scoring with multiple data sources
❌ Gemini AI explanation generation
❌ River discharge monitoring (Open-Meteo)
❌ SCHARMS flood zone data integration
❌ Complex multi-source validation
❌ Agency hierarchy and contradiction resolution
❌ Stakeholder role-based notifications
❌ Background scraping jobs for social media
❌ School/village-level preparedness tracking
❌ Student roster management
❌ School coordinator or village head roles
❌ Emergency drill scheduling and participation tracking
❌ Resilience metrics per village/school
❌ Village or school entity management
❌ Multi-level organizational hierarchy

**Focus**: Personal preparedness with educational content, family safety monitoring, community reporting with verification, and SMS flood alerts with reply.

---

## Database Schema (Simplified)

### Core Tables

```sql
-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) NOT NULL UNIQUE,
    home_address TEXT NOT NULL,
    home_location GEOMETRY(Point, 4326) NOT NULL,
    language VARCHAR(10) DEFAULT 'ms',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_location ON users USING GIST(home_location);

-- Personal Preparedness Checklist
CREATE TABLE preparedness_checklist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_name TEXT NOT NULL,
    category VARCHAR(50) DEFAULT 'general',
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_checklist_user ON preparedness_checklist(user_id);

-- Educational Content (static or seeded data)
CREATE TABLE educational_content (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_title TEXT NOT NULL,
    topic_description TEXT,
    category VARCHAR(50) NOT NULL,
    content TEXT,
    external_links JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Educational Content Views (tracking)
CREATE TABLE user_content_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_id UUID NOT NULL REFERENCES educational_content(id) ON DELETE CASCADE,
    viewed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, content_id)
);

-- Family Groups
CREATE TABLE family_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    leader_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    group_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(leader_id)
);

-- Family Members
CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    relationship VARCHAR(100),
    safety_status VARCHAR(20) DEFAULT 'UNKNOWN',
    status_updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_family_members_group ON family_members(family_group_id);
CREATE INDEX idx_family_members_phone ON family_members(phone_number);

-- Community Reports
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    report_type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    location_name TEXT,
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    vulnerable_person BOOLEAN DEFAULT FALSE,
    vouch_count INTEGER DEFAULT 0,
    helpful_count INTEGER DEFAULT 0,
    resolved_by UUID REFERENCES users(id),
    resolution_reason TEXT,
    resolved_at TIMESTAMPTZ,
    description_updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reports_location ON reports USING GIST(
    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
);
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_type ON reports(report_type);

-- Report Vouches (community members vouch for reports they witness)
CREATE TABLE report_vouches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(report_id, user_id)
);

-- Report Helpful
CREATE TABLE report_helpful (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(report_id, user_id)
);

-- Government Alerts (for SMS notifications)
CREATE TABLE government_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source VARCHAR(50) NOT NULL,
    area TEXT NOT NULL,
    latitude FLOAT,
    longitude FLOAT,
    severity VARCHAR(20),
    raw_data JSONB,
    fetched_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_gov_alerts_location ON government_alerts USING GIST(
    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
);

-- Evacuation Centers (already exists in database)
-- Used for displaying nearest shelters in SMS alerts and on map
```

**Removed Tables** (not in MVP):
- ❌ villages
- ❌ students
- ❌ drills
- ❌ drill_participants
- ❌ school_checklist
- ❌ resilience_metrics
- ❌ resilience_metric_history
- ❌ family_contacts (replaced by family_members)

---

## API Endpoints

### 1. Personal Preparedness

```python
# Get user's personal preparedness checklist
GET /api/v1/preparedness/checklist

# Add checklist item
POST /api/v1/preparedness/checklist
Body: {
    "item_name": "Emergency supply kit",
    "category": "supplies"
}

# Toggle checklist item completion
PATCH /api/v1/preparedness/checklist/{item_id}/toggle
Body: {
    "completed": true
}

# Get preparedness score
GET /api/v1/preparedness/score
Response: {
    "score": 85.0,
    "status": "Excellent Preparedness",
    "completed_items": 17,
    "total_items": 20
}

# Get educational content
GET /api/v1/preparedness/education
Response: {
    "topics": [
        {
            "id": "flood-escape",
            "title": "How to Escape During Floods",
            "description": "Learn the safest ways to evacuate",
            "category": "during_flood",
            "content": "Move to higher ground immediately...",
            "external_links": [
                {"title": "NADMA Guide", "url": "https://..."},
                {"title": "Video Tutorial", "url": "https://youtube.com/..."}
            ]
        }
    ]
}

# Get specific educational topic
GET /api/v1/preparedness/education/{topic_id}

# Mark educational content as viewed
POST /api/v1/preparedness/education/{topic_id}/view

# Get nearby evacuation centers
GET /api/v1/preparedness/evacuation-centers/nearby?latitude=3.1390&longitude=101.6869&radius_km=20
Response: {
    "centers": [
        {
            "id": "uuid",
            "name": "Dewan Orang Ramai Kampung Baru",
            "address": "Jalan Kampung Baru",
            "capacity": 500,
            "contact_phone": "019-234-5678",
            "distance_km": 2.5,
            "latitude": 3.1420,
            "longitude": 101.6900
        }
    ]
}
```

### 2. Family Safety

```python
# Create family group
POST /api/v1/family/groups
Body: {
    "group_name": "My Family"
}

# Get user's family group
GET /api/v1/family/groups/my
Response: {
    "id": "uuid",
    "group_name": "My Family",
    "leader_id": "uuid",
    "members": [...]
}

# Add family member
POST /api/v1/family/members
Body: {
    "name": "Ahmad bin Ali",
    "phone_number": "+60123456789",
    "relationship": "Father"
}

# Get all family members
GET /api/v1/family/members
Response: {
    "members": [
        {
            "id": "uuid",
            "name": "Ahmad bin Ali",
            "phone_number": "+60123456789",
            "relationship": "Father",
            "safety_status": "SAFE",
            "status_updated_at": "2024-03-10T10:30:00Z"
        }
    ]
}

# Update family member info
PATCH /api/v1/family/members/{member_id}
Body: {
    "name": "Ahmad bin Ali",
    "phone_number": "+60123456789",
    "relationship": "Father"
}

# Update family member safety status
PATCH /api/v1/family/members/{member_id}/status
Body: {
    "safety_status": "SAFE"
}

# Get family safety status overview
GET /api/v1/family/status
Response: {
    "total_members": 4,
    "safe": 3,
    "danger": 0,
    "unknown": 1,
    "members": [...]
}
```

### 3. Community Reports

```python
# Submit report
POST /api/v1/reports/submit
Body: {
    "report_type": "flood",
    "description": "Water rising rapidly near bridge",
    "location_name": "Kampung Sungai Lui",
    "latitude": 3.1390,
    "longitude": 101.6869,
    "vulnerable_person": false
}

# Get nearby reports
GET /api/v1/reports/nearby?latitude=3.1390&longitude=101.6869&radius_km=10&report_type=flood

# Get single report
GET /api/v1/reports/{report_id}

# Vouch for report (community members only)
POST /api/v1/reports/{report_id}/vouch

# Remove vouch
DELETE /api/v1/reports/{report_id}/vouch

# Mark as helpful
POST /api/v1/reports/{report_id}/helpful

# Remove helpful
DELETE /api/v1/reports/{report_id}/helpful

# Resolve report (admin only)
PATCH /api/v1/reports/{report_id}/resolve

# Reject report (admin only)
PATCH /api/v1/reports/{report_id}/reject
Body: {
    "reason": "False alarm"
}
```

### 4. SMS Alerts with Reply

```python
# Register user (includes phone for SMS)
POST /api/v1/auth/register
Body: {
    "phone": "+60123456789",
    "home_address": "Kampung Sungai Lui, Hulu Langat",
    "language": "ms"
}

# Twilio webhook for SMS replies
POST /api/v1/sms/webhook
Body (form-encoded from Twilio):
    From: "+60123456789"
    Body: "SAFE"
Response (TwiML):
    <?xml version="1.0" encoding="UTF-8"?>
    <Response>
        <Message>Status updated to SAFE. Your family has been notified.</Message>
    </Response>

# Background job checks for floods near users
# Sends SMS via Twilio automatically
# Processes SMS replies and updates family member status
```

### 5. Admin Verification Website

```python
# Admin login
POST /api/v1/admin/login
Body: {
    "username": "admin",
    "password": "secure_password"
}
Response: {
    "access_token": "jwt_token",
    "token_type": "bearer"
}

# Get all reports (with filters)
GET /api/v1/admin/reports?status=pending&type=flood&search=kampung&limit=20&offset=0
Response: {
    "reports": [...],
    "total": 45,
    "page": 1,
    "pages": 3
}

# Get single report details (includes vouch list)
GET /api/v1/admin/reports/{report_id}

# Approve report (change to validated) - ADMIN ONLY
POST /api/v1/admin/reports/{report_id}/approve

# Reject report - ADMIN ONLY
POST /api/v1/admin/reports/{report_id}/reject
Body: {
    "reason": "False alarm - no evidence"
}

# Resolve report - ADMIN ONLY
POST /api/v1/admin/reports/{report_id}/resolve

# Delete report
DELETE /api/v1/admin/reports/{report_id}

# Get report statistics
GET /api/v1/admin/stats
Response: {
    "total_reports": 145,
    "pending": 12,
    "validated": 98,
    "rejected": 20,
    "resolved": 15,
    "by_type": {
        "flood": 65,
        "landslide": 30,
        "blocked_road": 35,
        "medical_emergency": 15
    }
}
```

---

## Background Jobs (APScheduler)

```python
from apscheduler.schedulers.asyncio import AsyncIOScheduler

scheduler = AsyncIOScheduler()

@scheduler.scheduled_job('interval', minutes=5)
async def check_government_flood_warnings():
    """
    Fetch MetMalaysia flood warnings.
    Send SMS to affected users.
    """
    response = await httpx.get('https://api.data.gov.my/weather/warning')
    warnings = response.json()
    
    for warning in warnings:
        if 'flood' in warning['type'].lower():
            # Find users within affected area
            affected_users = find_users_near_warning(warning)
            
            # Send SMS via Twilio
            for user in affected_users:
                await send_flood_sms(user.phone, warning)

@scheduler.scheduled_job('interval', minutes=2)
async def check_community_flood_reports():
    """
    Check for validated flood reports.
    Send SMS to nearby users.
    """
    flood_reports = db.query(Report).filter_by(
        report_type='flood',
        status='validated'
    ).all()
    
    for report in flood_reports:
        # Find users within 10km
        nearby_users = find_users_near_report(report, radius_km=10)
        
        # Send SMS
        for user in nearby_users:
            await send_flood_sms(user.phone, report)

@scheduler.scheduled_job('cron', hour=0)  # Daily at midnight
async def expire_old_reports():
    """
    Auto-expire reports older than 7 days.
    """
    cutoff = datetime.now() - timedelta(days=7)
    db.query(Report).filter(
        Report.status.in_(['pending', 'validated']),
        Report.created_at < cutoff
    ).update({'status': 'expired'})
    db.commit()

scheduler.start()
```

---

## Twilio SMS Integration

```python
from twilio.rest import Client

class TwilioService:
    def __init__(self):
        self.client = Client(
            os.getenv('TWILIO_ACCOUNT_SID'),
            os.getenv('TWILIO_AUTH_TOKEN')
        )
        self.from_number = os.getenv('TWILIO_PHONE_NUMBER')
    
    async def send_flood_alert(self, to_phone: str, location: str, distance_km: float, nearest_shelter: dict):
        """
        Send flood alert SMS with reply instructions.
        """
        message = f"""🚨 FLOOD ALERT

Location: {location}
Distance: {distance_km} km from your home

Action: Move to higher ground immediately

Reply:
SAFE - I evacuated safely
DANGER - I need help

Nearest shelter: {nearest_shelter['name']} ({nearest_shelter['distance_km']}km)
Phone: {nearest_shelter['contact_phone']}

Stay safe!"""
        
        try:
            result = self.client.messages.create(
                body=message,
                from_=self.from_number,
                to=to_phone
            )
            logger.info(f"SMS sent to {to_phone}: {result.sid}")
            return result.sid
        except Exception as e:
            logger.error(f"Failed to send SMS to {to_phone}: {e}")
            return None
    
    async def process_sms_reply(self, from_phone: str, message_body: str):
        """
        Process SMS reply and update family member safety status.
        """
        # Find user by phone number
        user = find_user_by_phone(from_phone)
        if not user:
            return "User not registered"
        
        # Parse safety status
        status = parse_safety_status(message_body)  # Returns "SAFE" or "DANGER"
        if not status:
            return "Invalid reply. Please reply SAFE or DANGER"
        
        # Update family member status
        update_family_member_status(user.id, status)
        
        # Notify family members
        notify_family_members(user.id, status)
        
        return f"Status updated to {status}. Your family has been notified."
```

---

## Admin Website Implementation

### File Structure
```
admin_website/
├── index.html              # Main admin dashboard
├── login.html              # Admin login page
├── css/
│   └── admin.css          # Styling
├── js/
│   ├── auth.js            # Authentication logic
│   ├── reports.js         # Report management
│   └── api.js             # API client
└── README.md              # Setup instructions
```

### Sample HTML (index.html)
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Panel - Report Verification</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
</head>
<body class="bg-gray-100">
    <nav class="bg-white shadow-lg">
        <div class="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
            <h1 class="text-2xl font-bold text-gray-800">Report Verification Admin</h1>
            <button id="logoutBtn" class="bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600">
                Logout
            </button>
        </div>
    </nav>

    <div class="max-w-7xl mx-auto px-4 py-8">
        <!-- Filters -->
        <div class="bg-white rounded-lg shadow p-4 mb-6 flex gap-4">
            <select id="statusFilter" class="border rounded px-3 py-2">
                <option value="">All Status</option>
                <option value="pending">Pending</option>
                <option value="validated">Validated</option>
                <option value="rejected">Rejected</option>
                <option value="resolved">Resolved</option>
            </select>
            
            <select id="typeFilter" class="border rounded px-3 py-2">
                <option value="">All Types</option>
                <option value="flood">🌊 Flood</option>
                <option value="landslide">🏔️ Landslide</option>
                <option value="blocked_road">🚧 Road Blocked</option>
                <option value="medical_emergency">🏥 Medical</option>
            </select>
            
            <input type="text" id="searchInput" placeholder="Search location or description..." 
                   class="border rounded px-3 py-2 flex-1">
            
            <button id="searchBtn" class="bg-blue-500 text-white px-6 py-2 rounded hover:bg-blue-600">
                Search
            </button>
        </div>

        <!-- Reports Table -->
        <div class="bg-white rounded-lg shadow overflow-hidden">
            <table class="min-w-full">
                <thead class="bg-gray-50">
                    <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Location</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Description</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Verifications</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                    </tr>
                </thead>
                <tbody id="reportsTableBody" class="bg-white divide-y divide-gray-200">
                    <!-- Reports will be loaded here via JavaScript -->
                </tbody>
            </table>
        </div>

        <!-- Pagination -->
        <div id="pagination" class="mt-4 flex justify-center gap-2">
            <!-- Pagination buttons will be loaded here -->
        </div>
    </div>

    <!-- Report Details Modal -->
    <div id="reportModal" class="hidden fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
        <div class="bg-white rounded-lg p-6 max-w-2xl w-full mx-4">
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-2xl font-bold">Report Details</h2>
                <button id="closeModal" class="text-gray-500 hover:text-gray-700 text-2xl">&times;</button>
            </div>
            <div id="modalContent">
                <!-- Report details will be loaded here -->
            </div>
        </div>
    </div>

    <script src="js/api.js"></script>
    <script src="js/auth.js"></script>
    <script src="js/reports.js"></script>
</body>
</html>
```

### Sample JavaScript (reports.js)
```javascript
// Load reports from API
async function loadReports(filters = {}) {
    const token = localStorage.getItem('admin_token');
    const params = new URLSearchParams(filters);
    
    try {
        const response = await fetch(`/api/v1/admin/reports?${params}`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        
        const data = await response.json();
        renderReports(data.reports);
        renderPagination(data.page, data.pages);
    } catch (error) {
        console.error('Failed to load reports:', error);
        alert('Failed to load reports');
    }
}

// Render reports in table
function renderReports(reports) {
    const tbody = document.getElementById('reportsTableBody');
    tbody.innerHTML = '';
    
    reports.forEach(report => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td class="px-6 py-4 text-sm text-gray-900">${report.id.substring(0, 8)}</td>
            <td class="px-6 py-4 text-sm">${getTypeIcon(report.report_type)}</td>
            <td class="px-6 py-4 text-sm text-gray-900">${report.location_name}</td>
            <td class="px-6 py-4 text-sm text-gray-500">${truncate(report.description, 50)}</td>
            <td class="px-6 py-4">
                <span class="px-2 py-1 text-xs rounded ${getStatusColor(report.status)}">
                    ${report.status}
                </span>
            </td>
            <td class="px-6 py-4 text-sm text-gray-900">${report.verification_count}</td>
            <td class="px-6 py-4 text-sm space-x-2">
                ${report.status === 'pending' ? `
                    <button onclick="approveReport('${report.id}')" 
                            class="text-green-600 hover:text-green-800">✓</button>
                    <button onclick="rejectReport('${report.id}')" 
                            class="text-red-600 hover:text-red-800">✗</button>
                ` : ''}
                ${report.status === 'validated' ? `
                    <button onclick="resolveReport('${report.id}')" 
                            class="text-blue-600 hover:text-blue-800">✔</button>
                ` : ''}
                <button onclick="deleteReport('${report.id}')" 
                        class="text-gray-600 hover:text-gray-800">🗑</button>
                <button onclick="viewReport('${report.id}')" 
                        class="text-blue-600 hover:text-blue-800">👁</button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// Approve report
async function approveReport(reportId) {
    if (!confirm('Approve this report?')) return;
    
    const token = localStorage.getItem('admin_token');
    try {
        await fetch(`/api/v1/admin/reports/${reportId}/approve`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        loadReports();
    } catch (error) {
        alert('Failed to approve report');
    }
}

// Reject report
async function rejectReport(reportId) {
    const reason = prompt('Enter rejection reason:');
    if (!reason) return;
    
    const token = localStorage.getItem('admin_token');
    try {
        await fetch(`/api/v1/admin/reports/${reportId}/reject`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ reason })
        });
        loadReports();
    } catch (error) {
        alert('Failed to reject report');
    }
}

// Helper functions
function getTypeIcon(type) {
    const icons = {
        'flood': '🌊 Flood',
        'landslide': '🏔️ Landslide',
        'blocked_road': '🚧 Road',
        'medical_emergency': '🏥 Medical'
    };
    return icons[type] || type;
}

function getStatusColor(status) {
    const colors = {
        'pending': 'bg-yellow-100 text-yellow-800',
        'validated': 'bg-green-100 text-green-800',
        'rejected': 'bg-red-100 text-red-800',
        'resolved': 'bg-blue-100 text-blue-800'
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
}

function truncate(text, length) {
    return text.length > length ? text.substring(0, length) + '...' : text;
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadReports();
    
    // Event listeners
    document.getElementById('searchBtn').addEventListener('click', () => {
        const filters = {
            status: document.getElementById('statusFilter').value,
            type: document.getElementById('typeFilter').value,
            search: document.getElementById('searchInput').value
        };
        loadReports(filters);
    });
});
```

---

## Mobile App (Flutter) - Key Screens

### 1. Personal Preparedness Screen
- Personal preparedness checklist with completion status
- Overall resilience score (e.g., "85% READY")
- Educational content topics with "Read More" links
- Evacuation center map showing nearest shelters

### 2. Family Safety Roster Screen
- List of family members with safety status
- Visual indicators: ✓ SAFE, ⚠️ DANGER, ⏳ UNKNOWN
- Last updated timestamp for each member
- Button to update own safety status
- Notifications when family member updates status

### 3. Submit Report Screen
- 4 large icon buttons (flood, landslide, blocked road, medical)
- Description text field
- Location auto-detect
- Vulnerable person toggle
- Submit button

### 4. Community Intelligence Screen
- List of verified nearby reports
- Filter by report type
- Sort by distance
- Vouch and helpful buttons (community members can vouch, only admins can verify)
- Live updates

---

## Implementation Priority

### Phase 1: Core Backend (6 hours)
1. Database schema setup
2. User registration with phone + address
3. Authentication system with admin role
4. Community report submission
5. Report verification system
6. Nearby reports query (PostGIS)

### Phase 2: Personal Preparedness (5 hours)
1. Personal preparedness checklist endpoints
2. Educational content management
3. Evacuation center proximity queries
4. Preparedness score calculation

### Phase 3: Family Safety (5 hours)
1. Family group management
2. Family member CRUD operations
3. Safety status tracking
4. Family status notifications

### Phase 4: SMS Alerts with Reply (7 hours)
1. Twilio integration
2. SMS reply webhook endpoint
3. Government API monitoring
4. Proximity detection
5. SMS notification sending
6. Background jobs (APScheduler)
7. Family notification on SMS reply

### Phase 5: Admin Website (6 hours)
1. HTML/CSS layout
2. Authentication (login/logout)
3. Report table with filters
4. Action buttons (approve/reject/resolve/delete)
5. Report details modal

### Phase 6: Mobile App (12 hours)
1. Flutter project setup
2. Personal preparedness UI
3. Family safety roster UI
4. Report submission UI
5. Nearby reports feed

### Phase 7: Testing & Polish (4 hours)
1. End-to-end testing
2. Demo data preparation
3. Documentation
4. Deployment

**Total**: ~45 hours

---

## Success Metrics

- [ ] Users can track personal preparedness with individual checklist
- [ ] Users can access educational content about flood safety with external links
- [ ] Users can view nearest evacuation centers on a map
- [ ] Users can create family groups and add family members
- [ ] Family members can update safety status via app or SMS reply
- [ ] Family members receive notifications when status changes
- [ ] Users can submit community reports
- [ ] Community members can vouch for reports they witness
- [ ] Only admins can officially verify/approve reports
- [ ] Vouch count helps admins identify legitimate reports
- [ ] Nearby reports displayed within 500ms
- [ ] SMS alerts sent within 2 minutes of flood detection
- [ ] SMS replies processed within 30 seconds
- [ ] Family members notified when user replies to SMS
- [ ] Admin can approve/reject reports via web interface
- [ ] Admin website loads reports within 1 second
- [ ] No school/village-level tracking
- [ ] No drill scheduling or participation tracking
- [ ] No student roster (only family roster)

---

## Next Steps

1. Review this refocused design
2. Confirm scope with team
3. Set up development environment
4. Begin Phase 1 implementation (Core Backend)
5. Test with real users in pilot community
