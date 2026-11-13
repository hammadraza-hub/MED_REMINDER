# HANDOFF — read this first (for any agent or developer continuing the project)

Project: **MedRemind** — Flutter medication-reminder app on Firebase. Repo: `github.com/hammadraza-hub/MED_REMINDER`, branch `main`.
Authoritative plan: `Medicine-App-Backend-Modules-Firebase.pdf` (modules M0–M23, kept untracked at repo root). Status of each module: [modules-progress.md](modules-progress.md).
Owner writes in Roman Urdu/English mix; reply in the language the user uses.

## 1. Hard constraints (do not violate)
1. **Firebase Spark plan** (no Blaze). Therefore **no Cloud Functions can be deployed** and no Storage bucket. Anything needing server logic is either done client-side or left as a stub with a TODO naming the module. `functions/src/index.ts` is an empty scaffold.
2. **Medical data lives only under `profiles/{profileId}/…`**, never under `users/{uid}` (schema: `docs/firestore-schema.md`, locked v1.0).
3. **Never delete medications or logged doses** — archive them. Rules enforce this.
4. **Never commit secrets**: `.env`, `lib/firebase_options_prod.dart`, `google-services.json` are gitignored. No API keys in the app (AI/RevenueCat keys come via `--dart-define` or `.env`).
5. Default env is **staging** (`medapp-staging`). Never point dev builds at prod (`med-reminder-38e5c`).
6. One module at a time; verify rules tests pass before moving on; ask before pushing.

## 2. Setup & commands (Windows, PowerShell/Git Bash)
```bash
flutter pub get
flutter gen-l10n                      # after editing lib/l10n/*.arb
dart run build_runner build --delete-conflicting-outputs   # after editing Drift tables (app_database.dart)
flutter analyze
flutter test                          # 3 smoke tests only
flutter run --dart-define=ENV=staging
flutter run --dart-define=ENV=staging --dart-define=USE_EMULATOR=true   # emulators: Firestore 8080, Auth 9099, Functions 5001; Android reaches PC at 10.0.2.2
flutter run --dart-define=REVENUECAT_API_KEY=<key>                     # M12; default is a placeholder
```
Firestore rules tests (needs Java + firebase-tools; 30 cases):
```bash
npm ci
firebase emulators:exec --only firestore --project medapp-staging "npx jest tests/firestore.rules.test.js --runInBand --testTimeout=30000"
```
CI: `.github/workflows/firebase.yml` runs the same on PRs and deploys rules+indexes to staging on push to `main`.

**Fresh-clone gotcha:** `lib/config/app_config.dart` imports `lib/firebase_options_prod.dart`, which is gitignored. A fresh clone will not compile until you create it (`flutterfire configure --project=med-reminder-38e5c`, output renamed) or a stub exporting `DefaultFirebaseOptions`/`FirebaseOptions` for prod. Same for `android/app/google-services.json`.

## 3. Code conventions (follow these)
- **Layering:** `features/*/screen.dart` → `*_data.dart` (view-model/adapter) → repository → Firestore/Drift. Screens never call Firestore directly except legacy spots in `calendar`, `home/streaks_stats`, `meds/*`, `profile/*` (they still import `cloud_firestore`; migrate toward repos when touched).
- **Repositories:** Firebase impls in `lib/repositories/firebase_*_repository.dart`, singleton via `.instance`; interfaces/domain types for newer modules in `lib/core/<area>/`. Errors → `AppException` (`lib/core/app_exception.dart`). Callable functions go through `FunctionsClient` (`lib/core/functions_client.dart`).
- **Doses:** doc id = `{medId}_{yyyyMMddHHmm}`; generated client-side by `DoseEngine` (`lib/core/dose_engine.dart`: `generateDoses`, `generate14DayDoses`, daily/weekdays/cyclical/taper; PRN ids via `generatePrnDoseId`). `MedicationRepository` writes doses on create/update and deletes future pending ones.
- **Dose logging:** `DoseRepository.logDose / logPrnDose / snoozeDose / undoDose / markOverdueDosesMissed / getDailySummary / getAdherence{7,30,90}Days`. Rules block clients from writing `dailySummaries` (`allow write: if false`) — summaries are computed by repo reads, so do not add client writes there.
- **Reminders:** `ReminderScheduler.instance` (local notifications, Android only, 48 h window, max 100, escalation count 3, minutes read from `users/{uid}.settings`). Call `rescheduleAll()` after any med/dose change. Notification actions are queued via `reminder_action_queue.dart`.
- **Profile context:** `ProfileController.instance` holds the selected profile/member; `AuthRepository` creates `users/{uid}` + "self" profile on sign-up and restores selection on login.
- **Localization:** add keys to **all five** `lib/l10n/app_{en,es,fr,ar,hi}.arb` (en has `@key` metadata), run `flutter gen-l10n`, use `AppLocalizations.of(context)`. Initialize l10n in `didChangeDependencies`, not `initState` (past crash). es/fr/ar are currently ~34 keys behind en/hi.
- **Colors/theme:** use `lib/core/constants/app_colors.dart`; avoid raw hex.
- **Rules changes:** every rule change needs a case in `tests/firestore.rules.test.js`. Rules use helpers `signedIn, isMember, isOwner, canRead, canWrite, canEditMedications, canLogDoses, canViewHealth`; list queries can't use `get()`, hence the get/list split.
- **Commits:** message style `M<n>: <what>` / `feat(M<n>): …` / `chore:` / `docs:`; one logical change per commit.

