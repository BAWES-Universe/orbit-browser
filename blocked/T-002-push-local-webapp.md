---
id: T-002
title: Push local web-app work (URL bar + E2E suite) into repo as PR
state: claimed
priority: P0
owner: zero
claimer: zero
lease_expires: 2026-08-13T10:27:37.386810Z
claimed_at: 2026-08-13T06:27:37.386911Z
created: 2026-08-13
path: orbit-browser
---

## Context
Brick built locally (URL bar, workspace shell, 7 E2E tests — all green) but NEVER
pushed to the repo. Khalid saw the OLD repo state in the demo (no URL bar, no tabs).
The divergence must end: local work lands as a PR through the gate.

## What lands
- web-app/src/App.tsx + App.css — URL bar + chrome + tab-ready shell
- web-app/e2e/workspace.spec.ts — 7 passing E2E tests incl. URL-input regression guard
- index.html manifest link, vite.config dev SW, playwright.config
- Local build verified: 7/7 E2E green, build green

## Acceptance
- PR opened against develop (through Zero, who has push access)
- CodeRabbit + Sentry + E2E green in CI
- Khalid sees the URL bar working in a live build (demo ≠ stale)

## Verification
merged + QA + 0 TS + E2E suite green
