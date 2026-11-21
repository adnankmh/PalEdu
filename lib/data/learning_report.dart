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
    lessonIds.add(attempt.lessonId);
  }
  return LearningReport(
    attempts: count,
    lessonsPracticed: lessonIds.length,
    correctAnswers: correct,
    totalQuestions: total,
  );
}
