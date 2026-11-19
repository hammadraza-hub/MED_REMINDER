# Feature map (lib/features → data source → module)

Status 2026-11-18, commit `727ebd7`. 127 Dart files under `lib/features/`. Every screen has (or had) a sibling `*_data.dart` view-model / adapter; newer modules put the logic in `lib/core/<area>/` (pure, tested) and keep the screen thin.

| Feature dir (files) | Key screens | Data source today | Logic lives in | Module |
|---|---|---|---|---|
| `onboarding` (6) | splash (auth routing), onboarding, create account, `post_auth_router`, legal re-consent, app blocked (kill switch / version gate) | FirebaseAuth, Remote Config, `users/{uid}` | `lib/core/app_gate.dart`, `legal_gate.dart`, `app_startup.dart` | M2 M13 |
| `auth` (3) | login, signup, reset password | FirebaseAuth + `users/{uid}` | `auth_repository` | M2 |
| `profile` (10) | health profile, profiles (switcher), family setup, invite member, member permissions, received invites, notification setup | `profiles/{pid}` (roles, permissions); **invites = local only / stub** | `ProfileController`, `profile` repos | M3 M8 M11 |
| `meds` (39) | meds list, add (search / scan / manual), review scan, detail, edit, schedule picker, discontinue, allergies, interaction warning, inventory + adjust count, refill alert, pharmacy, side effects, add symptom, appointments, add appointment, doctor notes | `medications`, `allergies`, `pharmacies`, `inventoryEvents`, `symptoms`, `appointments`, `doctorNotes` | `medication_repository`, `dose_engine`, `interaction_checker` (static) | M4 M5 M9 M10 M15 M16 |
| `home` (16) | home (today's doses, dose sheet, streak chip, reminder-permission card, bell), notifications (App / Medicine chips), streaks & stats, vitals list / chart / add entry | `doses` (stream, day cut in the profile zone), `profiles` (member bar, real profiles), `vitals`, `vitalsDaily` | `HomeSummary`, `HomeDoseFilter`, `StreakHistory`, `HomeDay`, `FirestoreMemberRepository`, `HomeDoseSource` | M7 M15 |
| `calendar` (5) | calendar, adherence detail, missed-dose reason | `doses`, `dailySummaries` (computed) | `dose_repository` | M7 |
| `doctors` (2) | doctors list, add doctor | `prescribers` (Solo Pro gate for writes) | `lib/core/doctors/*` | M16 |
| `reports` (2) | report builder / preview, PDF viewer | `doses`, `medications` (read) | `lib/core/reports/*` (adherence, CSV, PDF, share, Pro rule) | M17 |
| `assistant` (5) | AI consent, chat, history, gate | `users/{uid}/chatThreads/{id}/messages`, consent in `users/{uid}`, FDA labels (openFDA) | `lib/core/ai/*` (safe context, safety layers, reply checker) | M18 |
| `community` (13) | gate / profile, groups list, group feed, compose, post + comments, saved, blocked, moderation | `communityProfiles`, `groups`, `posts` (+ comments, votes, bookmarks), `blocks`, `reports` | `lib/core/community/*` | M19 |
| `settings` (29) | settings, account, notifications (dose switch, escalation, quiet hours, lock-screen privacy), language, accessibility, privacy & security (app lock), data export, account purge, help & support, submit request, about, subscription, upgrade (paywall), compare plans, payment success | `users/{uid}.settings`, `customers/{uid}`, `supportTickets`, Remote Config, RevenueCat | `lib/core/export/*`, `account_*`, `subscription/*` | M2 M8 M12 M13 M14 M21 |

## Cross-feature services (`lib/core/services`, 29 files)
Reminders (`reminder_scheduler`, `reminder_action_queue`, `appointment_reminders`), push stub (`push_service`, local only), health sync, OCR / camera, FDA label, AI consent, account deletion + purge, preferences sync, Pro access, connectivity, session / access guards, app lock, app check setup, community services (feed, post, profile, reaction, safety, moderation), report service.

## Known weak spots
- Dead files in `meds`: `meds_screen_restored.dart`, `add_manual_screen.dart`, `review_scan_screen.dart` (see modules-progress "Tech debt"). The dead Home files (`dashboard_screen.dart`, `dose_action_sheet.dart`) were deleted.
- `received_invites_screen` / `invite_member_screen` do not talk to Firestore yet (M11 blocked).
- Some screens still import `cloud_firestore` directly (`calendar`, `meds`, `profile`); new code goes through repositories.
