# Reminder device matrix (M22 step 7)

Reminders are local alarms (no server on the Spark plan), so they depend on the
phone's OS. This sheet says what was **proved on the Android emulator**, and
what a person must check on **real phones** before release.

## A. Proved on the Android emulator (Pixel 7 image)

Automated: `integration_test/reminder_scheduler_test.dart` (7 tests + 1 device
check). Run:

```bash
flutter test integration_test/reminder_scheduler_test.dart -d emulator-5554 --dart-define=ENV=staging --dart-define=USE_EMULATOR=true
```

| # | Scenario | Result |
|---|----------|--------|
| 1 | 3 pending doses -> 3 reminders + 3 escalations each = 12 pending OS alarms | pass |
| 2 | Rescheduling twice does not duplicate alarms | pass |
| 3 | A dose marked taken loses its alarms (12 -> 8) | pass |
| 4 | A dose 50 h away gets no alarm yet (48 h window) | pass |
| 5 | Short miss window (25 min) cuts the escalations to +10 and +20 | pass |
| 6 | "Dose reminders" switch off -> 0 alarms | pass |
| 7 | Switch on again -> alarms come back; quiet hours ON do not stop or move them | pass |
| 8 | **The OS alarm really fires** about 60 s after scheduling (exact alarm allowed, notification permission granted) and the posted text does not contain the medicine name (lock-screen privacy on) | pass |

Device check 8 needs the permissions granted right after the install, because
`flutter test` removes the app at the end:

```bash
flutter test integration_test/reminder_scheduler_test.dart -d emulator-5554 --dart-define=ENV=staging --dart-define=USE_EMULATOR=true --dart-define=FIRE=true --plain-name FIRE
# in a second terminal, as soon as the app is installed:
adb shell pm grant com.medreminder.app android.permission.POST_NOTIFICATIONS
adb shell cmd appops set com.medreminder.app SCHEDULE_EXACT_ALARM allow
```

Logic proved by unit tests (no device needed): alarm planning and the iOS 64 /
Android 200 caps (`dose_alarm_planner_test`), quiet hours for appointments
(`quiet_hours_test`), Taken / Skip / Snooze replay (`reminder_action_queue_test`),
overdue sweep rule (`overdue_sweep_test`), DST and time zones
(`dose_engine_test`, `dose_zone_test`).

## B. Must be checked by hand on real phones (not possible on the emulator)

Mark each row pass / fail with the phone model and OS version.

| # | Scenario | How | Expected |
|---|----------|-----|----------|
| 1 | Screen off, phone idle 30 min | Dose due in 30 min, lock the phone | Sound + vibration at the minute |
| 2 | Battery saver / Doze | Turn on battery saver, dose due in 15 min | Still on time (exact alarm); note any delay |
| 3 | Vendor battery killers (Xiaomi, Oppo / Realme, Vivo, Huawei, Samsung "sleeping apps") | Swipe the app away from recents, dose due in 10 min | Fires. If not: document the phone's "autostart / no restrictions" setting for the user |
| 4 | Reboot | Schedule a dose 10 min ahead, reboot at once | Fires after boot (boot receiver is in the manifest) |
| 5 | Notification permission refused (Android 13+) | Deny on first ask, then open the app | No crash; the app asks again from Settings; no reminders until granted |
| 6 | Exact alarm permission off (Android 14+) | Revoke "Alarms & reminders" | Falls back to inexact; may be a few minutes late; note it |
| 7 | Action buttons | Tap Taken / Skip / Snooze with the app closed, then open the app | The dose changes on app open (queue replay); the escalations stop |
| 8 | Escalation | Ignore a reminder | Repeats every N min (Settings), stops at the miss deadline and after Taken |
| 9 | Time zone change | Set the phone to another zone | Open the app: reminders are rescheduled for the new zone; the dose list follows the PROFILE zone |
| 10 | DST day | Phone date set to the day before a spring / fall change (region with DST) | One reminder per dose, none lost or doubled |
| 11 | Do Not Disturb | Turn DND on | Behaves as the phone's DND rules say; note it |
| 12 | Lock-screen privacy | Lock the phone, let a reminder arrive | Generic text, no medicine name (default); name only if the user turned the option off |
| 13 | Many doses | 12+ doses per day for 2 days | Nearest ones all ring; on iOS at most 64 alarms are held, the rest are added on the next app open |
| 14 | Appointment reminder in quiet hours | Appointment reminder falls inside the quiet window | Delivered at the end of the window, while dose reminders are NOT delayed |
| 15 | Two profiles | Caregiver switches profile | Reminders follow the selected profile only (known limit, finding 8) |

### iOS only

| # | Scenario | Expected |
|---|----------|----------|
| 16 | First launch notification prompt | Asked from onboarding, not on launch |
| 17 | Focus modes / Time Sensitive | Note whether reminders break through the user's Focus (no entitlement is set today) |
| 18 | App not opened for 3 days | Only the next 48 h were scheduled: reminders stop after that. Document this limit |

## C. Known limits (Spark plan)

- Only the next 48 hours are scheduled, and only when the app has been opened
  (start, resume, after a log or edit). A phone that is not opened for days stops
  reminding. A server push on Blaze fixes this.
- iOS keeps 64 pending local notifications per app.
- Reminders are scheduled for the selected profile only.
- Inexact alarms (exact-alarm permission missing) can be minutes late.
