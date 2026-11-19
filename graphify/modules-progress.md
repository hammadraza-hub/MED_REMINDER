# Module progress board (from *Medicine-App-Backend-Modules-Firebase.pdf*)

Legend: ✅ done · 🟡 partial · ⛔ blocked · ⬜ not started
"**Spark**" = built client-side on the Firebase Spark plan (no Blaze, no Cloud Functions). A ✅ here means *done for Spark*; the "Needs Blaze / key / device" column lists what the plan wants that cannot be built or tested without them.

Status as of **2026-11-18**, commit `727ebd7` (M22 pushed). Percentages are estimates of the Spark scope, not measured.

## Phase 1 — Core launch

| ID | Module | Pri | Status | Evidence (where) | Needs Blaze / key / device |
|----|--------|-----|--------|------------------|----------------------------|
| M0 | Firebase project, envs, data layout | P0 | ✅ | `firebase.json`, `firestore.rules` (1855 lines, 32 match blocks), `firestore.indexes.json` (5 collection groups), `docs/firestore-schema.md`, CI `.github/workflows/firebase.yml` | Prod project not wired in CI; Storage not used (no bucket) |
| M1 | Flutter ↔ Firebase foundation | P0 | ✅ | `AppConfig`, `AppException`, `FunctionsClient`, repositories, Crashlytics + `SafeLog`, `AppStartup` | `firebase_options_prod.dart` is gitignored (fresh clone will not compile) |
| M2 | Authentication & accounts | P0 | 🟡 | email sign-up / login / reset, account screen, legal consent gate (M13), app lock | Google (`login_screen.dart:406`) and Apple (`:408`) sign-in TODO; "sign out everywhere" |
| M3 | Profiles, health profile, access model | P0 | ✅ | `Profile`, allergies, profile switcher, rules helpers (owner / caregiver / viewer, permissions), self-leave | Avatars to Storage (no bucket); per-plan profile limit not server-enforced |
| M4 | Drug catalog & label scan | P0 | 🟡 | `drug_repository`, ML Kit OCR, scan screens, FDA label service (M18) | `syncRxnorm` / `parseLabel` / `drugInfo` functions (Blaze) |
| M5 | Medications & schedules | P0 | ✅ | `medication_repository`, schedule picker, 5 schedule types, rules | – |
| M6 | Dose engine | P0 | ✅ | `lib/core/dose_engine.dart` (profile time zone, DST-safe, 57 tests), `dose_zone.dart`, `MedicationRepository.topUpDoses` (14-day window refilled on app start) | PDF wants a nightly scheduled function; on Spark the window is refilled only when the app is opened |
| M7 | Dose logging, adherence, calendar | P0 | ✅ | `dose_repository` (log / snooze / undo / overdue sweep), calendar, adherence, `StreakCalculator` | – |
| M8 | Reminders & push | P0 | 🟡 | `reminder_scheduler` + pure `DoseAlarmPlanner` (48 h, 3 escalations, iOS 64 / Android 200 cap), quiet hours for appointments, action queue (Taken / Skip / Snooze), lock-screen privacy; **real Android alarm verified on the emulator** | Server push / FCM fan-out (Blaze); iOS not tested on a device; real-phone matrix (`docs/REMINDER_DEVICE_MATRIX.md`) not run; reminders only for the selected profile |
| M9 | Inventory, refills, pharmacies | P0/P1 | 🟡 | `firebase_inventory_repository`, inventory / refill / pharmacy screens, rules (stock bounds, events) | Scheduled refill job and refill push (Blaze) |
| M10 | Safety checks | P0/P1 | 🟡 | static `interaction_checker.dart`, interaction warning screen | RxNorm / drug classes (needs a server); no automatic allergy / duplicate trigger |
| M11 | Caregiver & family sharing | P0/P1 | ⛔ | profile roles and permissions work in rules (caregiver loop tested on the emulator); invite / permission screens exist | `invites` has no rules and `firebase_caregiver_repository` is a stub: accepting an invite changes `memberUids`, which needs a server (Blaze) or a new rules design |
| M12 | Subscriptions (RevenueCat) | P1 | 🟡 | `subscription_service`, paywall / compare / upgrade screens, `customers/{uid}` read-only rule, Pro gates (`ownerIsPro`), 9 paywall widget tests | RevenueCat API key (step 5); webhook → `customers/{uid}` (Blaze) |
| M13 | Settings, support, Remote Config | P1 | ✅ | Remote Config (kill switch, version gate, FAQ), settings sync, legal re-consent, support tickets, biometric app lock | Ticket email (Trigger Email, Blaze) |
| M14 | Data export & account deletion | P1 | ✅ | client-side ZIP export, 7-day grace deletion, purge engine + screen, self-leave of shared profiles | `exportJobs` / delete function (Blaze); large accounts exceed the Spark write limit |

