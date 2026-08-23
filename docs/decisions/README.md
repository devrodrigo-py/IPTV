# Architecture Decision Records (ADRs)

This directory contains the Architecture Decision Records for the **nebula_iptv** project. Each ADR documents a significant architectural decision, its context, rationale, and consequences.

## Format

ADRs follow the standard format established by Michael Nygard:
- **Title**: Concise description of the decision
- **Status**: Proposed, Accepted, Deprecated, or Superseded
- **Date**: When the decision was made
- **Context**: The problem or situation that prompted the decision
- **Decision**: The actual architectural choice made
- **Consequences**: Both positive and negative impacts
- **Rationale**: Why this decision was chosen over alternatives
- **References**: Links to related documents, ADRs, or specifications

## Index

### Phase 1: Content Foundation

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| **ADR-001** | [MediaWork-Centric Content Foundation Architecture](./ADR-001-media-work-content-foundation.md) | Accepted | 2026-08-20 | Migrate from simple `tmdb_cache` table to a robust relational model with `MediaWork`, `ContentAlias`, and `MediaWorkMergeLog` tables. Introduces multi-source integration, fuzzy matching, and manual override capabilities. |

### Phase 2: Matching & Normalization *(Planned)*

| # | Title | Status | Date | Description |
|---|-------|--------|------|-------------|
| **ADR-002** | Normalization and Fuzzy Matching Algorithm Selection | Proposed | — | Evaluate and select algorithms for title normalization (case folding, punctuation removal, accent normalization) and fuzzy matching (Levenshtein distance, etc.). |
| **ADR-003** | TVMaze Integration Strategy | Proposed | — | Define how TVMaze serves as a fallback data source and how conflicts between TMDB and TVMaze are resolved. |
| **ADR-004** | Cache Refresh and Metadata Update Policies | Proposed | — | Establish policies for periodic metadata updates, cache invalidation, and handling of stale records. |

## Navigation

- **[main spec](../spec.md)** — Core specification for nebula_iptv evolution
- **[parent docs](../)** — Other documentation in the project

## Adding a New ADR

1. Create a new markdown file: `ADR-NNN-title-slug.md`
2. Use the template format shown in ADR-001
3. Start with **Status: Proposed**
4. Update this README with a link and brief description
5. Request review from the architecture team
6. Update status to **Accepted**, **Deprecated**, or **Superseded** after decision

## Status Definitions

- **Proposed**: Under discussion, not yet finalized
- **Accepted**: Approved and ready for implementation
- **Deprecated**: No longer in use, replaced by a newer decision
- **Superseded**: Replaced by another ADR (reference the new one)
