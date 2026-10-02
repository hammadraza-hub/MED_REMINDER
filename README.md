# 💊 MedRemind — Medication Reminder & Health Tracking App

Never miss a dose again — manage medications, schedules, adherence, inventory, pharmacy details, and health vitals for you and your family.

MedRemind is a Flutter-based medication reminder and health management app. The project currently includes a comprehensive frontend experience with reusable components, dynamic dummy data, medication tracking, adherence insights, refill management, pharmacy workflows, and vital-sign monitoring.

The UI architecture is designed so the current dummy data layer can later be replaced with user-specific Firebase data without rebuilding the screens.

---

## ✨ Features

### 🔐 Authentication & Onboarding

- Splash screen
- Onboarding flow
- Sign up
- Login
- Password reset
- Health profile setup
- Medical conditions
- Allergy setup
- Notification permission flow
- Family member setup

---

### 🏠 Home Dashboard

- Personalized greeting
- Family member/profile switching
- Daily medication progress ring
- Taken / Pending / Missed statistics
- Daily dose schedule
- Medication filters
- Taken action
- Skip dose
- Snooze dose
- Undo taken dose
- Low-stock warnings
- Daily streak indicator
- Quick Access shortcuts

---

### 🔥 Streaks & Adherence Stats

- Current medication streak
- Dynamic adherence statistics
- 30-day insights
- 90-day insights
- Historical trend visualization
- Data-driven chart calculations
- User/profile-aware navigation

---

### 💊 Medication Management

- Active and archived medications
- Add medication
- Search medication
- Scan medication label
- OCR scan review
- Manual medication entry
- Custom medication forms
- Edit medication
- Medication images by form
- Schedule medication
- Discontinue medication
- Archive discontinued medication
- Refill indicators

Medication forms currently support:

- Tablet
- Capsule
- Liquid
- Injection
- Drops
- Custom / Other forms

---

### 📷 Medication Label Scan

- Medication label scanning flow
- OCR-detected medication information
- Review and correction screen
- Medication name detection
- Strength detection
- Dynamic unclear-strength warning
- Retake photo
- Continue directly into schedule setup

---

### ⏰ Medication Scheduling

Multiple scheduling modes are supported:

- Daily
- Specific Days
- Cyclical
- As Needed (PRN)
- Tapering Dose

Additional schedule controls include:

- Multiple dose times
- Add/remove dose times
- Meal-relative timing
- Before meal
- With meal
- After meal
- Start date
- Optional end date
- Cyclical weeks on/off configuration
- Schedule validation

---

### 📅 Calendar & Dose History

- Monthly medication calendar
- Weekly dose history
- Date-specific adherence data
- Taken doses
- Missed doses
- Partial adherence
- Future dates handled separately
- Medication images
- Dynamic adherence status
- Missed-dose reason flow

Future dates are not falsely marked as Taken, Missed, or Partial.

---

### 📊 Adherence Details

- Detailed medication adherence history
- Dynamic adherence calculations
- Status filters
- Dose history
- Medication information
- Missed-dose tracking
- Export-ready architecture
- Backend-ready calculated percentages

---

### ❓ Missed Dose Reasons

- Missed-dose reason modal
- Predefined reason selection
- Optional context
- Designed for future adherence reporting
- Backend-ready persistence flow

---

### 📦 Medication Inventory

- Remaining medication quantity
- Estimated days remaining
- Dynamic LOW / OK status
- Medication-specific units
- Supply progress
- Filter by:
  - All
  - Low Stock
  - OK
- Manual inventory adjustment
- Refill workflow
- Medication images
- Inventory synchronized with active medications

Low-stock status is calculated from inventory data instead of being manually hardcoded in the Meds UI.

---

### ➕ Adjust Inventory Count

Bottom-sheet inventory adjustment experience:

- Current medicine
- Current quantity
- Increase count
- Decrease count
- Quick adjustment options
- Optional adjustment reason
- Save count
- Cancel without changes

The backend architecture is prepared to update an existing inventory document using `medicationId` rather than creating duplicate inventory records.

---

### ⚠️ Refill Alerts

- Low-stock medication details
- Remaining medication information
- Estimated supply
- Linked pharmacy
- Call pharmacy
- Snooze refill reminder
- Mark medication as refilled
- Pharmacy detail navigation

