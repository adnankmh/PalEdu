import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report_snapshot.dart';
import 'package:paledu/data/learning_report.dart';

void main() {
  test('large equal-accuracy cohort preserves first-practiced Arabic order', () {
    final attempts = <LearningAttempt>[
      for (var i = 0; i < 120; i++)
        LearningAttempt(
          lessonId: ' درس ${i.toString().padLeft(3, '0')} ',
          correctAnswers: 1,
          totalQuestions: 2,
        ),
    ];

    final snapshot = buildLearningReportSnapshot(attempts);
    expect(snapshot.overall.attempts, 120);
    expect(snapshot.overall.lessonsPracticed, 120);
    expect(snapshot.overall.accuracyPercent, 50);
    expect(snapshot.byLesson.keys.first, 'درس 000');
    expect(snapshot.revisionLessons(limit: 5, maximumAccuracyPercent: 50),
        ['درس 000', 'درس 001', 'درس 002', 'درس 003', 'درس 004']);
    expect(snapshot.revisionLessons(maximumAccuracyPercent: 49), isEmpty);
    expect(
      () => snapshot.revisionLessons(limit: 5).add('درس خاص'),
      throwsUnsupportedError,
    );
  });
}
