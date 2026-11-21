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

  test('surrounding whitespace does not double count the same lesson', () {
    final report = buildLearningReport(const [
      LearningAttempt(lessonId: ' math-1 ', correctAnswers: 1, totalQuestions: 2),
      LearningAttempt(lessonId: 'math-1', correctAnswers: 2, totalQuestions: 2),
      LearningAttempt(lessonId: ' science-1 ', correctAnswers: 1, totalQuestions: 1),
    ]);
    expect(report.attempts, 3);
    expect(report.lessonsPracticed, 2);
    expect(report.correctAnswers, 4);
    expect(report.totalQuestions, 5);
    expect(report.accuracyPercent, 80);
  });

  test('zero and full scores remain valid attempts', () {
    final report = buildLearningReport(const [
      LearningAttempt(lessonId: 'math-1', correctAnswers: 0, totalQuestions: 3),
      LearningAttempt(lessonId: 'science-1', correctAnswers: 2, totalQuestions: 2),
    ]);
    expect(report.attempts, 2);
    expect(report.lessonsPracticed, 2);
    expect(report.correctAnswers, 2);
    expect(report.totalQuestions, 5);
    expect(report.accuracyPercent, 40);
  });

  test('accuracy is weighted by questions rather than attempt averages', () {
    final report = buildLearningReport(const [
      LearningAttempt(lessonId: 'math-1', correctAnswers: 1, totalQuestions: 1),
      LearningAttempt(lessonId: 'math-2', correctAnswers: 0, totalQuestions: 9),
    ]);
    expect(report.accuracyPercent, 10);
  });

  test('rejects invalid attempts instead of producing misleading statistics', () {
    for (final attempt in const [
      LearningAttempt(lessonId: '', correctAnswers: 0, totalQuestions: 1),
      LearningAttempt(lessonId: '   ', correctAnswers: 0, totalQuestions: 1),
      LearningAttempt(lessonId: 'x', correctAnswers: -1, totalQuestions: 2),
      LearningAttempt(lessonId: 'x', correctAnswers: 3, totalQuestions: 2),
      LearningAttempt(lessonId: 'x', correctAnswers: 0, totalQuestions: 0),
      LearningAttempt(lessonId: 'x', correctAnswers: 0, totalQuestions: -1),
    ]) {
      expect(() => buildLearningReport([attempt]), throwsFormatException);
    }
  });

  test('a malformed later attempt rejects the whole report', () {
    expect(
      () => buildLearningReport(const [
        LearningAttempt(lessonId: 'math-1', correctAnswers: 2, totalQuestions: 3),
        LearningAttempt(lessonId: 'science-1', correctAnswers: 4, totalQuestions: 3),
      ]),
      throwsFormatException,
    );
  });
}
