# Firebase map

## Environments
| Env | Project | Region | Config file |
|-----|---------|--------|-------------|
| staging | `medapp-staging` | asia-south1 | `lib/firebase_options_staging.dart` ✅ |
| prod | `med-reminder-38e5c` | nam5 | `lib/firebase_options_prod.dart` ⚠️ exists locally but is **gitignored** (fresh clone won't compile — see HANDOFF) |

## Firestore collections vs rules
| Path | Rules block | Used by app |
|------|-------------|-------------|
| `users/{uid}` (+`devices`) | ✅ explicit | auth, settings, FCM tokens |
| `profiles/{pid}` | ✅ | profile repo |
| `…/medications` (+`inventoryEvents`) | ✅ | M5, M9 |
| `…/pharmacies` | ✅ | M9 |
| `…/doses`, `…/dailySummaries` | ✅ | M6/M7 |
| `…/allergies` | ✅ | M3 |
| `…/{collection}/{docId}` | generic fallback (~line 598) | other health data (refillAlerts, vitals, …) |
| `customers/{uid}` | ✅ owner read-only, no client write (added 2026-11-12, uncommitted) | M12 |
| `drugs`, `invites`, `supportTickets`, `exportJobs`, `config`, `mail` | no explicit block (default deny at `{document=**}`) | not yet |

## Other backend assets
- `functions/src/index.ts` — scaffold only, **no functions**.
- `tests/firestore.rules.test.js` — 435 lines, 26 cases (emulator).
- `.github/workflows/firebase.yml` — rules tests + staging deploy (storage deploy skipped).
- `firestore.indexes.json`, `storage.rules`, `docs/firestore-schema.md` (locked v1.0).
