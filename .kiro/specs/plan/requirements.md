# Requirements Document

## Introduction

This document specifies the backend requirements for the Disaster Resilience AI system focusing on three core features: Personal Preparedness & Family Safety, Community Intelligence Network, and SMS Flood Alerts with Reply. These features enable community-driven disaster reporting, verification, personal preparedness tracking, family safety monitoring, and automated SMS notifications with response handling through a FastAPI backend with Supabase database storage.

The Community Intelligence Network allows users to submit and verify disaster-related reports (floods, landslides, blocked roads, medical emergencies), while the Personal Preparedness system helps individuals track their readiness and provides educational content. The Family Safety Roster allows users to monitor their family members' safety status during emergencies. The SMS Alert system notifies users via Twilio when floods are detected and processes their safety status replies.

## Glossary

- **Report_Service**: Backend service managing community disaster reports
- **Verification_Service**: Backend service handling community verification of reports
- **Preparedness_Service**: Backend service managing individual preparedness checklists and educational content
- **Family_Service**: Backend service managing family groups and safety status
- **SMS_Service**: Backend service sending flood alerts via Twilio and processing replies
- **Admin_Service**: Backend service for admin verification website
- **Report**: A community-submitted incident record (flood, landslide, blocked road, medical emergency)
- **Verification**: A community member's confirmation that a report is accurate
- **Preparedness_Checklist**: Individual user's personal disaster preparedness tasks
- **Family_Group**: A user's family members for safety tracking
- **Safety_Status**: The current status of a family member (SAFE, DANGER, UNKNOWN)
- **Helpful_Count**: The number of users who marked a report as helpful
- **Report_Type**: Category of incident (flood, landslide, blocked_road, medical_emergency)
- **Educational_Content**: Static content and external links about flood safety

## Requirements

### Requirement 1: Community Report Submission

**User Story:** As a community member, I want to submit disaster reports through quick buttons, so that I can rapidly alert others about hazards or request help.

#### Acceptance Criteria

1. WHEN a user submits a report with type, location, and description, THE Report_Service SHALL create a report record with a unique ID, timestamp, and pending status
2. THE Report_Service SHALL accept report types of flood, landslide, blocked_road, and medical_emergency
3. WHEN a report is created, THE Report_Service SHALL store the submitter's user ID, latitude, longitude, and timestamp
4. THE Report_Service SHALL return the created report with ID, type, location, description, timestamp, verification status, and helpful count within 500ms
5. THE Report_Service SHALL validate that latitude is between -90.0 and 90.0 degrees
6. THE Report_Service SHALL validate that longitude is between -180.0 and 180.0 degrees
7. THE Report_Service SHALL support a vulnerable_person flag for priority rescue alerts

### Requirement 2: Report Retrieval and Filtering

**User Story:** As a community member, I want to view nearby verified reports, so that I can stay informed about hazards in my area.

#### Acceptance Criteria

1. WHEN a user requests nearby reports with their location and radius, THE Report_Service SHALL return all reports within the specified radius sorted by distance
2. THE Report_Service SHALL calculate distance using the Haversine formula for geographic coordinates
3. WHERE a user specifies a report type filter, THE Report_Service SHALL return only reports matching that type
4. WHERE a user specifies a verification status filter, THE Report_Service SHALL return only reports matching that status
5. THE Report_Service SHALL return reports with submitter username, location name, timestamp, verification count, and helpful count
6. WHEN a user requests a single report by ID, THE Report_Service SHALL return the complete report details including all verifications
7. IF a requested report ID does not exist, THEN THE Report_Service SHALL return a 404 error with message "Report not found"
8. THE Report_Service SHALL support pagination with limit and offset parameters

### Requirement 3: Community Vouch System

**User Story:** As a community member, I want to vouch for reports I witness, so that admins can see which reports are legitimate.

#### Acceptance Criteria

