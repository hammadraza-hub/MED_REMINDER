# 📋 AUDIT REPORT — MedRemind (med_remind_app)

**Scope:** Poora `lib/` (86 Dart files, ~48,000 lines, 174 TODO markers) + pubspec + README
**Date:** 2026-10-07
**Verdict:** UI-wise mazboot prototype, lekin **production-ready nahi** — data layer adhoora, auth/notifications fake, navigation mein structural bugs.

---

## 📊 Summary Scorecard

| Area | Score | Comment |
|---|---|---|
| UI/Design system | 8/10 | `AppColors` centralization achhi, components reusable |
| Architecture | 6/10 | Repository pattern sahi hai, lekin adha implement |
| Data persistence | 3/10 | Sirf meds/members/profile save; baqi sab dummy |
| Navigation | 4/10 | Shell pattern sahi, par 24 jagah duplicate shell bug |
| Code quality | 5/10 | Consistent style, par duplication + dead code bahut |
| Security/Auth | 1/10 | Koi real auth nahi |
| Testing | 0/10 | Zero tests |
| Production readiness | 3/10 | |

---

## 🔴 CRITICAL (P0 — pehle fix karo)

### C1. Reminder app mein reminder hi nahi hai
`pubspec.yaml` mein `flutter_local_notifications` jaisa koi package hi nahi. Dose reminders, refill alerts, appointment reminders — kuch bhi schedule nahi hota. App ka core purpose missing hai.
→ Impact: App ka naam "Med Reminder" hai but reminder feature exists hi nahi.

### C2. Auth pura fake hai
- `login_screen.dart:39` — non-empty check, phir SnackBar *"Login successful!"*. Koi credential verify nahi hota.
- Signup — data kahin save nahi hota. Reset password — sirf `debugPrint`.
- **Worse:** yeh pura flow (Splash→Onboarding→Signup→Login) **dead code** hai — `main.dart` isse kabhi call nahi karta. App seedha Home pe khulti hai, koi gate nahi.

### C3. Data loss — 80% features restart pe gayab

| Save hota hai (SQLite) | Sirf memory hai (restart = gayab) |
|---|---|
| Members, Medications, Schedules, Profile/photo | Doses, vitals, adherence, streaks, inventory, refills, pharmacies, appointments, doctor notes, side effects, invites, doctors |

User "Mark Refilled" kare → restart → wapas purana count. Symptom log kare → gayab.

### C4. Navigation — duplicate shell stacking (24 jagah)
Detail screens aise karti hain:

```dart
Navigator.push(MaterialPageRoute(builder: (_) => MedRemindShell(initialIndex: 0)));
```

Har baar **naya shell** stack pe chadhta hai (purana nahi hota) → back pe stale shell, unbounded stack growth. Sahi tarika pop-to-shell ya `pushAndRemoveUntil` consistently.

---

## 🟠 HIGH (P1 — functional bugs)

### H1. Saved vitals kabhi list/chart mein nahi aati
`vitals_list_screen.dart` — `AddVitalsEntryScreen` se result **discard** ho jata hai (khud TODO accept kiya). Chart bhi refresh nahi hota. User form bharta hai, kuch nahi hota.

### H2. Missed-dose reason persist nahi hota
`missed_dose_reason_modal.dart` → result sirf SnackBar dikhata hai. `CalendarData.dosesForDate()` const items return karta hai bina reason ke → "Tap to update" kabhi saved reason dikha nahi sakta.

### H3. Edit Medication stable ID nahi rakhta
`EditMedicationScreen` ko display strings milti hain (`medicineName, strength...`), **`medicationId` nahi** → edits SQLite mein round-trip nahi hote (`meds_screen.dart` ka khud TODO).

### H4. Member switching inconsistent

| Data | `memberId` se filter? |
|---|---|
| Doctors, members, meds, profile | ✅ Haan |
| Home doses, calendar, vitals, adherence, streaks | ❌ Nahi |

Mom pe switch karo → Doctors khali ho jate hain, Home pe Sarah ke doses dikhte rehte hain.

### H5. Medication lists alag-alag (4 sources)
Home=5 meds, Calendar=3, Adherence=4, AddDoctor=3 — koi shared source nahi. Same app mein user ko alag med lists dikhti hain.

### H6. Health profile data throw-away
`health_profile_screen.dart` — conditions/allergies input liya, aage pass hi nahi kiya, save kahin nahi. (Aur yeh screen bhi dead code hai.)

### H7. `FamilySetupScreen` navigation bug
`pushAndRemoveUntil(HomeScreen())` — seedha HomeScreen push karti hai **MedRemindShell nahi** → bottom bar gayab (agar yeh kabhi launch ho).

---

## 🟡 MEDIUM (P2 — quality/maintainability)

### M1. Dead code — ~10 files / pura auth+setup flow
`splash_screen`, `onboarding_screen`, `create_account_screen`, `health_profile_screen`, `notification_setup_screen`, `family_setup_screen`, `app_theme.dart` — sab unreferenced. `create_account_screen` = `signup_screen` ka abandoned duplicate (hardcoded hex ke saath, empty button).

### M2. Design system violations
- `create_account_screen.dart` — 18 hardcoded hex
- `health_profile_screen.dart` — 6 hardcoded hex
- `app_theme.dart` ek **doosra hi palette** (`#006B4D` vs `AppColors.primary #007A5E`) — dead par dangerous
- Duplicate constants: `streakGreen`==`streakFlame`, `inventoryWarning`==`inventoryLow`

