# Task Plan: Automaker feature claims vs codebase audit

## Goal

Cross-check every `.automaker/features/*/feature.json` entry (status + summary) against the actual Flutter and Fly.io backend implementation, and list gaps still requiring human or follow-up implementation.

## Current Phase

Phase 5 (Delivery) — **complete**, including exhaustive Automaker audit (`automaker-full-audit.md`)

## Phases

### Phase 1: Requirements & Discovery
- [x] Inventory all Automaker feature folders and `status` fields
- [x] Read planning-with-files skill rules (`codex-plans/`, append-only `fixes.md`)
- **Status:** complete

### Phase 2: Planning & Structure
- [x] Define verification method (grep + spot-read for critical paths)
- [x] Create `findings.md` gap matrix
- **Status:** complete

### Phase 3: Implementation
- [x] N/A — audit only (no product code changes this session)
- **Status:** complete

### Phase 4: Testing & Verification
- [x] Backend: spot-check `main.py` for advertised endpoints/classes
- [x] Frontend: spot-check `lib/`, `pubspec.yaml`, `AndroidManifest.xml`
- **Status:** complete

### Phase 5: Delivery
- [x] Write `progress.md` session log
- [x] Ensure `fixes.md` exists (append-only; no production fixes this audit)
- **Status:** complete

## Key Questions

1. Which features are marked `verified` but have no code or contradictory summaries? → See `findings.md` §Critical.
2. Which features are partially implemented with clear remaining ops/dev work? → See `findings.md` §Operational and §Partial.

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| Treat Automaker `summary` as primary claim text | `description` is aspirational; summaries describe what agents believed they shipped |
| Trust repo files over JSON status when they conflict | `deep-link-validation` is the clearest example |

## Errors Encountered

| Error | Attempt | Resolution |
|-------|---------|------------|
| None | — | — |

## Notes

- Per planning-with-files skill: archive this plan to `docs/task-plans/` when the team considers the audit closed (optional).
- **Do not trust `status: verified` alone** — validate against `summary` + repo.
