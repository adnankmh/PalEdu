# PalEdu Original Motion & Icon System — v0.11

PalEdu now includes an original book animation, an achievement burst, and a vector-painted logo crest designed for the project's emerald/gold identity.

## Assets, attribution and network
- \`assets/animations/welcome_book.json\`: brand-colored open book with a short float motion and sparkle.
- \`assets/animations/achievement_stars.json\`: one-time achievement burst with star/confetti layers.
- Both compositions are original to this repository, self-contained JSON shape animations, not dependent on remote LottieFiles URLs or CDN requests.
- Uses Flutter's open-source \`lottie\` package. Verify production dependencies and licenses at release.

## Product integration
- Entry screen combines \`RoyalBrandCrest\` and the book animation.
- Student "Continue learning" hero uses original book motion; progress indicators remain based on actual learner state.
- Quiz results use a star celebration when at least 70% of responses are correct, otherwise a static trophy.
- Profile lets each learner toggle \`الحركات التعليمية\`, persisted through shared preferences and cleared by the delete-my-data control.
- The animation adapter honors the platform's \`MediaQuery.disableAnimations\` and renders a semantic static icon without running animation.
- Animations run once, never loop indefinitely; always provide fallback icons on bad assets.

## QA
- Unit tests validate asset structure and persisted preference changes.
- Widget tests verify reduced-motion and disabled-motion fallback semantics.
- CI checks Flutter analyze, tests, and Android/Web build before merge.

This is an *animated UI upgrade*, not a claim that Supabase accounts are deployed, that all Palestinian textbooks are included, or that 500k concurrent learners have been load-tested.
