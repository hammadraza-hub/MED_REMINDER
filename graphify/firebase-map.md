# Firebase map

Status 2026-11-18, commit `727ebd7`. **Plan: Spark (free). No Cloud Functions, no Storage bucket, no server push.**

## Environments
| Env | Project | Region | Config file |
|-----|---------|--------|-------------|
| staging | `medapp-staging` | asia-south1 | `lib/firebase_options_staging.dart` ✅ |
| prod | `med-reminder-38e5c` | nam5 | `lib/firebase_options_prod.dart` ⚠️ gitignored (a fresh clone will not compile until it is created) |

Local emulators: Auth 9099, Firestore 8080 (`--dart-define=USE_EMULATOR=true`; Android reaches the PC at `10.0.2.2`).

## Services: what is used and what is not
| Service | State |
|---------|-------|
| Authentication | ✅ email + password; Google / Apple not built |
| Firestore | ✅ the only database; 32 rule blocks, default deny |
| Remote Config | ✅ kill switch, minimum version, FAQ |
| Crashlytics | ✅ with `SafeLog` scrubbing (no health text) |
| App Check | 🟡 client code ready (`AppCheckSetup`); **enforcement is a console step, not switched on** |
| FCM | 🟡 device token saved in `users/{uid}/devices`; `LocalOnlyPushService` — no server push |
| Local notifications | ✅ Android verified (real alarm on the emulator); iOS not tested on a device |
| Cloud Functions | ⬜ `functions/src/index.ts` is a 32-line scaffold, **nothing deployed** |
| Storage | ⬜ `storage.rules` = deny all; no bucket |
| RevenueCat | 🟡 SDK + paywall + guard; needs the API key; webhook needs Blaze |
| Trigger Email, Twilio | ⬜ not built (Blaze) |
| Drug catalog | 🟡 `drug_repository` + openFDA labels from the app; no `syncRxnorm` function |
| AI assistant | 🟡 client side with consent and safety layers; the server function was **not** built |

## Firestore collections vs rules (`firestore.rules`, 1855 lines)
Write access follows the role in `profiles/{pid}`: owner, caregiver (with `permissions.editMedications` / `logDoses`), viewer (read only). Health data is also limited by `healthUids`. List queries require membership (M21 closed the list holes).

| Path | Who may do what | Notes / module |
|------|-----------------|----------------|
| `users/{uid}` | owner only; legal, settings, deletion request | M2 M13 M14 |
| `users/{uid}/devices` | owner, 5 token fields only | M8 |
| `users/{uid}/limits/{day}` | owner; daily counters (posts 20, comments 100, reports 20, tickets 5), written in the same batch as the action | M21 |
| `profiles/{pid}` | members read; owner updates non-security fields; roles / memberUids / permissions cannot change from a client (except self-leave); delete only after the 7-day grace | M3 M14 |
| `…/medications` (+ `inventoryEvents`) | owner / caregiver with `editMedications`; stock writes bounded | M5 M9 |
| `…/doses` | create validated; update = log (`logDoses`) or regenerate (`editMedications`); overdue sweep to `missed` only; delete only pending | M6 M7 |
| `…/dailySummaries` | read only for members (computed in the app, no client write) | M7 |
| `…/allergies`, `…/pharmacies` | shape rules | M3 M9 |
| `…/vitals`, `…/vitalsDaily`, `…/symptoms` | owner / caregiver with health access; a vital cannot change (except note) | M15 |
| `…/prescribers`, `…/appointments`, `…/doctorNotes` | writes need `ownerIsPro` (Solo Pro gate); reads / deletes stay open | M16 |
| `customers/{uid}` | owner read; **no client write** (webhook would write on Blaze) | M12 |
| `config/*` | signed-in read, no write | M13 |
| `supportTickets` | create own, read own, immutable | M13 |
| `users/{uid}/chatThreads/{id}/messages` | the user only; AI consent required to start a thread | M18 |
| `communityProfiles`, `groups`, `posts` (+ `comments`, `votes`, `bookmarks`), `blocks`, `reports` | public to signed-in users by design; hidden posts only for moderator / author; reports create-only | M19 |
| everything else | `match /{document=**}` denies; collection-group queries not allowed | M21 |

**Not in rules, so every call is denied:** `invites` (M11 blocked), `exportJobs`, `mail`, `drugs`.

## Indexes (`firestore.indexes.json`) — **must be deployed**
| Collection | Fields | Used by |
|---|---|---|
| `doses` | medicationId ↑, scheduledAt ↑ | top-up, history |
| `doses` | medicationId ↑, status ↑, scheduledAt ↑ | delete future pending doses |
| `doses` | status ↑, missDeadline ↑ | **M22 overdue sweep** (new) |
| `medications` | status ↑, updatedAt ↑ | meds list |
| `vitals` | type ↑, measuredAt ↓ | vitals list |
| `chatThreads` | profileId ↑, updatedAt ↓ | AI chat history |
| `posts` | hidden ↑, createdAt ↓ | community feed |

The emulator does not enforce indexes, so these have **not** been proved against real Firestore.

## Tests and tools
- `tests/firestore.rules.test.js` + `tests/firestore.rules.m21.test.js`: **443 rules tests** (jest, `maxWorkers: 1`, wipes the emulator).
- `tools/audit_rules_probe.js`: role × collection probe, **0 gaps**.
- 15 emulator integration files in `integration_test/` (real repositories + real rules), including the caregiver loop, dose zones, real alarms.
- `tools/seed_community.js`, `set_moderator.js`, `cleanup_community.js`.
- CI `.github/workflows/firebase.yml`: rules tests (`npx jest tests --runInBand`) on PRs; deploys rules + indexes to staging on push to `main`. Rules and the new `doses` index are **not deployed yet** (last deploy before M21 / M22).

## What needs Blaze (not built)
Cloud Functions (triggers, callables, scheduled jobs, task queues), FCM push fan-out, nightly dose generation, refill job, Trigger Email, Twilio, RevenueCat webhook → `customers/{uid}`, server-side AI, caregiver invites (`memberUids` change), RxNorm sync, export jobs, server-side moderation, Storage avatars.

## Docs
`docs/firestore-schema.md` (data layout), `docs/PRODUCTION_RUNBOOK.md` (deploy, App Check, secrets, rollback), `docs/REMINDER_DEVICE_MATRIX.md`.
