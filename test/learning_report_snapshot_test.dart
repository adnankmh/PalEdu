import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report.dart';
import 'package:paledu/data/learning_report_snapshot.dart';

void main() {
  test('snapshot consumes a single-use lazy stream exactly once', () {
    var traversals = 0;
    Iterable<LearningAttempt> attempts() sync* {
      traversals++;
      if (traversals > 1) {
        throw StateError('The source cannot be replayed');
      }
      yield const LearningAttempt(
        lessonId: ' رياضيات-١ ',
        correctAnswers: 1,
        totalQuestions: 2,
      );
      yield const LearningAttempt(
        lessonId: 'رياضيات-١',
        correctAnswers: 2,
        totalQuestions: 2,
      );
      yield const LearningAttempt(
        lessonId: 'علوم-٢',
        correctAnswers: 0,
        totalQuestions: 4,
      );
    }

    final snapshot = buildLearningReportSnapshot(attempts());
    expect(traversals, 1);
    expect(snapshot.overall.attempts, 3);
    expect(snapshot.overall.lessonsPracticed, 2);
    expect(snapshot.overall.correctAnswers, 3);
    expect(snapshot.overall.totalQuestions, 8);
    expect(snapshot.byLesson.keys.toList(), ['رياضيات-١', 'علوم-٢']);
    expect(snapshot.byLesson['رياضيات-١']!.accuracyPercent, 75);
    expect(snapshot.revisionLessons(limit: 1), ['علوم-٢']);
    expect(() => snapshot.byLesson.clear(), throwsUnsupportedError);
  });

  test('snapshot rejects malformed late attempts without partial results', () {
    final source = <LearningAttempt>[
      const LearningAttempt(
        lessonId: 'علوم',
        correctAnswers: 1,
        totalQuestions: 2,
      ),
      const LearningAttempt(
        lessonId: 'رياضيات',
        correctAnswers: 3,
        totalQuestions: 2,
      ),
    ];
    expect(() => buildLearningReportSnapshot(source), throwsFormatException);
  });

  test('empty snapshot reports no fabricated accuracy or revisions', () {
    final snapshot = buildLearningReportSnapshot(const <LearningAttempt>[]);
    expect(snapshot.overall.accuracyPercent, isNull);
    expect(snapshot.byLesson, isEmpty);
    expect(snapshot.revisionLessons(), isEmpty);
  });
}
