# PalEdu Royal Emerald — design implementation v0.8

## Approved direction implemented
From supplied references: warm white surface, deep emerald hierarchy, restrained gold actions, readable Arabic RTL and clear progress cards. No images of draft UI are baked into Flutter; all content is real, selectable and accessible.

## Screens implemented in first pass
- Student home: personalized status from saved grade/track, genuine lesson and subject completion, Continue Learning, quick actions, ministry-resource shortcut, due-review shortcut.
- Subject library: expandable accordion per subject, search, completion-only filter and visible lesson links; no fabricated semesters/units.
- Shared theme: dark/light emerald/gold tokens, button/cell geometry, spacing and navigation behavior.

## Follow-up screens (new design passes)
1. A richer lesson reader with audio/PDF/video attachments when actual licensed assets exist.
2. Teacher studio and admin console desktop/tablet responsiveness.
3. Accessible onboarding and account chooser, profile and quiz feedback.
4. Detailed tests for accessibility, international RTL/localization, narrow devices and dark theme.

## Production caveats
- Offline sample lessons are a demo, NOT the official Palestinian schoolbooks.
- Account login requires configured Supabase service and reviewed database migrations.
- Hundreds of thousands of users is a capacity goal, not a measured system limit.
- No admin credentials or private secrets are checked into this repository.
