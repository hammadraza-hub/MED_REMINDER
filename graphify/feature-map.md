# Feature map (lib/features → data source → module)

| Feature dir | Key screens | Data source today | Module |
|-------------|-------------|-------------------|--------|
| `onboarding` | splash (auth routing), onboarding, create_account | FirebaseAuth | M2 |
| `auth` | login, signup, reset_password | FirebaseAuth + `users/{uid}` | M2 |
| `profile` | health_profile, profiles (switcher), family_setup, invite_member, member_permissions, received_invites, notification_setup | Firestore `profiles`; invites = stub | M3 / M8 / M11 |
| `meds` | list, add (search/scan/manual), detail, edit, schedule picker, discontinue, allergies, interaction warning, inventory, refill alert, pharmacy, side effects, symptoms, appointments, doctor notes | Firestore `medications`, `allergies`, `pharmacies`; appointments/notes dummy | M4 M5 M9 M10 M16 |
| `home` | dashboard, home, dose_action_sheet, streaks_stats, vitals list/chart/add | Firestore `doses`, `dailySummaries`; vitals Drift | M6 M7 M15 |
| `calendar` | calendar, adherence_detail, missed_dose_reason | Firestore `doses` | M7 |
| `doctors` | doctors, add_doctor | dummy | M16 |
| `reports` | report_preview | dummy/local | M17 |
| `assistant` | chat, history | `ai_service` (.env key) | M18 |
| `community` | community | dummy | M19 |
| `settings` | settings, account, notifications, language, accessibility, privacy_security, data_export, help_support, about, subscription, upgrade, compare_plans, payment_success | users/{uid}.settings, RevenueCat, Remote Config | M2 M8 M12 M13 M14 |

Pattern: each screen has a sibling `*_data.dart` holding view-model / dummy-or-repo adapter code.