1. WHEN a user vouches for a report, THE Report_Service SHALL create a vouch record linking the user ID to the report ID with a timestamp
2. THE Report_Service SHALL prevent a user from vouching for the same report more than once
3. IF a user attempts duplicate vouch, THEN THE Report_Service SHALL return a 409 error with message "Already vouched"
4. WHEN a vouch is created, THE Report_Service SHALL increment the report's vouch count
5. THE Report_Service SHALL return the updated vouch count within 300ms
6. WHEN a user requests a report, THE Report_Service SHALL include the total vouch count and whether the current user has vouched for it
7. THE Report_Service SHALL allow users to remove their vouch from a report
8. WHEN a vouch is removed, THE Report_Service SHALL decrement the report's vouch count
9. THE Report_Service SHALL display vouch count to help admins identify legitimate reports
10. ONLY admins SHALL be able to officially verify/approve reports (change status to validated)

### Requirement 4: Report Helpfulness Tracking

**User Story:** As a community member, I want to mark reports as helpful, so that valuable information is highlighted for others.

#### Acceptance Criteria

1. WHEN a user marks a report as helpful, THE Report_Service SHALL create a helpful record linking the user ID to the report ID
2. THE Report_Service SHALL prevent a user from marking the same report as helpful more than once
3. IF a user attempts duplicate helpful marking, THEN THE Report_Service SHALL return a 409 error with message "Already marked as helpful"
4. WHEN a helpful marking is created, THE Report_Service SHALL increment the report's helpful count
5. THE Report_Service SHALL return the updated helpful count within 300ms
6. WHEN a user requests a report, THE Report_Service SHALL include the total helpful count and whether the current user marked it helpful
7. THE Report_Service SHALL allow users to remove their helpful marking from a report
8. WHEN a helpful marking is removed, THE Report_Service SHALL decrement the report's helpful count

### Requirement 5: Personal Preparedness Checklist

**User Story:** As an individual user, I want to track my personal disaster preparedness tasks, so that I can ensure I'm ready for emergencies.

#### Acceptance Criteria

1. WHEN a user creates a preparedness checklist item, THE Preparedness_Service SHALL store the item name, category, and user ID
2. THE Preparedness_Service SHALL support categories including supplies, training, and planning
3. WHEN a user requests their checklist, THE Preparedness_Service SHALL return all items sorted by category then name
4. WHEN a user toggles a checklist item, THE Preparedness_Service SHALL update the completed status and record the timestamp
5. THE Preparedness_Service SHALL calculate the overall preparedness score as completed items divided by total items multiplied by 100
6. THE Preparedness_Service SHALL return a status message based on score: "Excellent Preparedness" (80-100%), "Good Preparedness" (60-79%), "Needs Improvement" (<60%)
7. THE Preparedness_Service SHALL return checklist data within 400ms
8. THE Preparedness_Service SHALL allow users to add notes to checklist items

### Requirement 6: Educational Content Management

**User Story:** As a user, I want to access educational content about flood safety, so that I can learn how to prepare and respond to emergencies.

#### Acceptance Criteria

1. THE Preparedness_Service SHALL provide a list of educational topics including flood escape procedures, emergency basics, and safety tips
2. WHEN a user requests educational content, THE Preparedness_Service SHALL return topic titles, descriptions, and external resource links
3. THE Preparedness_Service SHALL support both static content and external links (websites, videos)
4. THE Preparedness_Service SHALL categorize content by topic (before flood, during flood, after flood, general preparedness)
5. THE Preparedness_Service SHALL return educational content within 300ms
6. THE Preparedness_Service SHALL track which educational resources a user has viewed

### Requirement 7: Family Group Management

**User Story:** As a user, I want to create a family group and add my family members, so that I can monitor their safety during emergencies.

#### Acceptance Criteria

1. WHEN a user creates a family group, THE Family_Service SHALL store the group name and leader user ID
2. WHEN a user adds a family member, THE Family_Service SHALL store the member's name, phone number, and relationship
3. THE Family_Service SHALL validate phone numbers are in E.164 format
4. IF phone number format is invalid, THEN THE Family_Service SHALL return a 422 error with message "Invalid phone number format"
5. WHEN a user requests their family group, THE Family_Service SHALL return all family members with their current safety status
6. THE Family_Service SHALL default new family members to UNKNOWN safety status
7. THE Family_Service SHALL allow users to update family member information
8. THE Family_Service SHALL return family group data within 400ms

### Requirement 8: Family Safety Status Tracking

**User Story:** As a family member, I want to update my safety status during emergencies, so that my family knows I'm safe.

