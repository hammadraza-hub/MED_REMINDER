# graphify — MedRemind architecture & progress tracker

Snapshot date: **2026-11-18** · branch `main` · commit `727ebd7` · **M0–M22 done for the Spark plan; M23 (this folder) in progress**

This folder is the single place to see *what the app is*, *how it is wired*, and *how far along* it is.
It is hand-maintained (this is plan module **M23 — Graphify architecture update**). Update it at the end of every module. The generated code graph is in `../graphify-out/`.

| File | Purpose |
|------|---------|
| [HANDOFF.md](HANDOFF.md) | **START HERE** — constraints, commands, conventions, traps, per-module notes (sections 9-19) |
| [architecture.md](architecture.md) | Layers, data flow, startup order, mermaid diagrams |
| [modules-progress.md](modules-progress.md) | M0–M23 status board with evidence and what needs Blaze / a key / a device |
| [feature-map.md](feature-map.md) | Every `lib/features/*` area → data source → logic → module |
| [firebase-map.md](firebase-map.md) | Services used / not used, Firestore collections and rules, indexes, tests, CI, what needs Blaze |
| [progress.json](progress.json) | Machine-readable status (for scripts / dashboards) |
| [CHANGELOG.md](CHANGELOG.md) | Dated log of status changes — append, never rewrite |

## How to update
1. Finish a module step → edit its row in `modules-progress.md` and `progress.json`.
2. Add one line to `CHANGELOG.md`.
3. If you added a screen / repo / collection, update `feature-map.md` / `firebase-map.md`.
4. Refresh the code graph: `python -m graphify update .` (see HANDOFF section 8).

## Headline (2026-11-18)
- The whole plan is built on the Firebase **Spark plan** (client side only): core loop (medicine → schedule → dose → reminder → log), caregivers by role, subscriptions UI, settings / support, export and deletion, vitals, appointments, reports, AI assistant, community, offline states, hardened rules, and a large test suite.
- **Cloud Functions are still an empty scaffold.** Everything that needs a server is NOT built: push fan-out, nightly dose generation, refill job, caregiver invites, Trigger Email, Twilio, RevenueCat webhook, server-side AI, RxNorm sync.
- Tests: 1094 Flutter tests, 15 emulator integration files, 443 rules tests, rules probe 0 gaps. A real Android alarm was verified on the emulator.
- Before release: deploy rules and indexes to staging, run the real-phone reminder matrix (`docs/REMINDER_DEVICE_MATRIX.md`), switch App Check enforcement on, decide about Blaze.
