# PalEdu | تعلّم فلسطين

Flutter mobile learning app — an offline-first Arabic RTL demonstration.

## Status
Version 0.6.0 source: demo curriculum with 48 lessons and 144 original quiz questions across grades 1–12 and preliminary secondary pathways.
**This is NOT the full official Palestinian curriculum.** Government textbooks require copyright/licensing and academic review before redistribution.

## Features
- Onboarding with grade and track, local profile with no phone number
- Polished adaptive Material 3 layout, dark mode, font scale
- Subject catalog, lesson reader, multiple-choice quizzes, flashcards, matching game
- Offline sample content, progress and XP saved locally; delete-my-data option
- No third-party analytics, payments, tracking or user account in demo

## Cloud scale (planned, not proven)
Static curriculum media: object storage + CDN with versioned manifests;
authentication and student progress: dedicated API + protected database;
performance & capacity: staging load tests before production. See docs/ARCHITECTURE.md.

## Build using GitHub Actions
Open Actions > **PalEdu CI / Android**. The workflow installs Flutter on GitHub-hosted runners, generates Android native scaffolding, runs analyze & test, builds a debug APK, and uploads it under Artifacts.

Do not publish a debug-signed APK to Google Play. Production signing requires securely configured keys.
