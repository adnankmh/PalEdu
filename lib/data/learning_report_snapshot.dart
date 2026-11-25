import 'learning_report.dart';

/// Consistent local report and per-lesson view from one traversal of the input.
/// No learner identity, remote request, or private resource metadata is used.
class LearningReportSnapshot {
  const LearningReportSnapshot({
    required this.overall,
    required this.byLesson,
  });

  final LearningReport overall;
  final Map<String, LearningReport> byLesson;

  List<String> revisionLessons({
    int limit = 3,
    int minimumAttempts = 1,
    double maximumAccuracyPercent = 100,
  }) =>
      lessonsForRevision(
        byLesson,
        limit: limit,
        minimumAttempts: minimumAttempts,
        maximumAccuracyPercent: maximumAccuracyPercent,
      );
}

/// Aggregate in a single pass without retaining the individual attempts.
/// All input is validated before any result is returned. Insertion order of
/// lesson IDs is preserved for deterministic revision recommendations.
LearningReportSnapshot buildLearningReportSnapshot(
  Iterable<LearningAttempt> attempts,
) {
  final counts = <String, int>{};
  final correctByLesson = <String, int>{};
  final totalByLesson = <String, int>{};
  var attemptCount = 0;
  var correctCount = 0;
  var questionCount = 0;

  for (final attempt in attempts) {
    final id = attempt.lessonId.trim();
    if (id.isEmpty ||
        attempt.totalQuestions <= 0 ||
        attempt.correctAnswers < 0 ||
        attempt.correctAnswers > attempt.totalQuestions) {
      throw const FormatException('Invalid learning attempt');
    }
    attemptCount++;
    correctCount += attempt.correctAnswers;
    questionCount += attempt.totalQuestions;
    counts[id] = (counts[id] ?? 0) + 1;
    correctByLesson[id] = (correctByLesson[id] ?? 0) + attempt.correctAnswers;
    totalByLesson[id] = (totalByLesson[id] ?? 0) + attempt.totalQuestions;
  }

  return LearningReportSnapshot(
    overall: LearningReport(
      attempts: attemptCount,
      lessonsPracticed: counts.length,
      correctAnswers: correctCount,
      totalQuestions: questionCount,
    ),
    byLesson: Map<String, LearningReport>.unmodifiable({
      for (final id in counts.keys)
        id: LearningReport(
          attempts: counts[id]!,
          lessonsPracticed: 1,
          correctAnswers: correctByLesson[id]!,
          totalQuestions: totalByLesson[id]!,
        ),
    }),
  );
}
