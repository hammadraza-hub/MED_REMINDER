# Graphify changelog (append only)

- 2026-11-12 — Initial graphify created from code review. Baseline: M0–M7 done/mostly done, M8–M12 partial (M11 stub), M13–M14 early, Phase 2/3 UI-only.
- 2026-11-12 — Added HANDOFF.md. M12: `customers/{uid}` rule + 4 tests (30 rules tests green). Corrected: prod firebase options file is gitignored, not missing.
- 2026-11-12 — Ran real Graphify tool (`graphify update .`) → `graphify-out/`; added `.graphifyignore`; HANDOFF §8 documents usage.
- 2026-11-12 — M12 step 2: cancelSubscription now opens Play Store/App Store subscription page instead of writing customers/{uid}.
- 2026-11-12 — M12 step 3: RevenueCat skipped when REVENUECAT_API_KEY missing/placeholder; purchase calls throw SubscriptionUnavailableException; screens show a friendly message.
- 2026-11-12 — M12 step 4: UI-tested all subscription states on Android emulator; fixed hasPremiumAccess for canceled-but-paid subscriptions. M12 ≈ 75% (key + webhook pending).
- 2026-11-12 — Graph rebuilt after M12 steps 1-4 (4,903 nodes / 6,222 edges / 207 communities); README/HANDOFF snapshot refreshed.
- 2026-11-13 — M13 step 1: Remote Config terms/privacy/disclaimer keys, AppGate force-update/maintenance screen, AppInfoService (real version), About shows real version, debug cleartext for emulators, 10 new tests.
- 2026-11-13 — M13 step 1 fully verified on emulator (gate screens, About, Settings trailing version); found Settings 'About'/Allergies label bug.
