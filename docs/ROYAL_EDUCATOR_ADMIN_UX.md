# PalEdu — Royal Educator and Administrator UX

This update adopts the established emerald/gold visual system for teacher, trainer and admin portals:
- Teacher dashboard shows data-backed metrics only for the most recently retrieved (max 100) resources, preserving uploads, account sign-out and resource status.
- Admin dashboard shows real currently retrieved pending counts, clear no-results states and reusable review cards.
- Approval or rejection now requires a confirmation dialog before the existing protected RPC; duplicate submissions are blocked while in flight.
- Responsive cards and semantic controls are tested in Flutter CI.
- No secret, hard-coded admin identity, fabricated counts or locally elevated role is provided.
- Live user login requires an owned and configured Supabase backend; this change does not provision the service.
- Future: server-side pagination, media transcoding, teacher class management, robust minors' privacy review and actual capacity tests.