#### Acceptance Criteria

1. WHEN a family member updates their safety status, THE Family_Service SHALL store the status (SAFE, DANGER, UNKNOWN) and timestamp
2. THE Family_Service SHALL allow status updates via both app and SMS reply
3. WHEN a status is updated, THE Family_Service SHALL notify other family members in the group
4. THE Family_Service SHALL display safety status with visual indicators (✓ SAFE, ⚠️ DANGER, ⏳ UNKNOWN)
5. THE Family_Service SHALL record the last updated timestamp for each status change
6. THE Family_Service SHALL return updated status within 300ms
7. THE Family_Service SHALL only allow family members to view their own family group's status

### Requirement 9: Report Geospatial Queries

**User Story:** As a community member, I want to see reports near my location, so that I can visualize hazard locations.

#### Acceptance Criteria

1. WHEN a user requests reports within a bounding box, THE Report_Service SHALL return all reports where latitude is between min and max latitude and longitude is between min and max longitude
2. THE Report_Service SHALL validate that bounding box coordinates form a valid rectangle
3. WHEN a user requests reports within a radius of a point, THE Report_Service SHALL calculate distances using the Haversine formula
4. THE Report_Service SHALL return reports sorted by distance from the query point in ascending order
5. THE Report_Service SHALL include distance in kilometers for each returned report
6. WHERE a user specifies a maximum result count, THE Report_Service SHALL return at most that many reports

### Requirement 10: Report Lifecycle Management

**User Story:** As a community moderator, I want to manage report status, so that outdated or resolved reports don't clutter the feed.

#### Acceptance Criteria

1. WHEN a moderator marks a report as resolved, THE Report_Service SHALL update the report status to resolved and record the resolution timestamp
2. WHEN a moderator marks a report as rejected, THE Report_Service SHALL update the report status to rejected and record the reason
3. THE Report_Service SHALL support report statuses of pending, validated, rejected, resolved, and expired
4. WHEN a report is older than 7 days and unresolved, THE Report_Service SHALL automatically mark it as expired
5. WHERE a user requests reports, THE Report_Service SHALL exclude rejected, resolved, and expired reports by default
6. WHERE a user explicitly requests all statuses, THE Report_Service SHALL return reports regardless of status
7. WHEN a report status changes, THE Report_Service SHALL record the moderator user ID and timestamp
8. THE Report_Service SHALL allow report submitters to update their own report descriptions within 24 hours of creation

### Requirement 11: Evacuation Center Proximity

**User Story:** As a user, I want to see the nearest evacuation centers on a map, so that I know where to go during emergencies.

#### Acceptance Criteria

1. WHEN a user requests nearby evacuation centers, THE Preparedness_Service SHALL query centers within 20km of the user's location
2. THE Preparedness_Service SHALL calculate distance to each center using the Haversine formula
3. THE Preparedness_Service SHALL return centers sorted by distance in ascending order
4. THE Preparedness_Service SHALL include center name, address, capacity, contact phone, and distance for each result
5. THE Preparedness_Service SHALL return evacuation center data within 500ms
6. THE Preparedness_Service SHALL display centers on a map with location markers

### Requirement 12: SMS Flood Alert Notifications

**User Story:** As a registered user, I want to receive SMS alerts when floods are detected near my location, so that I can take immediate action.

#### Acceptance Criteria

1. WHEN a flood report is validated or a government flood warning is detected, THE SMS_Service SHALL identify all users within 10km of the flood location
2. THE SMS_Service SHALL send SMS notifications via Twilio to all affected users within 2 minutes of detection
3. THE SMS notification SHALL include flood location, distance from user's home, nearest evacuation center, and instructions to reply with safety status
4. THE SMS_Service SHALL query the nearest evacuation center within 20km and include its name, distance, and contact phone in the message
5. THE SMS_Service SHALL validate that user phone numbers are in E.164 format before sending
6. IF SMS delivery fails, THE SMS_Service SHALL log the failure with user ID, phone number, and error reason
7. THE SMS_Service SHALL track delivery status for each SMS sent
8. THE SMS_Service SHALL not send duplicate SMS alerts to the same user for the same flood event within 1 hour

### Requirement 13: SMS Reply Processing

