# graphify — MedRemind architecture & progress tracker

Snapshot date: **2026-11-12** · branch `main` · last commit `747bc77` (M9–M12)

This folder is the single place to see *what the app is*, *how it is wired*, and *how far along* it is.
It is hand-maintained (this is plan module **M23 — Graphify architecture update**). Update it at the end of every module.

| File | Purpose |
|------|---------|
| [architecture.md](architecture.md) | Layers, data flow, startup order, mermaid diagrams |
| [modules-progress.md](modules-progress.md) | M0–M23 status board with % and next actions |
| [feature-map.md](feature-map.md) | Every `lib/features/*` area → data source → backing module |
| [firebase-map.md](firebase-map.md) | Firestore collections, rules coverage, functions, CI, envs |
| [progress.json](progress.json) | Machine-readable status (for scripts / dashboards) |
| [CHANGELOG.md](CHANGELOG.md) | Dated log of status changes — append, never rewrite |

## How to update
1. Finish a module step → edit its row in `modules-progress.md` and `progress.json`.
2. Add one line to `CHANGELOG.md`.
3. If you added a screen/repo/collection, update `feature-map.md` / `firebase-map.md`.

## Headline (2026-11-12)
- Phase 1 core loop (add med → schedule → dose → remind → log) is built on Firebase **Spark plan** (client-side only).
- **Cloud Functions are empty** (`functions/src/index.ts` is the scaffold). Anything needing server logic (caregiver invites, RxNorm sync, label parse, export, delete, push fan-out) is stubbed or done client-side.
- Phase 2/3 screens (vitals, appointments, reports, AI, community) exist as UI, mostly on local Drift/dummy data.
- Uncommitted work in progress: M12 subscription/paywall (RevenueCat) + l10n for ar/es/fr.
