# Medicine Reminder App — Firestore Schema

Version: 1.0
Module: M0
Status: Locked for Phase 1

========================================
1. USERS
========================================

users/{uid}

Fields:
- email: string
- displayName: string
- createdAt: timestamp
- updatedAt: timestamp
- timezone: string
- settings: map
- legalVersions: map
- aiConsentAt: timestamp | null
- deletionRequestedAt: timestamp | null

Subcollections:

users/{uid}/devices/{deviceId}

Fields:
- fcmToken: string
- platform: string (android | ios)
- appVersion: string
- timezone: string
- lastSeen: timestamp


========================================
2. PROFILES
========================================

profiles/{profileId}

Fields:
- ownerUid: string
- kind: string (self | dependent)
- name: string
- timezone: string
- roles: map (uid -> role)
- memberUids: array<string>
- healthUids: array<string>
- createdAt: timestamp
- updatedAt: timestamp
- permissions: map (uid -> permission flags)

Role Types:
- owner
- caregiver
- viewer
Advanced Permissions:

permissions: {
  uid: {
    editMedications: boolean,
    logDoses: boolean
  }
}

Health Access:
- healthUids is the authoritative source for health-data access.
- Only owner can grant or revoke health access.
- Caregivers and viewers cannot grant themselves health access.


========================================
3. MEDICATIONS
========================================

profiles/{profileId}/medications/{medId}

Fields:
- name: string
- strength: string
- form: string
- dosage: string
- instructions: string
- schedule: map
- quantityOnHand: number
- flags: map
- active: boolean
- createdAt: timestamp
- updatedAt: timestamp

Subcollections:

profiles/{profileId}/medications/{medId}/inventoryEvents/{eventId}

Fields:
- delta: number
- reason: string
- doseId: string | null
- createdAt: timestamp


========================================
4. DOSES
========================================

profiles/{profileId}/doses/{doseId}

Dose ID Format:
medId_yyyyMMddHHmm

Fields:
- medId: string
- scheduledAt: timestamp
- missDeadline: timestamp
- status: string (pending | taken | skipped | missed)
- loggedAt: timestamp | null
- reasonCode: string | null


========================================
5. DAILY SUMMARIES
========================================

profiles/{profileId}/dailySummaries/{yyyy-MM-dd}

Fields:
- due: number
- taken: number
- skipped: number
- missed: number
- updatedAt: timestamp


========================================
6. HEALTH DATA COLLECTIONS
========================================

All medical data remains inside:

profiles/{profileId}/

Collections:
- allergies
- safetyWarnings
- refillAlerts
- pharmacies
- links
- vitals
- vitalsDaily
- symptoms
- prescribers
- appointments
- doctorNotes

Each document:
- createdAt: timestamp
- updatedAt: timestamp
- Relevant medical fields


========================================
7. GLOBAL COLLECTIONS
========================================

drugs/{rxcui}
- Drug reference information

supportTickets/{id}
- Support requests

invites/{id}
- Caregiver invitations

customers/{uid}
- RevenueCat subscription information

mail/{id}
- Trigger Email documents

exportJobs/{id}
- Medical data export jobs

config/{docId}
- plans
- faq
- jobs


========================================
8. FUTURE PHASES
========================================

Phase 2:
- Additional medical features

Phase 3:
- chatThreads/{threadId}/messages/{messageId}
- groups/{groupId}/posts/{postId}


========================================
9. SECURITY REQUIREMENTS
========================================

1. Medical data must never be stored under users/{uid}.

2. All medical records belong to profiles/{profileId}.

3. Only authorized profile members can access medical data.

4. Profile ownership must be verified using Firebase Authentication.

5. Caregiver access must follow roles and permissions.

6. Users cannot modify their own roles.

7. Sensitive collections require restrictive security rules.

8. Cloud Functions perform privileged backend operations.

9. Production medical data must not be copied into staging.

10. App Check must be enabled and tested before enforcement.


========================================
10. ENVIRONMENTS
========================================

STAGING:
Project ID: medapp-staging
Firestore Region: asia-south1

PRODUCTION:
Project ID: med-reminder-38e5c
Firestore Region: nam5

Database ID for both:
(default)