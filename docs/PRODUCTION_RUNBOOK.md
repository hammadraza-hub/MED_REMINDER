# MedRemind — Production runbook (M21 step 7)

Written at the end of M21 (security and production hardening). It says what is
protected today on the **Spark** plan, what must be done before real families
use the app, and exactly what to do once the project is moved to **Blaze**.

Nothing in this file has been done against a real Firebase project yet: all
code and rules were tested on the local emulators. Items marked **[CONSOLE]**
are clicks or commands in the Firebase / Google Cloud console, **[BLAZE]** need
the Blaze plan, **[DEVICE]** need a real phone.

---------------------------------------------------------------------------

## 1. Where things stand (Spark, end of M21)

| Area | State |
|---|---|
| Firestore rules | Default deny, list rules fixed (profiles / medications / doses members only), dose create / update validation, bounded stock writes, shape rules for allergies, pharmacies, events, settings, devices, **daily limits** (posts 20, comments 100, reports 20, tickets 5). 443 rules tests + a probe of 161 role checks, all green. **Not deployed yet.** |
| Logs, crash reports, analytics | Release logs redacted (`SafeLog`), Crashlytics gets only the kind / code of an error, no analytics SDK, analytics and ad id off in Android / iOS config. A source scan test fails on risky log lines. |
| Lock screen and device | Reminders say "Medication reminder" (names hidden by default, user switch), recent-apps screen blank (Android), cover (iOS, untested), Android auto-backup off. |
| App Check | App side done (debug provider in debug / emulator / staging test builds, Play Integrity + DeviceCheck in production). **Enforcement is OFF.** |
| Secrets | Scan clean. Gemini key only in the gitignored `.env`. A guard test fails on a secret in the source. |
| Server side | `functions/` is the empty template. Nothing runs on a server. |

What Spark **cannot** give you (so it is not claimed anywhere): server-side
checks, secrets in Secret Manager, backups / point-in-time recovery, budget
alerts, alerts when a job stops, rate limits for AI / SMS, App Check on callable
functions.

---------------------------------------------------------------------------

## 2. Before the first real user (Spark is enough for all of this)

Do these in order. Tick each box.

### 2.1 Rules and indexes
- [ ] `firebase deploy --only firestore:rules --project staging` (alias in `.firebaserc`; production is `prod`).
- [ ] `firebase deploy --only firestore:indexes --project staging`. The indexes the app needs (a real project refuses queries without them, the emulator does not):
  `doses (medicationId, scheduledAt)`, `doses (medicationId, status, scheduledAt)`,
  `medications (status, updatedAt desc)`, `vitals (type, measuredAt desc)`,
  `chatThreads (profileId, updatedAt desc)`, `posts (hidden, createdAt desc)`.
  Wait until every index shows **Enabled** in the console (can take minutes).
- [ ] Run the app against staging and tick through: sign up, Home doses, mark taken, Meds add / edit / archive, Calendar, Vitals, Doctors, Reports, AI history, Community post / comment / report, support ticket, data export, account deletion request. Any `permission-denied` in `adb logcat` is a rule problem.
- [ ] Repeat for production (`--project prod`) after the staging pass. The CI workflow already deploys rules and indexes on a merge to `main` (staging) and on a release (production); it now runs **all** rules tests (`npx jest tests --runInBand`).

### 2.2 Seed and configuration
- [ ] Community groups: `node tools/seed_community.js --project <id> --production` (needs `GOOGLE_APPLICATION_CREDENTIALS`, run `npm ci` in `functions/` first).
- [ ] A moderator: `node tools/set_moderator.js --project <id> --email <moderator>` (sets the `moderator` custom claim with the Admin SDK; the person signs in again).
- [ ] Remote Config values for the app gate (minimum version, maintenance, terms and privacy versions) and `config/faq`.
- [ ] The stored notification setting `hideMedicineNamesOnLockScreen` of any test account that pressed Save before M21 step 4 is `false` (the old screen always wrote false). Reset those accounts, or ask testers to open Settings > Notifications and check the switch.