### M3. Duplication — refactor candidates
- 4 dose-status enums (`DoseStatus`, `DoseHistoryStatus`, `StreakDoseStatus` [dead], `AdherenceDoseStatus`)
- 2 vital-type enums (`VitalType` vs `AddVitalType`)
- Medicine-image `switch` ×4, `_medicineTypeIcon` ×3, date/time formatters ×6+
- Dark header code copy-paste (Profiles vs Invite)
- Responsive tablet math copy-paste 4+ files mein

### M4. Performance smells
- `adherence_detail_screen` + `streaks_stats_screen` — getters har build pe 365-day dummy history regenerate karte hain (3+ baar per build)
- `calendar_screen` — `dosesForDate` har build pe re-generate
- Regex loops in OCR parsing per-line re-compile

### M5. Fake async / misleading UI
- `Future.delayed(300–400ms)` = fake network spinner (invite, vitals, doctor, appointment save)
- "Smart Caregiver Alert — reminder scheduled automatically" → kuch schedule nahi hota
- "HIPAA-compliant encryption" banner → koi encryption nahi
- "Caregiver Real-time Sync" → hardcoded `true`

### M6. Schema issues
- `Medications.linkedPharmacyId` — FK **bina** `.references()` (sirf yeh wala FK)
- `scheduleType` ke 2 alag vocabularies: `daily/specificDays/interval` (DB) vs `daily/specific_days/cyclical/prn/tapering` (repo) — free-form strings, no enum
- `watchSchedules` filters `isEnabled=true`, `getSchedules` nahi karta (asymmetric)
- `DoseEvents` + `RefillEvents` tables bani hain, **koi repository/UI nahi**

### M7. Hardcoded magic values
`'Sarah'` default, streak `12`, goal `80%` ×2, previous-period `82%`, Pulse `72 bpm`, med lists, `local_sarah*` seed IDs, `'3 notes'`, `'Sep 22'`, `'2 appointments scheduled'`, demo prefill (128/82/96/68.4).

---

## 🟢 LOW (P3 — polish)

| # | Issue | Location |
|---|---|---|
| L1 | Leftover editor comment: `// ← YE LINE TUMHARI FILE MEIN THI HI NAHI!` | `custom_button.dart:43` |
| L2 | Description = template default *"A new Flutter project."* | `pubspec.yaml` |
| L3 | README markdown line ~249 ke baad toota (headings ke `#` gayab) | `README.md` |
| L4 | `OcrService`/`CameraService` chatty `debugPrint` (raw OCR text) release mein bhi | core/services |
| L5 | `DatabaseProvider.close()` — kabhi call nahi hota | `database_provider.dart` |
| L6 | `sqlite3_flutter_libs ^0.6.0+eol` — upstream **end-of-life** | `pubspec.yaml` |
| L7 | A11y: back button = bare `GestureDetector` (no 48dp touch target) | `onboarding_header.dart` |
| L8 | Manual `hasError` flag, Form/validation integration nahi | `custom_text_field.dart` |
| L9 | "Yesterday" sirf `day` compare karke — month boundary pe false positive | `doctor_notes_screen.dart` |
| L10 | `day % 7` check `day % 5` **pehle** → day 35/70 partial ki jagah full "missed" | `calendar_data.dart` |
| L11 | Signup mein `pill.png` precache hota hai par use `signup_pill2.jpg` | `signup_screen.dart` |
| L12 | Bottom-nav `currentIndex` inconsistency: Meds children = 1, Appointments/Notes = 0 | meds feature |

---

## ✅ Achhi cheezein (yeh preserve karo)

1. **Repository + contract pattern** — `abstract MedicationRepository` → `LocalMedicationRepository`, Firebase swap sirf naya implementation = UI untouched
2. **`AppColors` ek jagah** — 150+ named colors, private constructor
3. **Screen vs `*_data.dart` separation** — UI aur dummy data alag
4. **Drift schema + migration** (v1→v2 upgrade working) + `AppDatabase.forTesting`
5. **`IndexedStack` shell** — tab state preserve hoti hai
6. **OCR pipeline** (camera → ML Kit → heuristic parser) genuinely solid — strength/name/form/frequency extraction, confidence scoring
7. **Member isolation mechanism** (`ProfileController` + `useSelectedProfileImage:false` contract) — jab poori tarah lag jaye ga achha hoga
8. **Idempotent seeding** — deterministic IDs se double-seed nahi hota

---

## 🗺️ Recommended Fix Roadmap

### Sprint 1 — Foundation (P0)
1. Notifications package add + dose scheduling (app ka core)
2. Navigation fix: detail screens → pop-to-shell (24 sites, ek helper banao)
3. `DoseEvents` repository banao + home/calendar ko real data pe lagao
4. Dead code delete karo (~10 files, 2-3k lines)

### Sprint 2 — Data integrity (P1)
5. Vitals/missed-reason/invite results persist karo
6. `EditMedicationScreen` ko `medicationId` do
7. Shared `MedicationRepository` se Home/Calendar/Adherence ki lists unify karo
8. Har feature data ko `memberId` se filter karo

### Sprint 3 — Quality (P2)
9. Enums unify (4 dose-status → 1), formatters/icon helpers ek `utils` file mein
10. Hardcoded hex hatao, `app_theme.dart` delete ya merge karo
11. Fake delays/`Future.delayed` hatao, misleading UI copy sahi karo
12. Pehle 10-15 unit tests (repositories + OCR parser)

### Sprint 4 — Release (P1/P3)
13. Auth decide karo: Firebase Auth ya onboarding skip + guest mode
14. README fix, pubspec description, eol dependency upgrade

---

**Bottom line:** Design system aur architecture ki neev achhi hai, lekin app abhi **UI demo** hai — 80% data dummy hai, core "reminder" feature missing hai, aur navigation mein ek structural bug hai. Sprint 1 ke 4 points agar kar lo, app usable ban jayegi.