**User Story:** As a user receiving a flood alert, I want to reply to the SMS with my safety status, so that my family knows I'm safe without opening the app.

#### Acceptance Criteria

1. WHEN a user replies to a flood alert SMS with "SAFE", THE SMS_Service SHALL update the user's safety status to SAFE
2. WHEN a user replies with "DANGER", THE SMS_Service SHALL update the user's safety status to DANGER and flag for priority assistance
3. THE SMS_Service SHALL accept case-insensitive replies (safe, SAFE, Safe)
4. THE SMS_Service SHALL process SMS replies within 30 seconds of receipt
5. WHEN a safety status is updated via SMS, THE SMS_Service SHALL notify all family members in the user's family group
6. THE SMS_Service SHALL send a confirmation SMS to the user after processing their reply
7. IF the reply is not recognized, THE SMS_Service SHALL send an error message with valid options
8. THE SMS_Service SHALL log all incoming SMS replies with timestamp and processing status

### Requirement 14: Government Flood Warning Integration

**User Story:** As the system, I want to monitor government flood warnings, so that I can automatically alert users.

#### Acceptance Criteria

1. THE SMS_Service SHALL fetch flood warnings from MetMalaysia API every 5 minutes
2. WHEN a new flood warning is detected, THE SMS_Service SHALL parse the warning area and severity
3. THE SMS_Service SHALL geocode the warning area to latitude and longitude coordinates
4. THE SMS_Service SHALL store the warning in the government_alerts table with source, area, severity, and timestamp
5. THE SMS_Service SHALL trigger SMS notifications to users within the affected area
6. IF the API request fails, THE SMS_Service SHALL log the error and retry on the next scheduled run
7. THE SMS_Service SHALL not send duplicate alerts for the same warning within 24 hours

### Requirement 15: Admin Verification Website

**User Story:** As an admin, I want to verify, approve, or reject community reports through a web interface, so that I can moderate content efficiently.

#### Acceptance Criteria

1. WHEN an admin logs in with valid credentials, THE Admin_Service SHALL return a JWT token valid for 24 hours
2. THE Admin_Service SHALL provide an endpoint to list all reports with filters for status, type, and search query
3. WHEN an admin requests reports, THE Admin_Service SHALL return paginated results with report ID, type, location, description, status, vouch count, and created timestamp
4. WHEN an admin approves a report, THE Admin_Service SHALL update the report status to validated and record the admin user ID
5. WHEN an admin rejects a report, THE Admin_Service SHALL update the report status to rejected, store the rejection reason, and record the admin user ID
6. WHEN an admin resolves a report, THE Admin_Service SHALL update the report status to resolved and record the resolution timestamp
7. WHEN an admin deletes a report, THE Admin_Service SHALL permanently remove the report and all associated vouches
8. THE Admin_Service SHALL provide statistics including total reports, pending count, validated count, rejected count, and counts by report type
9. THE Admin_Service SHALL display vouch count for each report to help admins identify legitimate reports
10. THE Admin_Service SHALL return report lists within 1 second
11. THE Admin_Service SHALL require authentication for all admin endpoints
12. ONLY admins SHALL be able to change report status to validated (community members can only vouch)

### Requirement 16: Twilio Webhook for SMS Replies

**User Story:** As the system, I want to receive and process SMS replies from users, so that I can update their safety status automatically.

#### Acceptance Criteria

1. WHEN Twilio receives an SMS reply, THE SMS_Service SHALL receive the webhook POST request with sender phone number and message body
2. THE SMS_Service SHALL identify the user by phone number
3. THE SMS_Service SHALL parse the message body to extract the safety status (SAFE or DANGER)
4. THE SMS_Service SHALL update the user's family member record with the new safety status
5. THE SMS_Service SHALL return TwiML response to Twilio within 5 seconds
6. IF the user is not found, THE SMS_Service SHALL log the error and send a "User not registered" response
7. THE SMS_Service SHALL handle concurrent webhook requests without data corruption
8. THE SMS_Service SHALL validate the webhook request signature to prevent spoofing

## Out of Scope (Not in MVP)

The following features are explicitly excluded from this MVP:

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
❌ Emergency drill scheduling and participation tracking
❌ Resilience metric history and trends
