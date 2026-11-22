import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report.dart';
import 'package:paledu/data/learning_report_snapshot.dart';

void main() {
  test('revision thresholds use question-weighted accuracy at exact boundaries', () {
    final snapshot = buildLearningReportSnapshot([
      const LearningAttempt(lessonId: '  الكسور  ', correctAnswers: 0, totalQuestions: 1),
      const LearningAttempt(lessonId: 'الكسور', correctAnswers: 9, totalQuestions: 9),
      const LearningAttempt(lessonId: 'الجبر', correctAnswers: 0, totalQuestions: 2),
      const LearningAttempt(lessonId: 'الهندسة', correctAnswers: 2, totalQuestions: 2),
    ]);

    expect(snapshot.overall.attempts, 4);
    expect(snapshot.overall.lessonsPracticed, 3);
    expect(snapshot.overall.correctAnswers, 11);
    expect(snapshot.overall.totalQuestions, 14);
    expect(snapshot.byLesson['الكسور']!.accuracyPercent, 90);
    expect(
      snapshot.revisionLessons(maximumAccuracyPercent: 90),
      ['الجبر', 'الكسور'],
    );
    expect(
      snapshot.revisionLessons(maximumAccuracyPercent: 0),
      ['الجبر'],
    );
    expect(
      snapshot.revisionLessons(minimumAttempts: 2, maximumAccuracyPercent: 90),
      ['الكسور'],
    );
    expect(
      snapshot.revisionLessons(limit: 0),
      isEmpty,
    );
  });
}
