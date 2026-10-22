# PalEdu 0.15 — Internal multimedia learning resources

Inspired by Khan Academy's learning path, Moodle's resource bank, and Kolibri's offline-first organization. This PR implements a narrow, testable media foundation rather than claiming product parity.

- Teacher upload kinds: book (PDF), handout/worksheet (PDF/JPG/PNG), lesson material (PDF/JPG/PNG), video (MP4). Invalid combinations are rejected before upload.
- Direct HTTPS PDF/image/MP4/HLS URL allowed as an alternative to upload. Regular YouTube watch-page URLs are not falsely presented as playable direct video. Exactly one file or link is required.
- Teacher form adds semester 1 or 2, already supported by the existing SQL schema, and changes file-picker allowed extensions by kind. Previous selected files are cleared on kind change.
- Student library filters by semester and media type, uses clear icons, has a reload action, and routes to the built-in PDF, video or NEW zoomable image viewer. Legacy content without semester remains visible.
- Content stays within PalEdu; no external browser hand-off for approved resources. Network is needed for remote media and private Supabase Storage.
- No copyrighted books, videos or handouts have been copied into this repo. Teachers must obtain permission and administrators verify rights before publishing.
- Actual teacher uploads, authenticated accounts and RLS require live Supabase project deployment. This PR does not configure cloud credentials.
- Upload is limited to 50 MB. Larger videos need authorized HLS/MP4 hosting and streamed URLs. Resumable uploads/CDN transcoding and load testing remain future work.
- Tests cover format validation, direct HTTPS sources, viewer selection, and unsafe link rejection.
