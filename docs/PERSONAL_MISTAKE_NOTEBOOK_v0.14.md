# PalEdu v0.14 — Personal Mistake Notebook

**دفتر أخطائي** is an active learning feature for students. Upon completing
a lesson quiz, the app saves only compact SHA-256 question fingerprints for
wrong responses (never the prompt, choice or answer text). Previously wrong
items are removed when reanswered correctly. When lessons are changed in the
demonstration catalog, outdated content fingerprints are not accidentally
linked to new questions.

From the student Home, Games and Profile, the user can review lesson-specific
mistakes or take a mixed corrective practice session. Explanations are revealed
after answering. Correct responses clear that mistake; incorrect responses
stay in the notebook for another attempt. Corrective practice does not award
XP or falsely increment the full-lesson daily study count.

## Safety and scope
- Purely local SharedPreferences on the same device, no external telemetry.
- Question text, submitted choice and personal identity are never stored by
  the notebook. Only lesson IDs and 24-character hashed fingerprints.
- Bounded storage: 120 lesson IDs with up to 80 mistakes per lesson.
- Delete My Data clears the notebook as well as reading progress, quiz
  activity, favourites and device profile.
- No assumption of authenticated account sync or deployed Supabase.
- This applies to existing local demonstrative lessons, not imported
  third-party PDFs where interactive question banks do not exist.
- Confirmed by Flutter analyze/test and Android/Web CI before merging.
