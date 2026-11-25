import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report.dart';

void main() {
  test('revision ranks weighted question accuracy, not attempt averages', () {
    final attempts = <LearningAttempt>[
      const LearningAttempt(
        lessonId: 'الكسور',
        correctAnswers: 1,
        totalQuestions: 1,
      ),
      const LearningAttempt(
        lessonId: 'الكسور',
        correctAnswers: 0,
        totalQuestions: 9,
      ),
      const LearningAttempt(
        lessonId: 'الهندسة',
        correctAnswers: 3,
        totalQuestions: 10,
      ),
      const LearningAttempt(
        lessonId: 'الهندسة',
        correctAnswers: 3,
        totalQuestions: 10,
      ),
    ];

    final overall = buildLearningReport(attempts);
    final breakdown = buildLessonBreakdown(attempts);
    expect(overall.attempts, 4);
    expect(overall.lessonsPracticed, 2);
    expect(overall.correctAnswers, 7);
    expect(overall.totalQuestions, 30);
    expect(overall.accuracyPercent, closeTo(23.3333333333, 0.000001));
    expect(breakdown['الكسور']!.accuracyPercent, 10);
    expect(breakdown['الهندسة']!.accuracyPercent, 30);
    expect(
      lessonsForRevision(
        breakdown,
        minimumAttempts: 2,
        maximumAccuracyPercent: 30,
      ),
      ['الكسور', 'الهندسة'],
    );
    expect(
      lessonsForRevision(
        breakdown,
        minimumAttempts: 2,
        maximumAccuracyPercent: 29,
      ),
      ['الكسور'],
    );
  });
}
