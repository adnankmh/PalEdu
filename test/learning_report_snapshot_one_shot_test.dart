import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report.dart';
import 'package:paledu/data/learning_report_snapshot.dart';

void main() {
  test('snapshot consumes a one-shot stream exactly once', () {
    var reads = 0;
    Iterable<LearningAttempt> source() sync* {
      reads++;
      if (reads != 1) {
        throw StateError('attempt source must not be traversed twice');
      }
      yield const LearningAttempt(
        lessonId: 'رياضيات',
        correctAnswers: 1,
        totalQuestions: 3,
      );
      yield const LearningAttempt(
        lessonId: 'علوم',
        correctAnswers: 2,
        totalQuestions: 2,
      );
      yield const LearningAttempt(
        lessonId: ' رياضيات ',
        correctAnswers: 3,
        totalQuestions: 3,
      );
    }

    final snapshot = buildLearningReportSnapshot(source());
    expect(reads, 1);
    expect(snapshot.overall.attempts, 3);
    expect(snapshot.overall.lessonsPracticed, 2);
    expect(snapshot.overall.correctAnswers, 6);
    expect(snapshot.overall.totalQuestions, 8);
    expect(snapshot.byLesson['رياضيات']!.attempts, 2);
    expect(snapshot.byLesson['رياضيات']!.correctAnswers, 4);
    expect(snapshot.revisionLessons(), ['رياضيات', 'علوم']);
    expect(reads, 1);
  });

  test('invalid late attempt rejects entire one-shot report', () {
    var reads = 0;
    Iterable<LearningAttempt> source() sync* {
      reads++;
      yield const LearningAttempt(
        lessonId: 'علوم',
        correctAnswers: 1,
        totalQuestions: 2,
      );
      yield const LearningAttempt(
        lessonId: 'رياضيات',
        correctAnswers: 5,
        totalQuestions: 4,
      );
    }

    expect(
      () => buildLearningReportSnapshot(source()),
      throwsFormatException,
    );
    expect(reads, 1);
  });
}
