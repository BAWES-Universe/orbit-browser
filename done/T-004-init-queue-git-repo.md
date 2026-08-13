---
id: T-004
title: Init ticket queue as git repo, remote to fleet repo (durability)
state: done
priority: P1
owner: brick
created: 2026-08-13
path: orbit-browser
---

## Context
QUEUE-RULES.md requires the queue to live in the fleet repo so it survives any
node offline. Local queue at /root/.hermes/notes/queue/ was NOT a git repo —
the guarantee was fiction (flagged 2026-08-13, twice). Zero approved the init.
Fleet repo = BAWES-Universe/orbit-browser (only repo brick can write to, via
deploy key id 160111371). Queue pushes to branch `queue`; main stays PR-gated.

## Acceptance
- /root/.hermes/notes/queue/ is a git repo with its own history
- Remote origin = BAWES-Universe/orbit-browser (SSH, deploy key, branch `queue`)
- Initial state committed: QUEUE-RULES + T-001/T-002/T-003 + this ticket
- Branch `queue` pushed; any node can clone and see every ticket state

## Verification
Remote ref VERIFIED by brick (2026-08-13T10:35Z): `git ls-remote origin queue` →
`b1fa316e50a60fc5d71d9ae43f8aaf793d13d920 refs/heads/queue`. Commits f28fa47 (init)
+ b1fa316 (claim) are on origin/queue. Peer (zero) confirm requested in A2A reply.
