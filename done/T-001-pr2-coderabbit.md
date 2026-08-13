---
id: T-001
title: Address PR #2 CodeRabbit findings (3 fixes)
state: done
priority: P0
owner: zero
created: 2026-08-13
path: orbit-browser
---

## Context
PR #2 (q-orbit-02-chrome) has 3 unaddressed CodeRabbit reviews (2026-08-13T05:54).
Khalid flagged them. Must be answered through the process, never ignored.

## The 3 findings
1. shells/macos/OrbitBrowser/Sources/BrowserView/BrowserWindowController.swift:181 —
   "Focus the start-page field only on a start-page transition" (background tabs steal focus)
2. shells/macos/OrbitBrowser/Sources/Chrome/ToolbarView.swift:117 —
   layout/avatar reference mismatch
3. shells/macos/README.md:21 — Theme.swift is at Sources/Theme.swift, not Sources/Chrome/

## Acceptance
- Each finding: fix committed to the PR branch (or reasoned disposition posted as reply)
- CodeRabbit re-review green
- PR #2 mergeable, ready for reviewer sign-off
- Route through Zero (has push access) unless worker with access claims it

## Verification
PR #2 MERGED to main (94e2d60, verified ON main by brick via ancestry check
2026-08-13T10:35Z). CodeRabbit addressed (b65bc4a per merge message), CI green.
Fleet bar: merged + QA + 0 TS — satisfied.
