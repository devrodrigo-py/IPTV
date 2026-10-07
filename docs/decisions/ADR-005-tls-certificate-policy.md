# ADR-005: TLS Certificate Validation Policy

**Date**: 2026-08-29
**Status**: Accepted

---

## Context

`DioClient` had a global `badCertificateCallback` that accepted **any**
invalid certificate (`(...) => true`). Every HTTPS request in the app —
playlist imports, Xtream API calls, TMDB enrichment — was vulnerable to
man-in-the-middle attacks, regardless of whether the user's IPTV source
actually needed self-signed certificate support.

Some IPTV panels do serve HTTPS with self-signed or expired certificates,
so a blanket "reject all" would break real sources. The spec (§29) requires
never bypassing security controls, and the TLS bypass was silent and global.

## Decision

1. **Reject invalid certificates by default.** `DioClient` no longer
   accepts any invalid certificate unless explicitly opted in.
2. **Opt-in is per playlist/source, never global.** The `playlists` table
   gained an `allowInsecureTls` column (schema v11). During import and
   refresh, the repositories pass the flag down to the datasources, which
   scope the acceptance to the source's host for the duration of the
   request (`DioClient.allowInsecureFor` / `disallowInsecureFor`).
   Requests to any other host (TMDB, TVMaze) are never affected.
3. **Visible UI warning.** The "Add source" dialog exposes an explicit
   checkbox — *"Aceitar certificado inválido (self-signed)"* — with a
   red warning that data may be intercepted. The flag defaults to **off**
   for every new source.

## Alternatives considered

- **Keep global accept**: rejected — MITM exposure for all traffic, no
  user awareness.
- **Global setting in Configurações**: rejected — one careless toggle
  would disable TLS validation for every source; risk is per-source.
- **Certificate pinning per source**: overkill for this stage; sources
  rotate certificates and no TOFU UX exists yet. Can be revisited with an
  ADR if needed.

## Consequences

- Sources with self-signed certificates must opt in at import time and
  will see the warning once per source creation.
- The `M3uDataSource`/`XtreamDataSource` methods gained an optional
  `allowInsecureCertificates` parameter (default `false`).
- Attack surface shrinks from "all HTTPS traffic" to "only hosts the user
  explicitly trusted, only while their requests run".
- Future monetization/gating work (Etapa 8) is not affected; the flag is
  a data-layer detail behind the repository API.

## Related Decisions

- ADR-001 (MediaWork content foundation) — untouched.
- Schema migration v10 → v11 (`allowInsecureTls` on `playlists`).