## 4. Where things are
| Need | Path |
|------|------|
| Entry / startup order | `lib/main.dart`, `lib/main_shell.dart` |
| Env config | `lib/config/app_config.dart`, `remote_config_service.dart` |
| Models | `lib/models/*` |
| Firebase repos | `lib/repositories/*` |
| Domain interfaces + legacy local Drift repos | `lib/core/**` |
| Drift DB | `lib/core/database/app_database.dart` (+ generated `.g.dart`) |
| Services | `lib/core/services/*` (scheduler, push, OCR, camera, AI) |
| Screens | `lib/features/<area>/` — see [feature-map.md](feature-map.md) |
| Rules / tests / indexes | `firestore.rules`, `tests/firestore.rules.test.js`, `firestore.indexes.json` |
| Schema | `docs/firestore-schema.md`, [firebase-map.md](firebase-map.md) |

## 5. Known issues / traps
- Two parallel repo layers (`lib/core/*` vs `lib/repositories/*`) with duplicate interface names (`dose_repository.dart` in both). Check which one a screen imports before editing.
- Leftover files: `meds_screen_restored.dart`, `add_manual_screen.dart` (vs `add_medication_manual_screen.dart`), `settings/allergy_screen.dart` (vs `meds/allergies_screen.dart`). Verify usage with grep before deleting.
- M11 caregiver repo (`lib/repositories/firebase_caregiver_repository.dart`) is a stub that throws — invite/permission screens cannot work on Spark.
- `ROADMAP.md` (Oct 2026) is stale; the PDF plan and this folder supersede it.
- Dart analyzer previously reported ~15 info/warn issues (`activeColor` deprecations, doc-comment lints).
- `.env` must not be listed under `flutter: assets:` in pubspec (check before release).

## 6. Work queue (in order)
**A. M12 Subscriptions — finishing without Blaze/RevenueCat key (in progress, user doing step by step)**
1. ✅ `customers/{uid}` rule + 4 tests (commit `0d60195`).
2. ✅ (done, uncommitted) `cancelSubscription`: remove Firestore `update` in `firebase_subscription_repository.dart`; open Play Store subscriptions page via `url_launcher` (`https://play.google.com/store/account/subscriptions`); wire from `subscription_screen.dart` (~line 110).
3. ✅ (done, uncommitted) Placeholder-key guard (`SubscriptionService.isConfigured`, `SubscriptionUnavailableException`) in `subscription_service.dart`: if key is empty/`your_revenuecat_api_key_here`, skip `Purchases.configure`, keep `_initialized=false`, and make other methods throw a clear error so the upgrade screen shows "plans unavailable".
4. ✅ (done 2026-11-12, Android emulator + Firebase emulators) UI test by writing `customers/{uid}` docs in the emulator UI (`active/trial/canceled/expired`).
5. After a RevenueCat key (or Test Store key) exists: `Purchases.logIn(uid)`/`logOut` on auth changes; derive premium from `CustomerInfo` entitlements; verify purchase on device.
6. Needs Blaze (blocked): RevenueCat webhook → `customers/{uid}`; server-enforced profile limit.

**B. Next modules by value:** M2 Google sign-in (`login_screen.dart:403`) + Terms/Privacy screen (`signup_screen.dart:727`) → M22 unit tests for `DoseEngine`, `ReminderScheduler`, repos → M8 iOS notifications → M10 safety checks beyond the static map → M13/M14 (support tickets, export, delete account) → Phase 2/3 UI-only modules.

**C. Housekeeping:** localization of remaining ~80 feature files; remove dead files; consolidate repo layers; refresh `graphify/` after each module.

## 7. Definition of done for a module step
`flutter analyze` clean for touched files · rules tests green (if rules touched) · strings in 5 ARBs · feature works on staging/emulator · `graphify/modules-progress.md`, `progress.json`, `CHANGELOG.md` updated · committed with `M<n>:` message.