Additional refill actions are planned as the workflow continues to expand.

---

### 🏥 Pharmacy Management

#### Pharmacy Details

- Pharmacy name
- Phone number
- Optional address
- Open / closed status
- Opening hours
- Linked medications
- Medication stock indicators
- Call pharmacy
- Edit pharmacy
- Refill-related information

#### Add / Edit Pharmacy

- Add new pharmacy
- Edit existing pharmacy
- Pharmacy name validation
- Phone validation
- Optional address
- Assign one or more medications
- Shared Add/Edit form architecture

The planned data relationship is:

```text
Current User / Family Member
        ↓
Medication
        ↓
linkedPharmacyId
        ↓
Pharmacy Document
🩺 Health Vitals
Vitals tracking has been added to the Home experience.

Currently supported metrics:

Blood Pressure
Blood Glucose
Weight
Heart Rate
Vitals List includes:

Latest reading
Units
Measurement timestamp
Trend indicator
Historical sparkline
Target/reference information
Caregiver sync state
Selected family profile
Dynamic profile name from Home
➕ Log Vitals
Users can log new vital measurements through a dedicated screen.

Supported entry types:

Blood Pressure
Systolic
Diastolic
Concurrent pulse
Blood Glucose
Weight
Heart Rate
Additional functionality:

Dynamic input form based on vital type
Previous reading comparison
Target/range status
Measurement date and time
Input validation
Selected family member context
Save / Cancel flow
Backend-ready result model
👨‍👩‍👧 Family Profiles
Multiple family members
Profile switching from Home
Selected profile context
Vitals profile synchronization
Architecture ready for user/member-specific medication and health data
Future Firebase queries will use member IDs so each family member has independent medication, adherence, inventory, and health records.

🧭 Centralized App Navigation
MedRemind uses a single reusable bottom navigation component.

Main tabs:

text

Home | Meds | Calendar | Reports | Settings
Architecture:

text

AppBottomNavigation
        ↓
MedRemindShell
        ↓
IndexedStack
Benefits:

One navigation definition for the entire app
Consistent icons
Consistent typography
Consistent colors
Correct active tab
Preserved main-tab state
No duplicated feature-specific bottom navigation bars
Detail screens return to the requested main tab through MedRemindShell(initialIndex: index).

🏗️ Architecture
The frontend follows a separation between UI and feature data.

Example:

text

UI Screen
   ↓
Feature Data / Model
   ↓
Firebase / Backend (planned)
Examples include:

text

HomeScreen
    ↓
HomeData

InventoryScreen
    ↓
InventoryData

PharmacyInfoScreen
    ↓
PharmacyInfoData

VitalsListScreen
    ↓
VitalsData
This allows the current dummy data to be replaced by Firestore queries or streams while keeping most UI code unchanged.

🧩 Reusable Components
The project uses reusable widgets including:

AppBottomNavigation
AppAvatar
CustomButton
CustomTextField
SocialButton
OnboardingHeader
Shared medication images
Reusable modals and bottom sheets
Feature-specific duplicated bottom navigation bars have been removed.

🎨 Design System
Colors are centralized through:

text

lib/core/constants/app_colors.dart
The project avoids scattering custom hex colors throughout feature screens.

UI principles include:

Consistent color system
Readable typography
Accessible touch targets
Responsive layouts
Shared visual language
Maximum content width for tablets
Scrollable layouts where required
SafeArea support
Main feature content generally uses a maximum width of approximately 480px for tablet-friendly presentation.

🔄 Current Data Strategy
The app currently uses frontend/dummy data to build and validate the complete user experience.

The architecture is being prepared for:

text

Authenticated User
        ↓
Family Member
        ↓
Medications
        ↓
Schedules
        ↓
Dose History
        ↓
Inventory
        ↓
Pharmacy
        ↓
Vitals
        ↓
Reports
Values such as adherence percentages, inventory status, streaks, trends, and charts are intended to be calculated from real backend records rather than manually maintained UI values.

🔥 Planned Firebase Integration
Firebase integration is planned for the next backend phase.

Expected services include:

Firebase Authentication
Sign up
Login
Password reset
Current authenticated user
Cloud Firestore
User profiles
Family members
Medications
Medication schedules
Dose history
Adherence records
Inventory
Pharmacy information
Vital entries
Streak data
Reports
Firebase Storage
User profile images
Medication photos
Scanned medication labels
Notifications
Medication reminders
Snooze reminders
Refill alerts
Low-stock notifications
Schedule changes
🛠️ Tech Stack
Framework: Flutter
Language: Dart
State: StatefulWidget / local feature state
Navigation: Navigator + centralized MedRemindShell
Main tab state: IndexedStack
Assets: Local medication/profile images
SVG: flutter_svg
OCR: OCR service architecture
Charts: Custom/data-driven Flutter visualization
Backend: Firebase planned
Authentication: Firebase Auth planned
Database: Cloud Firestore planned
Storage: Firebase Storage planned
📂 Project Structure
text

lib/
├── core/
│   ├── constants/
│   └── services/
│
├── features/
│   ├── home/
│   │   ├── home_screen.dart
│   │   ├── home_data.dart
│   │   ├── streaks_stats_screen.dart
│   │   ├── vitals_list_screen.dart
│   │   ├── vitals_data.dart
│   │   ├── add_vitals_entry_screen.dart
│   │   └── add_vitals_entry_data.dart
│   │
│   ├── meds/
│   │   ├── meds_screen.dart
│   │   ├── add_medication_screen.dart
│   │   ├── add_manual_screen.dart
│   │   ├── review_scan_screen.dart
│   │   ├── schedule_screen.dart
│   │   ├── edit_medication_screen.dart
│   │   ├── inventory_screen.dart
│   │   ├── refill_alert_detail_screen.dart
│   │   ├── pharmacy_info_screen.dart
│   │   └── add_edit_pharmacy_screen.dart
│   │
│   └── calendar/
│       ├── calendar_screen.dart
│       ├── adherence_detail_screen.dart
│       └── missed_dose_reason_modal.dart
│
├── widgets/
│   ├── app_avatar.dart
│   └── app_bottom_navigation.dart
│
└── main_shell.dart
📱 Main User Flow
text

Splash
   ↓
Onboarding
   ↓
Authentication
   ↓
Health Profile Setup
   ↓
Notification Setup
   ↓
Home Dashboard
From the main application:

text

Home
├── Daily Doses
├── Streaks & Stats
└── Vitals
    ├── Vitals List
    └── Log Vitals

Meds
├── Medication List
├── Add Medication
│   ├── Search
│   ├── Scan Label
│   │   └── Review Scan
│   └── Manual Entry
├── Schedule
├── Edit Medication
├── Inventory
│   ├── Adjust Count
│   └── Refill Alert
│       └── Pharmacy Details
│           └── Add / Edit Pharmacy
└── Archived Medications

Calendar
├── Dose History
├── Missed Dose Reason
└── Adherence Detail
🚀 Run Locally
Clone the repository:

Bash

git clone https://github.com/hammadraza-hub/MED_REMINDER.git
Open the Flutter project and install dependencies:

Bash

flutter pub get
Run the app:

Bash

flutter run
Check code health:

Bash

flutter analyze
🚧 Project Status
MedRemind is currently under active development.

Implemented / In Progress
✅ Onboarding UI
✅ Authentication UI
✅ Health setup UI
✅ Home dashboard
✅ Family profile switching
✅ Dose actions
✅ Medication management UI
✅ Add medication flows
✅ OCR review flow
✅ Medication scheduling
✅ Calendar adherence
✅ Missed-dose workflow
✅ Adherence details
✅ Streaks & statistics
✅ Medication inventory
✅ Inventory adjustment
✅ Refill workflow
✅ Pharmacy details
✅ Add/Edit pharmacy
✅ Vitals overview
✅ Log Vitals
✅ Centralized bottom navigation
🔄 Vitals charts/trends
🔄 Reports
🔄 Settings expansion
⏳ Firebase Authentication integration
⏳ Firestore persistence
⏳ Firebase Storage
⏳ Production medication notifications
⏳ User-specific realtime synchronization
🎯 Goal
The goal of MedRemind is to provide one simple health companion for medication adherence, refill management, family medication tracking, health vitals, and long-term adherence insights.

The frontend is being built first with backend-ready models and data separation so the application can transition to Firebase-powered user-specific data without redesigning the complete UI.

📌 Repository
https://github.com/hammadraza-hub/MED_REMINDER

Built with Flutter 💙

MedRemind — Never miss a dose again.