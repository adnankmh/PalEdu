# PalEdu architecture and growth plan

- **Flutter client**: localized RTL, responsive Material 3 widgets; offline demo bundle; minimal personally identifying information.
- **Content service**: approved lessons versioned by grade/track/subject/unit. Publish immutable JSON, PDF and image objects to CDN. Cache with a content-hash manifest and bounded storage; support conditional requests. **Not deployed yet.**
- **Backend**: managed auth with teacher/editor/student roles; API rate limits, pagination, idempotent progress events and per-user access control (RLS if using Supabase). **Not deployed yet.**
- **Scale target**: 100,000+ registered learners, target 500k. Registrations are not equal to concurrent connections. Estimate peak RPS, object request ratios, CDN hit rates and bandwidth from measurements, then load test at 100, 1k, 10k, 50k and beyond using a staging environment. Do not claim verified capacity until observed.
- **Privacy**: child/minor-oriented default no public profiles, no location collection, safe account recovery, least-privilege operations and documented retention/deletion. Vet all third-party content and moderation.
- **Educational policy**: examples are marked demonstration_only. Official Palestinian materials must be verified, attributed and licensed before being shown as official.
- **Delivery**: Android CI debug artifact first; release signing & app-store reviews later. iOS needs macOS runner and Apple signing account.