## 8. Code knowledge graph (Graphify tool)
Generated with [Graphify](https://github.com/Graphify-Labs/graphify) (`pip install graphifyy`, CLI `graphify`). Output is in `graphify-out/`: `GRAPH_REPORT.md` (hubs/communities), `graph.json` (queryable), `graph.html` (visual, aggregated). Last rebuilt 2026-11-12 after commit `211a0ff` (M12 steps 1-4): 4,903 nodes, 6,222 edges, 207 communities, Dart supported, no LLM/API cost. `.graphifyignore` excludes platform folders, build output and generated files.
```bash
graphify update .                         # refresh after code changes (free, AST only)
graphify query "how are doses logged?"    # traverse the graph
graphify explain "ReminderScheduler"
graphify path "DoseEngine" "DoseRepository"
graphify affected "Dose"                  # what breaks if this changes
```
Caveats: some Dart nodes are noisy (`_`, `with`, `dependencies` from yaml/json); trust file-level and class-level nodes. The hand-written docs in this folder are the source of truth for *status*; the graph is for *structure*.

### M12 UI test notes (2026-11-12, verified on Android emulator)
- Verified: no-key guard ("Purchases are not available right now."), states none/active/trial/canceled/expired render correctly, Cancel opens Chrome → Play Store subscriptions page.
- Bug found+fixed: `SubscriptionInfo.hasPremiumAccess` ignored `canceled` with a future `expiresAt` (user lost Pro early). Now stays premium until expiry.
- Open UI nits (not fixed): plan shows raw id (`annual_premium`) and raw status; footer says "App Store Settings" on Android; "Cancel Plan" button still shown for already-canceled plans; Subscription screen loads once (no live `watchSubscription`).
- Test recipe: `firebase emulators:start --only auth,firestore --project medapp-staging`; `flutter run -d <android> --dart-define=ENV=staging --dart-define=USE_EMULATOR=true`; seed `customers/{uid}` via emulator REST (`Authorization: Bearer owner`) or Emulator UI at :4000. Local app may hold a stale saved login whose profile/user docs must be seeded first.

## 9. M13 — Settings, Support & Remote Config (in progress)
Plan steps (Spark unless noted): **1** Remote Config keys + force-update/maintenance gate + real version ✅ · **2** legal-version re-prompt ✅ · **3** sync language/accessibility into `users/{uid}.settings` ⏳ · **4** `config/faq` rule+repo+Help screen ⏳ · **5** `supportTickets` rule+form (mailto fallback) ⏳ · **6** biometric app lock (`local_auth`) ⏳ · **7** `onTicketCreated` email function (needs Blaze) ⛔.
Step 1 (done, 2026-11-13): `AppInfoService` (package_info_plus), `AppGate` (pure logic, `lib/core/app_gate.dart`), `RemoteConfigService` now has `terms_version`, `privacy_version`, `disclaimer_text`, `gateStatus`; splash shows `AppBlockedScreen` (update/maintenance, 5 locales) before routing; About shows real version. Tests: `test/app_gate_test.dart` (10). Gate is **not** testable with Firebase emulators (no Remote Config emulator) — set `min_app_version` / `maintenance_mode` in the staging console to see it live. RC fetch interval is 1 h, so "Try again" may not see a change immediately.
Emulator-testing gotchas learned: debug manifest now allows cleartext HTTP (needed for Auth emulator at 10.0.2.2); a stale saved login from the real staging project gives `INVALID_REFRESH_TOKEN` against the Auth emulator and the app hangs after Remote Config init — run `adb shell pm clear com.medreminder.app` and sign up fresh.

**M13 step 1 — full emulator verification (2026-11-13, Android 15 emulator + Firebase emulators):** update-required screen ✅ (button opens `play.google.com/store/apps/details?id=com.medreminder.app`), maintenance screen ✅ ("Try again" triggers an RC refresh), normal start passes the gate ✅, About shows "Version 1.0.0 (build 1)" ✅, Settings row trailing now real version ✅. Gate screens were forced with a temporary `GATE_TEST` debug override (removed afterwards; Remote Config has no emulator). Test login recipe: create user via Auth emulator REST, mark `emailVerified` via `accounts:update` with `Authorization: Bearer owner`, seed `users/{uid}` + `profiles/{pid}` (roles/memberUids/healthUids), `adb shell pm clear com.medreminder.app`, sign in.
Known issues found (not fixed): Settings "Preferences" 4th row opens Allergies but is labelled "About" (`_itemTitle` has no `allergies` case); About badge "UP TO DATE ✓" is static text; seeded test profile gave Allergies `permission-denied` (rules need fields the seed lacks) — seed data issue, not an app bug as far as known.

**M13 step 2 — legal re-consent (done 2026-11-13, verified on emulator):** `LegalGate` (pure, `lib/core/legal_gate.dart`) + `LegalService` (`lib/core/services/legal_service.dart`, fails open incl. 8 s timeout) + `AuthRepository.getAcceptedLegal/acceptLegal` + `LegalReconsentScreen` (5 locales) + `resolvePostAuthHome` used by splash AND login. Signup now writes the Remote Config `terms_version`/`privacy_version` instead of hard-coded `'1.0'`. Shared `LegalDocSheet` (`lib/widgets/legal_doc_sheet.dart`) now also opens from signup's Terms/Privacy links (was TODO). Tests: `test/legal_gate_test.dart` (9) + 3 new rules tests (33 total). Verified: legacy user / outdated accepted version -> prompt (login + splash paths); accept -> writes `users/{uid}.legal`+`legalVersions`, opens dashboard; relaunch -> no prompt.
Heads-up: 3 older smoke tests (`assistant_chat_smoke_test`, `report_preview_smoke_test`, `widget_test`) fail even on a clean checkout — pre-existing, unrelated. The placeholder Terms/Privacy text (ARB `aboutLegalBody*`, `aboutLegalComplianceValue`) claims "SOC-2 Type II Certified · HIPAA ... Verified 2025" — unverified compliance claim; replace with real legal text before launch.