## Phase 2 / 3

| ID | Module | Pri | Status | Evidence (where) | Needs Blaze / key / device |
|----|--------|-----|--------|------------------|----------------------------|
| M15 | Vitals, symptoms, health sync | P2 | ✅ | `firebase_vitals_repository`, symptoms, `vitalsDaily` summaries, HealthKit / Health Connect mapper, charts | Real health data on a device |
| M16 | Prescribers & appointments | P2 | ✅ | prescribers, appointments, doctor notes, appointment reminders, Solo Pro gate in rules | – |
| M17 | Reports (PDF / CSV) | P2 | ✅ | report builder, PDF / CSV, preview, share, Pro gate | – |
| M18 | AI assistant | P3 | ✅ (client) | consent, safe context, safety layers, FDA labels, chat history in `chatThreads` | PDF wants the AI call on a server function; the key must not ship in the app: **not built** until Blaze |
| M19 | Community | P3 | ✅ | pseudonym profiles, groups, feed, posts, comments, votes, saved, report / block / filter, moderation | Server-side moderation jobs (Blaze) |

## Cross-cutting

| ID | Module | Status | Evidence (where) | Left |
|----|--------|--------|------------------|------|
| M20 | Loading / error / empty / offline states | ✅ | `AsyncState`, shared widgets, offline banner, queued writes, startup that does not hang offline | – |
| M21 | Security & hardening | ✅ (Spark part) | rules hardened (443 tests, probe 0 gaps), daily limits in rules, secrets guard, lock-screen privacy, App Check client code, `docs/PRODUCTION_RUNBOOK.md` | App Check enforcement (console step); rules + indexes not deployed to staging yet; Blaze parts written down |
| M22 | Testing | ✅ | 76 Flutter test files (1094 tests), 15 emulator integration files, 443 rules tests, rules probe, real alarm test, `docs/REMINDER_DEVICE_MATRIX.md` | Run the real-phone matrix |
| M23 | Graphify | ✅ | this folder (docs rewritten 2026-11-18) + `graphify-out/` rebuilt from commit `727ebd7` (8,605 nodes) | Refresh after every module: `python -m graphify update .` |

## Overall
Phase 1 (M0–M14): 10 of 15 modules done for Spark, 4 partial, 1 blocked. Phase 2/3 (M15–M19): all done for Spark. Cross-cutting M20–M22 done. **Everything that needs a server (Cloud Functions, push fan-out, Trigger Email, Twilio, RevenueCat webhook, scheduled jobs, server-side AI) is not built** and waits for Blaze.

## Localization
5 locales (en, hi: 993 keys; es / fr / ar: 959). The 34 keys behind in es / fr / ar fall back to English. Most feature screens use `AppLocalizations`; some older screens still hard-code English (for example parts of Add Medication and Invite Member).

## Tech debt (known)
- Dead / unreferenced files (confirmed by grep): `lib/features/meds/meds_screen_restored.dart` (2009 lines), `lib/repositories/firebase_dose_repository.dart`, `lib/core/doses/dose_repository.dart`. Also `add_manual_screen.dart` and `settings/allergy_screen.dart` look like leftovers. Marked, not deleted.
- Two repository styles: Firebase repos in `lib/repositories/*` and a legacy local Drift path (`lib/core/database`, `lib/core/medications/local_*`, `LocalMemberRepository` no longer used by Home since the member bar reads real profiles).
- 114 `TODO Backend` markers in `lib/`.
- Reminders are scheduled for the selected profile only.
- `ROADMAP.md` (Oct 2026, pre-Firebase) is stale; `firestore-debug.log` / `pubsub-debug.log` at the root are untracked noise.

## Suggested next steps
1. Deploy rules and the new indexes to staging (`firebase deploy --only firestore:rules,firestore:indexes --project medapp-staging`).
2. Run the real-phone reminder matrix (`docs/REMINDER_DEVICE_MATRIX.md`), iOS included.
3. Decide Blaze: it unlocks M11 (invites), server push, scheduled jobs, Trigger Email / Twilio, RevenueCat webhook, server-side AI.
4. Finish M2 Google / Apple sign-in; RevenueCat key (M12 step 5).
5. Clean up dead code and the duplicate repository layers.
