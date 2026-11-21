import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report.dart';

void main() {
  test('empty report has no invented accuracy', () {
    final report = buildLearningReport(const <LearningAttempt>[]);
    expect(report.attempts, 0);
    expect(report.lessonsPracticed, 0);
    expect(report.accuracyPercent, isNull);
  });

  test('counts repeated practice without double counting distinct lessons', () {
    final report = buildLearningReport(const [
      LearningAttempt(lessonId: 'math-1', correctAnswers: 3, totalQuestions: 4),
      LearningAttempt(lessonId: 'math-1', correctAnswers: 4, totalQuestions: 4),
      LearningAttempt(lessonId: 'science-1', correctAnswers: 1, totalQuestions: 2),
    ]);
    expect(report.attempts, 3);
    expect(report.lessonsPracticed, 2);
    expect(report.correctAnswers, 8);
    expect(report.totalQuestions, 10);
    expect(report.accuracyPercent, 80);
  });

  test('rejects invalid attempts instead of producing misleading statistics', () {
    for (final attempt in const [
      LearningAttempt(lessonId: '', correctAnswers: 0, totalQuestions: 1),
      LearningAttempt(lessonId: 'x', correctAnswers: -1, totalQuestions: 2),
      LearningAttempt(lessonId: 'x', correctAnswers: 3, totalQuestions: 2),
      LearningAttempt(lessonId: 'x', correctAnswers: 0, totalQuestions: 0),
    ]) {
      expect(() => buildLearningReport([attempt]), throwsFormatException);
    }
  });
}
