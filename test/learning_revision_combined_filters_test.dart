import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report.dart';

void main() {
  test('combined revision filters keep weighted Arabic ties stable', () {
    final breakdown = buildLessonBreakdown(const [
      LearningAttempt(lessonId: ' علوم ', correctAnswers: 0, totalQuestions: 1),
      LearningAttempt(lessonId: 'رياضيات', correctAnswers: 1, totalQuestions: 4),
      LearningAttempt(lessonId: 'تاريخ', correctAnswers: 2, totalQuestions: 8),
      LearningAttempt(lessonId: 'رياضيات', correctAnswers: 1, totalQuestions: 4),
      LearningAttempt(lessonId: 'تاريخ', correctAnswers: 0, totalQuestions: 2),
      LearningAttempt(lessonId: 'لغة عربية', correctAnswers: 5, totalQuestions: 5),
    ]);

    // One perfect or single-attempt lesson must not distort revision advice.
    final suggested = lessonsForRevision(
      breakdown,
      minimumAttempts: 2,
      maximumAccuracyPercent: 25,
      limit: 2,
    );
    expect(suggested, ['تاريخ', 'رياضيات']);
    expect(() => suggested.add('علوم'), throwsUnsupportedError);
    expect(
      lessonsForRevision(
        breakdown,
        minimumAttempts: 2,
        maximumAccuracyPercent: 19,
      ),
      isEmpty,
    );
    expect(
      lessonsForRevision(
        breakdown,
        minimumAttempts: 2,
        maximumAccuracyPercent: 20,
      ),
      ['تاريخ'],
    );
  });
}
