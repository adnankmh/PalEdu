import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report.dart';

void main() {
  test('a lazy stream of attempts is consumed once per report', () {
    var reads = 0;
    Iterable<LearningAttempt> source() sync* {
      reads++;
      yield const LearningAttempt(
        lessonId: '  العلوم  ',
        correctAnswers: 2,
        totalQuestions: 3,
      );
      yield const LearningAttempt(
        lessonId: 'العلوم',
        correctAnswers: 4,
        totalQuestions: 5,
      );
      yield const LearningAttempt(
        lessonId: 'الرياضيات',
        correctAnswers: 1,
        totalQuestions: 2,
      );
    }

    final breakdown = buildLessonBreakdown(source());
    expect(reads, 1);
    expect(breakdown.keys.toList(), ['العلوم', 'الرياضيات']);
    expect(breakdown['العلوم']!.attempts, 2);
    expect(breakdown['العلوم']!.correctAnswers, 6);
    expect(breakdown['العلوم']!.totalQuestions, 8);
    expect(breakdown['الرياضيات']!.accuracyPercent, 50);
    expect(lessonsForRevision(breakdown, limit: 1), ['الرياضيات']);
  });

  test('invalid later lazy attempt is rejected instead of reporting partial data', () {
    Iterable<LearningAttempt> source() sync* {
      yield const LearningAttempt(
        lessonId: 'اللغة العربية',
        correctAnswers: 2,
        totalQuestions: 3,
      );
      yield const LearningAttempt(
        lessonId: 'اللغة العربية',
        correctAnswers: 5,
        totalQuestions: 4,
      );
    }

    expect(() => buildLessonBreakdown(source()), throwsFormatException);
    expect(() => buildLearningReport(source()), throwsFormatException);
  });
}
