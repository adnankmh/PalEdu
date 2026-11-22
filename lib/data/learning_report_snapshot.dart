import 'learning_report.dart';

/// Consistent local report and per-lesson view from a single traversal of the
/// input. This supports lazy attempt streams that cannot be replayed.
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

/// Materialize once, then validate both views before returning either.
/// No learner identity, remote request, or private resource metadata is used.
LearningReportSnapshot buildLearningReportSnapshot(
  Iterable<LearningAttempt> attempts,
) {
  final collected = attempts.toList(growable: false);
  final overall = buildLearningReport(collected);
  final byLesson = buildLessonBreakdown(collected);
  return LearningReportSnapshot(overall: overall, byLesson: byLesson);
}