### 2.3 Keys and App Check
- [ ] **[CONSOLE]** Restrict the Firebase API keys (Google Cloud console > APIs and services > Credentials): Android = package `com.medreminder.app` + SHA-1 of the debug / upload / Play signing keys, iOS = bundle id, API restriction = only the Firebase APIs the app uses.
- [ ] App Check runbook: see HANDOFF, "M21 step 5". Short form: register Play Integrity (needs the Play Console link) and DeviceCheck, add debug tokens, ship with enforcement OFF, watch the verified percentage 1-2 weeks, enforce on staging, then production.
- [ ] Force-update gate (Remote Config, M13) to retire app versions that predate App Check before enforcing.

### 2.4 Devices **[DEVICE]**
- [ ] Build a **release** APK and run it on a real Android phone. Check `adb logcat` while using the app: no e-mail address, no uid / long id, no medicine name (the redaction only runs in release / profile builds).
- [ ] Fire a real reminder on that phone: lock screen shows "Medication reminder" only; with the switch off it shows the medicine.
- [ ] Recent-apps list shows a blank card for the app.
- [ ] Force a test crash (debug menu or a throwaway button) and read it in Crashlytics: only an error kind / code, no message with names.
- [ ] iOS (needs a Mac): the app-switcher cover, DeviceCheck key, and (better) the App Attest capability.

### 2.5 Legal and consent
- [ ] Privacy policy and terms match what the app really does (see section 5: data map). Bump the versions in Remote Config so existing users are asked again.
- [ ] AI assistant: consent screen text names the AI provider. Do not switch the AI on for real users until the provider is covered by a signed agreement for health data (section 5).

---------------------------------------------------------------------------

## 3. Moving to Blaze (do in this order)

Nothing here is needed to start on Spark. Do it when you want: server-side
checks, the AI assistant, SMS to caregivers, subscriptions webhooks, backups.

