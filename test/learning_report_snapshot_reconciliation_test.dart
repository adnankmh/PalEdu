import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report.dart';
import 'package:paledu/data/learning_report_snapshot.dart';

void main() {
  test('single-pass snapshot reconciles with independent aggregate and lesson totals', () {
    final attempts = List<LearningAttempt>.generate(
      360,
      (index) => LearningAttempt(
        lessonId: index % 3 == 0 ? ' رياضيات-١ ' : index % 3 == 1 ? 'علوم-٢' : 'لغة-٣',
        correctAnswers: index % 7,
        totalQuestions: 7 + index % 5,
      ),
    );

    final snapshot = buildLearningReportSnapshot(attempts);
    final overall = buildLearningReport(attempts);
    final breakdown = buildLessonBreakdown(attempts);

    expect(snapshot.overall.attempts, overall.attempts);
    expect(snapshot.overall.lessonsPracticed, overall.lessonsPracticed);
    expect(snapshot.overall.correctAnswers, overall.correctAnswers);
    expect(snapshot.overall.totalQuestions, overall.totalQuestions);
    expect(snapshot.overall.accuracyPercent, overall.accuracyPercent);
    expect(snapshot.byLesson.keys.toList(), breakdown.keys.toList());
    for (final id in breakdown.keys) {
      expect(snapshot.byLesson[id]!.attempts, breakdown[id]!.attempts);
      expect(snapshot.byLesson[id]!.correctAnswers, breakdown[id]!.correctAnswers);
      expect(snapshot.byLesson[id]!.totalQuestions, breakdown[id]!.totalQuestions);
    }
    expect(
      snapshot.revisionLessons(limit: 2, minimumAttempts: 100),
      lessonsForRevision(breakdown, limit: 2, minimumAttempts: 100),
    );
    expect(() => snapshot.byLesson.clear(), throwsUnsupportedError);
  });
}
