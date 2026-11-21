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
  test('supports Arabic lesson identifiers without changing their identity', () {
    final report = buildLearningReport(const [
      LearningAttempt(lessonId: ' رياضيات-١ ', correctAnswers: 2, totalQuestions: 3),
      LearningAttempt(lessonId: 'رياضيات-١', correctAnswers: 1, totalQuestions: 2),
      LearningAttempt(lessonId: 'علوم-٢', correctAnswers: 2, totalQuestions: 2),
    ]);
    expect(report.attempts, 3);
    expect(report.lessonsPracticed, 2);
    expect(report.accuracyPercent, closeTo(100 * 5 / 7, 0.000001));
  });

  test('per-lesson breakdown counts repeated attempts and weighted accuracy', () {
    final byLesson = buildLessonBreakdown(const [
      LearningAttempt(lessonId: ' رياضيات-١ ', correctAnswers: 1, totalQuestions: 2),
      LearningAttempt(lessonId: 'رياضيات-١', correctAnswers: 3, totalQuestions: 3),
      LearningAttempt(lessonId: 'علوم-٢', correctAnswers: 0, totalQuestions: 5),
    ]);
    expect(byLesson.keys, containsAll(['رياضيات-١', 'علوم-٢']));
    expect(byLesson.length, 2);
    expect(byLesson['رياضيات-١']!.attempts, 2);
    expect(byLesson['رياضيات-١']!.accuracyPercent, 80);
    expect(byLesson['علوم-٢']!.accuracyPercent, 0);
    expect(() => byLesson.clear(), throwsUnsupportedError);
  });

  test('per-lesson breakdown rejects invalid attempts', () {
    expect(
      () => buildLessonBreakdown(const [
        LearningAttempt(lessonId: 'math', correctAnswers: 1, totalQuestions: 2),
        LearningAttempt(lessonId: 'science', correctAnswers: 4, totalQuestions: 3),
      ]),
      throwsFormatException,
    );
  });

  test('empty breakdown has no invented lesson rows', () {
    final byLesson = buildLessonBreakdown(const <LearningAttempt>[]);
    expect(byLesson, isEmpty);
    expect(() => byLesson['missing'] = const LearningReport(
      attempts: 1,
      lessonsPracticed: 1,
      correctAnswers: 1,
      totalQuestions: 1,
    ), throwsUnsupportedError);
  });

  test('per-lesson reports remain stable after input list changes', () {
    final attempts = <LearningAttempt>[
      const LearningAttempt(
        lessonId: 'رياضيات-١',
        correctAnswers: 1,
        totalQuestions: 2,
      ),
    ];
    final byLesson = buildLessonBreakdown(attempts);
    attempts.add(const LearningAttempt(
      lessonId: 'رياضيات-١',
      correctAnswers: 2,
      totalQuestions: 2,
    ));
    expect(byLesson['رياضيات-١']!.attempts, 1);
    expect(byLesson['رياضيات-١']!.totalQuestions, 2);
    expect(byLesson['رياضيات-١']!.accuracyPercent, 50);
  });

  test('breakdown totals reconcile with the aggregate report', () {
    final attempts = <LearningAttempt>[
      const LearningAttempt(lessonId: 'رياضيات-١', correctAnswers: 2, totalQuestions: 3),
      const LearningAttempt(lessonId: 'علوم-٢', correctAnswers: 1, totalQuestions: 5),
      const LearningAttempt(lessonId: ' رياضيات-١ ', correctAnswers: 4, totalQuestions: 4),
    ];
    final overall = buildLearningReport(attempts);
    final byLesson = buildLessonBreakdown(attempts);
    expect(byLesson.keys.toList(), ['رياضيات-١', 'علوم-٢']);
    expect(byLesson.values.fold<int>(0, (sum, row) => sum + row.attempts),
        overall.attempts);
    expect(byLesson.values.fold<int>(0, (sum, row) => sum + row.correctAnswers),
        overall.correctAnswers);
    expect(byLesson.values.fold<int>(0, (sum, row) => sum + row.totalQuestions),
        overall.totalQuestions);
    expect(byLesson.values.every((row) => row.lessonsPracticed == 1), isTrue);
  });


}