### 3.1 Cost safety first **[BLAZE] [CONSOLE]**
1. Upgrade the project (staging first, then production).
2. **Budget alerts on both projects**: Google Cloud console > Billing > Budgets and alerts > Create budget, scope = the project, amount small at first (for example USD 5 for staging, USD 20 for production), alert at 50 %, 90 %, 100 % to your e-mail. A budget alert does **not** stop spending; it only tells you. For a hard stop, add a function that disables billing on the 100 % Pub/Sub message (Google's "cap billing" recipe) only if you accept an outage.
3. In `functions/src/index.ts` keep `setGlobalOptions({ maxInstances: 5 })` (already in the template) so a traffic spike cannot run up the bill.

### 3.2 Backups **[BLAZE] [CONSOLE]**
1. **Point-in-time recovery** (7 days of history): `gcloud firestore databases update --database='(default)' --enable-pitr --project <id>` (or Firebase console > Firestore > Disaster recovery). Check the flags against the current gcloud documentation before running.
2. **Scheduled backups**: `gcloud firestore backups schedules create --database='(default)' --recurrence=daily --retention=14d --project <id>` (weekly for production if cost matters).
3. **Test a restore once** and write the date here: restore the newest backup into a NEW database (`gcloud firestore databases restore --source-backup=<backup> --destination-database=restore-test`), open a few documents, then delete the test database. Re-test after any large schema change.
4. Auth users are **not** part of a Firestore backup: export them from time to time (`firebase auth:export users.json --project <id>`) and keep the file in a restricted place (it holds password hashes).

### 3.3 Secrets in Secret Manager **[BLAZE]**
- Keep every secret out of the app and out of git: Gemini / Claude key, Twilio SID + token, RevenueCat webhook secret, interaction-checker vendor key.
- `firebase functions:secrets:set GEMINI_API_KEY` (and the others), then in the function: `const geminiKey = defineSecret("GEMINI_API_KEY"); export const aiChat = onCall({ secrets: [geminiKey] }, ...)`.
- Rotate the Gemini key that lives in the local `.env` once the function is live, and delete it from the PC.

### 3.4 Functions that replace Spark workarounds **[BLAZE]**
| Spark workaround today | Replace with | Then tighten |
|---|---|---|
| The app marks overdue doses `missed` itself (`markOverdueDosesMissed`) | Scheduled function `markMissedDoses` (every 1-5 minutes) | Rules: remove `overdueSweepOnly()`, `missed` becomes server-only |
| The app writes `quantityOnHand` (bounded by `validStockChange`) | Function that updates stock from inventory events | Rules: block `quantityOnHand` again for clients |
| Daily limits counted by the rules | Same limits inside the callable / trigger functions (Admin SDK, no client counter) | Keep the rule counters as a second layer, or remove them |
| Support ticket only stored | E-mail the support inbox (Trigger Email extension or a function) | — |
| `invites` has no rules (caregiver add) | Callable `inviteCaregiver` / `acceptInvite` that edits `memberUids`, `roles`, `healthUids`, `permissions` | Rules stay: clients can never write those fields |
| AI assistant "unavailable" | Callable `aiChat` with the safety layers of M18 and `defineSecret` | Rules: `users/{uid}.aiConsentAt` check inside the function |

### 3.5 Heartbeat alert for `markMissedDoses` **[BLAZE]**
Caregiver alerts depend on that job, so a silent stop must be noticed.
1. The job writes `config/jobs { markMissedDosesAt: <server time> }` at the end of every run (Admin SDK; rules already forbid client writes to `config`).
2. A second scheduled function (every 5 minutes) reads it; if it is older than 5 minutes it logs an `ERROR` with a fixed text (`markMissedDoses heartbeat stale`).
3. Cloud Monitoring > Alerting > Create policy > **Log-based alert** on that error text > notification channel = your e-mail / SMS. Also add an alert on function **errors** and **execution count = 0** for `markMissedDoses`.
4. Test it once: disable the job, wait 6 minutes, confirm the alert arrives, enable the job again.

### 3.6 Rate limits and abuse **[BLAZE]**
- Per-user daily counter documents written by the **functions** (clients cannot write them): `users/{uid}/limits/{day}` already exists for the Spark limits; use a separate field set for server limits (AI messages per day, invites per day, SMS per day).
- **SMS** (only if caregivers get SMS): send only to a number the user verified, cap sends per user per day, restrict Twilio geo-permissions to the countries you serve, and alert on a spike (SMS pumping fraud).
- **App Check on callables**: `onCall({ enforceAppCheck: true }, ...)` once the console shows nearly all traffic verified.
- **Sign out of all devices**: callable `signOutEverywhere` = `admin.auth().revokeRefreshTokens(uid)` (the app already returns to the sign-in screen when the session ends: `SessionGuard`).

---------------------------------------------------------------------------

## 4. Monitoring (what to look at, how often)

| What | Where | How often |
|---|---|---|
| Crash free users, new crash types | Firebase Crashlytics | weekly, daily after a release |
| App Check verified vs unverified | App Check > APIs | daily until enforced, then weekly |
| Firestore reads / writes / deletes, `permission-denied` spikes | Firebase usage + Cloud Monitoring | weekly |
| Spend vs budget | Billing > Budgets | weekly |
| Failed job heartbeat | the alert in 3.5 | automatic |
| Community reports | `reports` collection (moderator screen) | daily once the community is open |
| Support tickets | `supportTickets` in the console | daily |

Incident (data exposure suspected): 1) set App Check / rules to deny (deploy a rules file with `allow read, write: if false;` for the affected collection), 2) rotate the affected keys, 3) check Cloud Audit Logs for the time window, 4) tell affected users and, where a law requires it, the authority; keep a written timeline.

---------------------------------------------------------------------------

## 5. Data protection (HIPAA-style) checklist

The app is **not** a covered entity under HIPAA (PRD risk 2) but users expect the
same care. Facts below were checked in the code; legal claims about what a
Google agreement covers must be **verified against Google's current documents**
(Google Cloud BAA and the list of covered services) before anyone relies on
them: the list changes and is not reproduced here.

### 5.1 Data map: where health data is and where it goes

