/// Local-only learning report calculations; no learner identifiers or network calls.
class LearningAttempt {
  const LearningAttempt({
    required this.lessonId,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  final String lessonId;
  final int correctAnswers;
  final int totalQuestions;
}

class LearningReport {
  const LearningReport({
    required this.attempts,
    required this.lessonsPracticed,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  final int attempts;
  final int lessonsPracticed;
  final int correctAnswers;
  final int totalQuestions;

  /// Null when no questions have been answered; avoids a misleading 0% grade.
  double? get accuracyPercent =>
      totalQuestions == 0 ? null : 100 * correctAnswers / totalQuestions;
}

/// Summarizes only validated, completed attempts. Invalid data is rejected
/// rather than silently inflating or deflating the learner's report.
LearningReport buildLearningReport(Iterable<LearningAttempt> attempts) {
  var count = 0;
  var correct = 0;
  var total = 0;
  final lessonIds = <String>{};
  for (final attempt in attempts) {
    if (attempt.lessonId.trim().isEmpty ||
        attempt.totalQuestions <= 0 ||
        attempt.correctAnswers < 0 ||
        attempt.correctAnswers > attempt.totalQuestions) {
      throw const FormatException('Invalid learning attempt');
    }
    count++;
    correct += attempt.correctAnswers;
    total += attempt.totalQuestions;
    lessonIds.add(attempt.lessonId.trim());
  }
  return LearningReport(
    attempts: count,
    lessonsPracticed: lessonIds.length,
    correctAnswers: correct,
    totalQuestions: total,
  );
}

/// Local per-lesson totals for a teacher's or student's progress view.
/// Keys are trimmed lesson IDs; no learner identity or private metadata is stored.
Map<String, LearningReport> buildLessonBreakdown(
  Iterable<LearningAttempt> attempts,
) {
  final counts = <String, int>{};
  final correct = <String, int>{};
  final totals = <String, int>{};
  for (final attempt in attempts) {
    // Validate before changing any per-lesson totals.
    if (attempt.lessonId.trim().isEmpty ||
        attempt.totalQuestions <= 0 ||
        attempt.correctAnswers < 0 ||
        attempt.correctAnswers > attempt.totalQuestions) {
      throw const FormatException('Invalid learning attempt');
    }
    final id = attempt.lessonId.trim();
    counts[id] = (counts[id] ?? 0) + 1;
    correct[id] = (correct[id] ?? 0) + attempt.correctAnswers;
    totals[id] = (totals[id] ?? 0) + attempt.totalQuestions;
  }
  return Map<String, LearningReport>.unmodifiable({
    for (final id in counts.keys)
      id: LearningReport(
        attempts: counts[id]!,
        lessonsPracticed: 1,
        correctAnswers: correct[id]!,
        totalQuestions: totals[id]!,
      ),
  });
}

/// Returns the lessons with the lowest weighted accuracy first, so a local
/// progress screen can suggest revision without transmitting learner data.
/// Ties preserve the original order in [buildLessonBreakdown].
/// [limit] must be non-negative; zero returns an empty, immutable list.
List<String> lessonsForRevision(
  Map<String, LearningReport> breakdown, {
  int limit = 3,
}) {
  if (limit < 0) {
    throw const FormatException('Invalid revision limit');
  }
  final entries = breakdown.entries.toList();
  // Dart's List.sort is not guaranteed stable; retain the source position.
  final positions = <String, int>{
    for (var i = 0; i < entries.length; i++) entries[i].key: i,
  };
  entries.sort((a, b) {
    final left = a.value.accuracyPercent;
    final right = b.value.accuracyPercent;
    if (left == null || right == null) {
      return left == null && right == null
          ? positions[a.key]!.compareTo(positions[b.key]!)
          : left == null ? 1 : -1;
    }
    final order = left.compareTo(right);
    return order != 0 ? order : positions[a.key]!.compareTo(positions[b.key]!);
  });
  return List<String>.unmodifiable(
    entries.take(limit).map((entry) => entry.key),
  );
}
