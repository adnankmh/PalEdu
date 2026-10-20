# PalEdu — Achievements & Study Habit Center (v0.13)

Student-facing achievements are built from real local quiz attempts and
first-time lesson completions. The home page and profile expose a new
"إنجازاتي" destination.

## Included
- Eight badge milestones, earned from existing saved lesson completions, quiz
  review results, actual subject variety and verified consecutive practice days.
- Personal daily goal of two **completed lesson quiz attempts**. Retaking a
  lesson adds a practice attempt, but XP and first completion remain once only.
- Seven-day activity graph, current streak, due review count and grade-specific
  course completion. Streak is never invented for historical data before update.
- Beautiful royal emerald/gold cards that work in RTL and respect the user's
  reduced-motion preference when showing the existing celebration Lottie.
- Data stored locally via SharedPreferences as day-count aggregates, not names,
  answers, question text or personal identifiers. Keeps up to 180 days of daily
  data; delete-my-data clears the counts.

## Security, fairness and known scope
- No leaderboards, social features, student comparisons or child messaging.
- Eight badges are motivational only; they are **not** school certificates.
- A streak excludes future dates and only counts stored attempts; device time is
  the timestamp source, not verified cloud attendance.
- Activity and earned badges are device-local, not account-synced. Cloud sync
  requires a live authenticated back-end with per-user authorization.
- Existing content remains original demonstration lessons, not a claim that all
  Ministry of Education textbooks are bundled.
- This feature doesn't certify 500k users or deploy Supabase.
- Test with GitHub Actions Flutter analyze/test + Android + Web before merging.
