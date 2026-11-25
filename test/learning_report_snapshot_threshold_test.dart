import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report.dart';
import 'package:paledu/data/learning_report_snapshot.dart';

void main() {
  test('snapshot revision filters preserve exact threshold boundaries', () {
    final snapshot = buildLearningReportSnapshot(const [
      LearningAttempt(lessonId: 'علوم', correctAnswers: 0, totalQuestions: 5),
      LearningAttempt(lessonId: 'رياضيات', correctAnswers: 4, totalQuestions: 5),
      LearningAttempt(lessonId: 'رياضيات', correctAnswers: 4, totalQuestions: 5),
      LearningAttempt(lessonId: 'تاريخ', correctAnswers: 5, totalQuestions: 5),
    ]);

    expect(snapshot.overall.accuracyPercent, 65);
    expect(snapshot.revisionLessons(maximumAccuracyPercent: 0), ['علوم']);
    expect(
      snapshot.revisionLessons(
        minimumAttempts: 2,
        maximumAccuracyPercent: 80,
      ),
      ['رياضيات'],
    );
    expect(
      snapshot.revisionLessons(
        minimumAttempts: 2,
        maximumAccuracyPercent: 79.999,
      ),
      isEmpty,
    );
    expect(snapshot.revisionLessons(limit: 0), isEmpty);
    expect(
      () => snapshot.revisionLessons(maximumAccuracyPercent: double.nan),
      throwsFormatException,
    );
    expect(
      () => snapshot.revisionLessons(minimumAttempts: 0),
      throwsFormatException,
    );
  });
}
