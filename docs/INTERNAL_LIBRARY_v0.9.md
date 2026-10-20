# PalEdu — Internal Documents Library (v0.9 preview)

## Implemented
- In-app ministry resource index fetch and HTML parsing, grouped by grade/branch/type with search; two Ministry of Education indexes are queried over HTTPS. Live loading works if the ministry site remains accessible and its HTML structure has compatible headings and tables.
- Source-URL validation restricts *official index discovery* to Ministry of Education domains. Links are not redistributed or proxied by PalEdu.
- Bundled fallback for a limited number of **verified** grade-10/11/12 PDFs, plus cached dynamically discovered links after successful fetching.
- Built-in PDF engine for Android/Web/iOS: page scrolling/zoom, jump to page, local last-page position and a saved-book marker. A PDF is streamed from the original owner, not copied into GitHub.
- Teacher-uploaded PDF/handout links open in the same reader once Supabase Auth and private Storage are configured.
- MP4/HLS direct videos open inside a separate PalEdu player with playback controls. YouTube page URLs are not direct media and are not falsely treated as playable. The user sees an explanatory message.

## Remaining work
- Some grades may appear empty when the ministry website cannot be reached and no cached index exists; this is honest rather than inventing books.
- Initial opening of PDF/video requires network. Do not advertise offline textbooks until permissions, quota and local downloads are implemented.
- All ministry textbooks and the full corpus of third-party handouts have NOT been transferred to PalEdu storage. Redistribution requires authorization, rights provenance and educational review.
- Teacher authentication, upload permissions and content approval need a *live configured Supabase project*. They are only coded locally today.
- Current school grade/branch names must be validated against the 2026/27 official structure, including special streams.
- On Flutter Web, cross-origin PDF fetch can be blocked by the ministry's CORS headers. An authorized same-origin CDN/proxy would be needed for reliable web reading; do not insert an insecure public proxy.
- Record actual GitHub Actions build status, not inferred readiness. Stage load tests before any "500k users" claim.

## QA
- Parser tests for grades, branches, an untrusted link, and network fallback.
- Flutter Analyze/Test + Android APK + Web preview on GitHub Actions.
