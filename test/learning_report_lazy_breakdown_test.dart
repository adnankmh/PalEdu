import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report.dart';

void main() {
  test('breakdown consumes a lazy sequence once and preserves first-seen order', () {
    var visits = 0;
    Iterable<LearningAttempt> attempts() sync* {
      visits++;
      yield const LearningAttempt(
        lessonId: ' رياضيات-١ ',
        correctAnswers: 1,
        totalQuestions: 3,
      );
      yield const LearningAttempt(
        lessonId: 'علوم-٢',
        correctAnswers: 2,
        totalQuestions: 4,
      );
      yield const LearningAttempt(
        lessonId: 'رياضيات-١',
        correctAnswers: 3,
        totalQuestions: 3,
      );
    }

    final breakdown = buildLessonBreakdown(attempts());
    expect(visits, 1);
    expect(breakdown.keys.toList(), ['رياضيات-١', 'علوم-٢']);
    expect(breakdown['رياضيات-١']!.attempts, 2);
    expect(breakdown['رياضيات-١']!.correctAnswers, 4);
    expect(breakdown['رياضيات-١']!.totalQuestions, 6);
    expect(breakdown['علوم-٢']!.accuracyPercent, 50);
    expect(() => breakdown.remove('علوم-٢'), throwsUnsupportedError);
  });

  test('late invalid attempt aborts lazy per-lesson breakdown', () {
    Iterable<LearningAttempt> attempts() sync* {
      yield const LearningAttempt(
        lessonId: 'رياضيات-١',
        correctAnswers: 1,
        totalQuestions: 2,
      );
      yield const LearningAttempt(
        lessonId: 'علوم-٢',
        correctAnswers: 3,
        totalQuestions: 2,
      );
    }

    expect(() => buildLessonBreakdown(attempts()), throwsFormatException);
  });
}
