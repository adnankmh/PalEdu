import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/state/student_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('invalid completed quizzes never mutate progress or local reports', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final student = StudentState(prefs);

    final invalid = <(String, int, int)>[
      ('', 1, 1),
      ('   ', 1, 1),
      ('x' * 161, 1, 1),
      ('math', -1, 2),
      ('math', 3, 2),
      ('math', 0, 0),
      ('math', 1, 10001),
    ];
    for (final (id, score, total) in invalid) {
      await expectLater(
        student.finish(id, score, total),
        throwsArgumentError,
      );
    }

    expect(student.completed, isEmpty);
    expect(student.xp, 0);
    expect(student.reviews, isEmpty);
    expect(student.practiceDays, isEmpty);
    expect(student.learningAttempts, isEmpty);
    expect(prefs.containsKey('learning_attempts_v1'), isFalse);
    expect(StudentState(prefs).learningReport.attempts, 0);
  });
  test('padded lesson IDs share one completion, review and report identity', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final student = StudentState(prefs);

    await student.finish('  رياضيات-١  ', 2, 3);
    await student.finish('رياضيات-١', 3, 3);

    expect(student.completed, {'رياضيات-١'});
    expect(student.reviews.keys, {'رياضيات-١'});
    expect(student.learningReport.lessonsPracticed, 1);
    expect(student.learningReport.attempts, 2);
    expect(student.learningLessonBreakdown['رياضيات-١']!.correctAnswers, 5);
    expect(student.xp, 30);

    final restored = StudentState(prefs);
    expect(restored.completed, {'رياضيات-١'});
    expect(restored.reviews.keys, {'رياضيات-١'});
    expect(restored.learningReport.lessonsPracticed, 1);
    expect(restored.learningReport.attempts, 2);
  });

}
