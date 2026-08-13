# Fleet Ticket Queue — durable, git-native
## Model
- Queue lives in the fleet repo (source of truth). Survives any node offline.
- Ticket lifecycle: open → claimed → done | blocked | dropped-back
- CLAIM = atomic rename open/ → claimed/ + lease timestamp + claimer field
- DROP-BACK = staleness watchdog: claimed > lease expires → back to open (exists)
- Never lost: a ticket is always in exactly one state, in git history.

## States
- open/: available. Ticket = one markdown file with VERIFIED/COST/OWNER fields.
- claimed/: being worked. lease: 4h default (renewable). claimer + claimed_at in file.
- done/: verified output. evidence link required (PR, artifact path, ledger tx).
- blocked/: needs khalid or gate. reason field mandatory.

## Rules
1. Take: claim open ticket (rename + claim fields). Never claim 2 tickets same time unless stated.
2. Work: do the thing, then VERIFY (merged + QA + 0 TS or artifact QA).
3. Drop back: done/ with evidence, or blocked/ with reason, or lease expires → auto back to open.
4. Nobody self-verifies. Auditor ≠ earner.
5. Queue = the process. No side work outside tickets (the lesson from PR #2 / local lane).
