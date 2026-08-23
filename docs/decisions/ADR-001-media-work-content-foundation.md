# ADR-001: MediaWork-Centric Content Foundation Architecture

**Date**: 2026-08-20  
**Status**: Accepted  
**Deciders**: Architecture Team  

---

## Context

The current nebula_iptv application uses a simple `tmdb_cache` table as a flat cache for metadata aggregation. This model has significant limitations that prevent sophisticated content matching and data management:

- **No fuzzy matching support**: The flat structure doesn't support partial or approximate content matching
- **No variant handling**: Unable to merge/unmerge content variants from multiple sources
- **No aliasing system**: No support for multiple titles or identifiers for the same work
- **No merge auditability**: No historical record of content consolidations or manual overrides
- **Single-source limitation**: Only TMDB metadata is cached; TVMaze and other sources are not systematically integrated
- **Limited cache persistence**: 7-day cache expiration loses valuable metadata relationships
- **No source attribution**: Unclear which metadata came from which source or whether it was manually curated

This architecture cannot support the required evolution toward a robust multi-source content matching pipeline with manual override capabilities and data lineage tracking.

---

## Decision

We will **migrate from the simple `tmdb_cache` table to a MediaWork-centric relational model** as the foundation for the content management system. This new architecture introduces three core tables:

1. **`MediaWork`**: The canonical representation of a unique creative work
   - Primary identifier (`work_id`)
   - Aggregate metadata (title, synopsis, release date, genres, etc.)
   - Permanent record with audit trail
   - **No cache expiration** — permanent storage with periodic metadata updates

2. **`ContentAlias`**: Aliases and identifiers linking content across multiple sources
   - Foreign key to `MediaWork`
   - TMDB ID, TVMaze ID, IMDb ID, custom identifiers
   - Fuzzy matching scores and confidence levels
   - Source attribution and merge history

3. **`MediaWorkMergeLog`**: Audit trail for all content consolidations
   - Records manual merge/unmerge operations
   - Captures rationale and user/system responsibility
   - Enables rollback and historical analysis
   - Tracks source priority and resolution rules applied

### Source Priority & Override Model

Metadata will be governed by explicit source attribution:

- **`source: auto`** — Metadata fetched from TMDB or TVMaze following the normalized pipeline
- **`source: manual`** — User-curated overrides; these are **immutable** and take precedence over auto-fetched data

Manual overrides are treated as "sacred" — they represent user intent and should never be silently overwritten by automatic matching or periodic refresh operations.

### Normalization & Matching Pipeline

All inbound metadata from TMDB and TVMaze will flow through a deterministic normalization pipeline:

1. **Title normalization**: Case folding, punctuation removal, accent normalization
2. **Fuzzy matching**: Levenshtein distance or similar algorithm with configurable confidence thresholds
3. **Merge scoring**: Calculate confidence scores for proposed consolidations
4. **Duplicate detection**: Identify and flag potential duplicate works before they enter the canonical store

TVMaze serves as a **fallback data source** when TMDB data is unavailable or incomplete.

---

## Consequences

### Positive Consequences

- **Richer data model**: Support for fuzzy matching, aliasing, and multi-source integration
- **Permanent metadata storage**: 30-day cache persistence (compared to current 7-day model) with no hard expiration
- **Auditability**: Full traceability of all content consolidations and manual overrides via `MediaWorkMergeLog`
- **User control**: Manual overrides are protected from automatic overwrites; users can curate their catalog with confidence
- **Multi-source flexibility**: TVMaze integration as fallback; extensible to future sources (IMDb, custom APIs)
- **Data quality improvements**: Matching scores and confidence levels enable progressive refinement of the dataset

### Negative Consequences

- **Increased schema complexity**: Three tables instead of one; requires careful foreign key management and consistency checking
- **Migration effort**: Existing `tmdb_cache` data must be bulk-loaded into the new schema; requires data transformation and validation logic
- **Performance considerations**: Joining across three tables for content lookup; requires indexed queries and possible denormalization for hot paths
- **Higher maintenance burden**: The merge log requires monitoring; stale or incorrect merges must be detected and resolved
- **Storage overhead**: Storing aliases and merge history increases database footprint compared to the flat cache model

### Implementation Requirements

To realize the benefits and mitigate risks, the following must be implemented:

1. **Data migration script**: Transform existing `tmdb_cache` entries into `MediaWork` + `ContentAlias` records
2. **Normalization service**: Implement title normalization and fuzzy matching algorithms
3. **Merge resolution engine**: Build logic to propose and execute merges with confidence scoring
4. **Audit logging**: Ensure all mutations to `MediaWork` and `MediaWorkMergeLog` are logged
5. **Rollback & correction tools**: Enable admins to undo merges and resolve conflicts
6. **Query optimization**: Build materialized views or caching layers for common queries (by TMDB ID, TVMaze ID, canonical title)
7. **Monitoring & alerts**: Track merge quality, conflict frequency, and manual override patterns

---

## Rationale

This decision prioritizes **data fidelity, auditability, and user control** over simplicity. The multi-source, alias-aware model enables sophisticated content matching while the merge audit trail provides accountability and reversibility. Manual overrides are protected, ensuring that user curation is never silently lost to automatic updates.

The 30-day cache duration and permanent storage model balance freshness (metadata can still be updated periodically) with stability (no arbitrary data loss).

---

## Related Decisions

- **ADR-002** *(future)*: Normalization and Fuzzy Matching Algorithm Selection
- **ADR-003** *(future)*: TVMaze Integration Strategy
- **ADR-004** *(future)*: Cache Refresh and Metadata Update Policies

---

## References

- `nebula_iptv` Specification for Content Evolution (docs/spec.md)
- TMDB API Documentation
- TVMaze API Documentation
- ADR template based on [Michael Nygard's ADR format](https://github.com/adr/madr)