| Data | Where it lives | Leaves the phone? |
|---|---|---|
| Profiles, medications, doses, allergies, vitals, symptoms, doctors, appointments, notes, inventory | Firestore `profiles/{id}/...` (rules: members only, health records need `healthUids`) | Only to Firestore |
| Account settings, AI consent, community id | Firestore `users/{uid}` (own only) | Only to Firestore |
| Offline copy | Firestore cache on the phone; Android auto-backup is OFF | No |
| Reminders | Local notifications; names hidden by default; payload = ids only | No |
| Reports / data export (PDF, CSV, ZIP) | Built on the phone, shared by the user through the system share sheet, temp file deleted after | Only where the user sends it |
| AI assistant | Not active on Spark. After Blaze: context + question go to the AI provider through a function, after consent | Yes (consent) |
| FDA label lookup | The medicine name / RxCUI is sent to the public FDA API when the user asks | Yes (user action) |
| Health Connect / HealthKit | Read on the phone, stored in Firestore as vitals | Only to Firestore |
| Crash reports | Kind and code of the error only | Yes (no health data by design) |
| Analytics, ad id | None | No |
| Push messages | No text, no health data (push is not active on Spark) | — |
| Subscriptions | RevenueCat with an anonymous app user id, no attributes | Yes (no health data) |

### 5.2 Checks
- [x] No health data in logs, crash reports or analytics (code, tests).
- [x] No secret in the source or the app bundle (scan + guard test).
- [x] Lock screen, recent apps, backups (code, tests, emulator).
- [x] Rules tested for owner, co-manager (caregiver with permissions), caregiver without permission, viewer, stranger, signed-out.
- [x] Account deletion: 7-day grace, then the purge removes profiles owned by the user, chats, community profile, bookmarks, blocks, devices, daily counters, the user document and the Auth account; community posts stay as "[deleted]".
- [x] Export: the user can download all their data as a ZIP.
- [ ] **[CONSOLE]** Check the current Google Cloud BAA scope for each service in use (Firestore, Authentication, Cloud Functions, Crashlytics, FCM, Remote Config, App Check) and decide what is acceptable. Keep health data out of Crashlytics, FCM text and analytics either way (already the case).
- [ ] **AI provider:** use a provider and a product that is covered by an agreement for health data (for example a cloud-hosted model offering with a BAA) rather than a consumer API key. Do not send names, e-mail, phone or ids (the M18 context builder already removes them; `integration_test/ai_context_test.dart` checks it).
- [ ] Tell users in the privacy policy: what is stored, the FDA lookup, the AI provider, how to export and delete.
- [ ] Review who has Firebase console access (it can read all data); use least privilege and two-step sign-in on those accounts.

---------------------------------------------------------------------------

## 6. Known open items at the end of M21

- Rules and App Check are not deployed / enforced yet (sections 2.1, 2.3).
- `invites` (adding a caregiver) has no rules and no flow that works on Spark: a design decision, best done with a Blaze function (section 3.4).
- `users/{uid}.legal` / `legalVersions` and extra fields on `medications` updates are still free-form (low risk).
- The iOS parts (app-switcher cover, DeviceCheck / App Attest) are untested (no Mac).
- The stray tracked file `lib/features/meds/meds_screen_restored.dart` (unused backup) is still in the repository.
- `SettingsRepository.getSettings` was called with a profile id by the reminder scheduler (fixed in step 4). A similar mistake elsewhere shows up as a `permission-denied` on `users/<profileId>` in the log: look for it during the staging pass.

---------------------------------------------------------------------------

## 7. Commands for the final check (run before every release)

```bash
# 1. Static analysis (errors must be 0)
dart analyze lib test integration_test

# 2. Unit and widget tests
flutter test

# 3. Rules tests (all files, one after another) - start the emulator first
firebase emulators:start --only auth,firestore --project medapp-staging
npx jest tests                 # package.json: maxWorkers 1
node tools/audit_rules_probe.js   # must print "0 gaps"

# 4. Emulator integration tests (Android emulator; reseed after jest, which wipes Firestore)
flutter test integration_test/<file>.dart -d emulator-5554 \
  --dart-define=ENV=staging --dart-define=USE_EMULATOR=true

# 5. Release build and the device checks of section 2.4
flutter build apk --release --dart-define=ENV=prod
```
