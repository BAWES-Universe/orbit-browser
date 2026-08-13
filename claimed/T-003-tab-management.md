---
id: T-003
title: Build tab management (open/close/switch) — regression-tested
state: claimed
priority: P1
owner: brick
claimer: brick
lease_expires: 2026-08-13T14:35:28Z
claimed_at: 2026-08-13T10:35:28Z
created: 2026-08-13
path: orbit-browser
---

## Context
Khalid's demo feedback: "I can't even close tabs or see a url bar." Tab management
doesn't exist yet in the web-app shell. Core browser behavior — must exist AND be
tested (E2E: open tab, close tab, switch tab; regression guard like URL input).

## Acceptance
- Tab bar UI: open, close (×), switch (click), active state
- E2E tests: open N tabs, close one, switch between — all green
- Works alongside URL bar (tab = URL context)

## Verification
merged + QA + 0 TS + E2E suite green
