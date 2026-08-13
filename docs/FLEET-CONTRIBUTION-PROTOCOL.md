# Orbit Browser — Fleet Contribution Protocol
**Ratified by khalid 2026-08-13. THE rule for who works what.**
Purpose: everyone contributes when online WITHOUT damaging the other's work or velocity.

## 1. LANES — one owner per thing, no overlap
| Lane | Owner | Scope | Do NOT touch |
|---|---|---|---|
| **web-app** | brick | src/, e2e/, playwright, PWA, manifest | Swift shells, Xcode |
| **native-shells** | zero | shells/macos, shells/ios (Swift, Xcode, Fastfile) | web-app/src, e2e/ |
| **ci-cd** | brick | .github/workflows, eas.json, app.json, Fastlane config | — (config owner) |
| **docs** | brick | README, docs/, THROWAWAY-001 | — |
| **queue** | brick (PM) | /root/.hermes/notes/queue/ + repo queue branch | — |

## 2. CONTRIBUTION FLOW (everyone, every time)
1. **Check queue first** — open/ has tickets. Take one: claim (rename + lease + claimer).
2. **Branch from develop** — `feat/<lane>-<ticket-id>-<slug>` (never main directly).
3. **Work ONLY in your lane's paths.** If a change crosses lanes → coordinate in the ticket first, never silently.
4. **PR to develop** — CI runs (lint, typecheck, build, E2E). CodeRabbit reviews every PR (queued 1/hr, never skipped).
5. **CodeRabbit findings** → brick triages → owner fixes → re-review → merge.
6. **Drop ticket to done/** with evidence (PR link). Nothing merges without its ticket.

## 3. VELOCITY GUARDS (no damage to the other's work)
- **Never two people on the same ticket.** Claim = ownership. Lease expires → back to open, not stolen.
- **Never rewrite the other lane's code without a cross-lane ticket note.** A web-app change that needs shell changes = ONE ticket, BOTH owners named.
- **No reverts of the other's merged work** — if it's broken, open a fix ticket (never revert silently; the PR #2 revert incident taught us).
- **Main = always green.** If your PR breaks CI, you fix it same-day or the ticket goes blocked.
- **Zero offline ≠ work stops** — brick continues web-app/CI/QA; native-shell tickets wait in the queue (durable, git-native).

## 4. FEEDBACK LOOP (khalid's requirement)
- **Every CodeRabbit finding = a ticket** (or a reply in the thread + ticket ref). Findings never die in threads.
- **Every demo feedback = a ticket** (e.g. "no URL bar", "can't close tabs" → T-003 tab management).
- **Brick triages daily**: open → claimed → done → blocked; surfaces ONLY what needs khalid.

## 5. CURRENT STATE (2026-08-13)
- PR #2 chrome redesign: MERGED to main (0fb4e8d)
- PR #3 web-app URL bar + E2E: open — brick owns, needs CodeRabbit pass + merge
- T-001 (PR2 CodeRabbit): DONE (addressed in b65bc4a)
- T-002 (push web-app): DONE (PR #3 open)
- T-003 (tab management): OPEN — brick claims next after PR #3

**The queue is the truth. The lanes are the law. Main is always green.**
