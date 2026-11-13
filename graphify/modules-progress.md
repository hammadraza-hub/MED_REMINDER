# Module progress board (from *Medicine-App-Backend-Modules-Firebase.pdf*)

Legend: ✅ done · 🟡 partial · 🟠 UI only · ⬜ not started · ⛔ blocked
Status is derived from git history + code inspection on 2026-11-12. "Spark" = built client-side because Blaze/Functions not available.

## Phase 1 — Core launch

| ID | Module | Pri | Status | % | Evidence | Gap / next action |
|----|--------|-----|--------|---|----------|-------------------|
| M0 | Firebase project, envs, data layout | P0 | ✅ | 90 | `firebase.json`, `.firebaserc`, `firestore.rules` (624 lines), 26 rules tests, `.github/workflows/firebase.yml`, schema doc | Storage rules unused (no bucket, Spark); prod project not wired; Functions folder empty |
| M1 | Flutter ↔ Firebase foundation | P0 | ✅ | 90 | `AppConfig`, `AppException`, `FunctionsClient`, 7 repos, Crashlytics, App Check | `firebase_options_prod.dart` gitignored (fresh clone won't build); Storage emulator skipped |
| M2 | Authentication & accounts | P0 | 🟡 | 70 | login/signup/reset/account screens on FirebaseAuth; splash routing | Google (`login_screen.dart:403`) & Apple (`:405`) TODO; `onUserCreated` done client-side; no "sign out everywhere"; Terms/Privacy screen TODO (`signup_screen.dart:727`) |
| M3 | Profiles, health profile, access model | P0 | ✅ | 85 | `Profile`/`Allergy` models, rules helpers canRead/canWrite, switcher, allergy CRUD | Avatars to Storage deferred; per-plan profile limit not server-enforced |
| M4 | Drug catalog & label scan | P0 | 🟡 | 55 | `drug_repository`, ML Kit OCR, scan screens | No `syncRxnorm`/`parseLabel`/`drugInfo` functions |
| M5 | Medications & schedules | P0 | ✅ | 80 | `firebase_medication_repository`, schedule picker, rules | Verify all 5 schedule types (cyclic, taper, PRN) |
| M6 | Dose engine | P0 | ✅ | 80 | `lib/core/dose_engine.dart` (381 lines), doses rules | Runs on device, not a scheduled function — gaps if app not opened |
| M7 | Dose logging, adherence, calendar | P0 | ✅ | 85 | commit `4410d75`; calendar/adherence/streaks on Firestore; dailySummaries | `adherence_detail_screen.dart:279` TODO; offline logging unverified |
| M8 | Reminders & push | P0 | 🟡 | 70 | `reminder_scheduler.dart` (449), `push_service`, action queue, FCM token registration, permission screen | **Android only**; iOS not done; no server-side push fallback |
| M9 | Inventory, refills, pharmacies | P0/P1 | 🟡 | 65 | `firebase_inventory_repository`, inventory/refill/pharmacy screens, rules (inventoryEvents, pharmacies) | `refillAlerts` only under generic rule; no scheduled refill job |
| M10 | Safety checks | P0/P1 | 🟡 | 40 | static `interaction_checker.dart`, warning screen | Hard-coded map; no RxNorm/classes; no allergy/duplicate auto-trigger |
| M11 | Caregiver & family sharing | P0/P1 | ⛔ | 25 | `firebase_caregiver_repository.dart` is a **stub**; invite/permissions screens | Needs callable functions (Blaze) |
| M12 | Subscriptions (RevenueCat) | P1 | 🟡 | 60 | `subscription_service.dart`, paywall/compare/upgrade screens | `customers` rule + tests done; cancel opens store page (step 2); key guard + UI test done on emulator (steps 3–4); **step 5 needs RevenueCat key**; webhook → `customers/{uid}` needs functions |
| M13 | Settings, support, Remote Config | P1 | 🟡 | 55 | `remote_config_service`, `settings_repository`, notification settings in `users/{uid}.settings` | Step 1 of 7 done (RC keys, force-update/maintenance gate, real version). Left: legal re-prompt, settings sync, `config/faq`, `supportTickets`, biometric lock; ticket email needs Blaze |
| M14 | Data export & account deletion | P1 | ⬜ | 10 | `data_export_screen` UI only | `exportJobs`, delete-account flow, functions |

## Phase 2/3

| ID | Module | Pri | Status | % | Notes |
|----|--------|-----|--------|---|-------|
| M15 | Vitals, symptoms, health sync | P2 | 🟠 | 15 | Vitals screens + Drift `VitalEntries`; no Firestore |
| M16 | Prescribers & appointments | P2 | 🟠 | 10 | doctors/appointments/doctor-notes screens, dummy data |
| M17 | Reports (PDF/CSV) | P2 | 🟠 | 15 | `report_preview_*` + smoke test |
| M18 | AI assistant | P3 | 🟠 | 20 | `assistant/*`, `ai_service.dart`, key via `.env` (should move server-side) |
| M19 | Community | P3 | 🟠 | 5 | UI only, optional |

## Cross-cutting

| ID | Module | Status | % | Notes |
|----|--------|--------|---|-------|
| M20 | Loading/error/empty/offline states | 🟡 | 25 | `AppException` exists; screens inconsistent |
| M21 | Security & hardening | 🟡 | 35 | Rules + tests; App Check **not enforced**; `.env` is gitignored |
| M22 | Testing | 🟡 | 25 | 30 rules cases, 3 Flutter smoke tests; **no repo/engine/scheduler unit tests** |
| M23 | Graphify | 🟡 | 50 | This folder (created 2026-11-12). Refresh after each module |

## Overall
Phase 1 (M0–M14) weighted ≈ **62 %**; whole plan ≈ **45 %** (estimates, not measured).

## Localization
5 locales (en, hi: 495 keys; es/fr/ar: 461). ~34 of ~113 feature files reference `AppLocalizations` — the rest still hardcode English. es/fr/ar are 34 keys behind en/hi, and their generated files have uncommitted changes.

## Tech debt
- Duplicate repo interfaces under `lib/core/*` vs `lib/repositories/*`; legacy Drift local repos.
- `meds_screen_restored.dart`, `add_manual_screen.dart` vs `add_medication_manual_screen.dart` look like leftovers.
- ~40 `TODO Backend` markers across `lib/` (profile, assistant, calendar, accessibility, database).
- Untracked `Medicine-App-Backend-Modules-Firebase.pdf`; `firestore-debug.log` / `pubsub-debug.log` at root.
- Generated desktop plugin registrants modified — commit or revert.
- `ROADMAP.md` (Oct 2026, pre-Firebase) is stale vs. the M0–M23 plan.

## Suggested next steps
1. Commit/finish M12 (subscription edits + l10n) and run `flutter analyze`.
2. Decide Blaze upgrade → unlocks M11, M4 server pieces, M14, push fan-out.
3. Finish M2 Google sign-in + Terms/Privacy screen.
4. Add unit tests for `dose_engine`, `reminder_scheduler`, repos (M22).
5. iOS notification path (M8).
