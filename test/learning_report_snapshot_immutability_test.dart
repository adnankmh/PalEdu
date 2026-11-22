import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report.dart';
import 'package:paledu/data/learning_report_snapshot.dart';

void main() {
  test('snapshot normalizes lesson IDs and isolates immutable results', () {
    final attempts = <LearningAttempt>[
      const LearningAttempt(
        lessonId: '  رياضيات  ',
        correctAnswers: 2,
        totalQuestions: 4,
      ),
      const LearningAttempt(
        lessonId: 'رياضيات',
        correctAnswers: 3,
        totalQuestions: 4,
      ),
      const LearningAttempt(
        lessonId: 'علوم',
        correctAnswers: 1,
        totalQuestions: 2,
      ),
    ];

    final snapshot = buildLearningReportSnapshot(attempts);
    attempts.clear();

    expect(snapshot.overall.attempts, 3);
    expect(snapshot.overall.lessonsPracticed, 2);
    expect(snapshot.overall.correctAnswers, 6);
    expect(snapshot.overall.totalQuestions, 10);
    expect(snapshot.byLesson.keys.toList(), ['رياضيات', 'علوم']);
    expect(snapshot.byLesson['رياضيات']!.attempts, 2);
    expect(snapshot.byLesson['رياضيات']!.accuracyPercent, 62.5);
    expect(snapshot.revisionLessons(), ['علوم', 'رياضيات']);
    expect(
      () => snapshot.byLesson.clear(),
      throwsUnsupportedError,
    );
    final revisions = snapshot.revisionLessons();
    expect(() => revisions.add('تاريخ'), throwsUnsupportedError);
    expect(snapshot.overall.attempts, 3);
  });
}
