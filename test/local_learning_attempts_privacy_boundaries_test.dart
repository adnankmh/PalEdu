import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/state/student_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores valid local attempts while excluding malformed and oversized records', () async {
    SharedPreferences.setMockInitialValues({
      'learning_attempts_v1': jsonEncode([
        {'lesson': ' رياضيات-١ ', 'correct': 0, 'total': 1},
        {'lesson': 'علوم', 'correct': true, 'total': 1},
        {'lesson': 'علوم', 'correct': 1, 'total': 10001},
        {'lesson': List.filled(161, 'x').join(), 'correct': 1, 'total': 1},
        {'lesson': 'علوم', 'correct': 1, 'total': 2},
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final student = StudentState(prefs);
    expect(student.learningReport.attempts, 2);
    expect(student.learningReport.correctAnswers, 1);
    expect(student.learningReport.totalQuestions, 3);
    expect(student.learningAttempts.first.lessonId, 'رياضيات-١');
    await student.erase();
    expect(StudentState(prefs).learningReport.attempts, 0);
    expect(prefs.containsKey('learning_attempts_v1'), isFalse);
  });

  test('non-list persisted report data cannot become student attempts', () async {
    SharedPreferences.setMockInitialValues({
      'learning_attempts_v1': jsonEncode({'lesson': 'علوم', 'correct': 1, 'total': 1}),
    });
    final prefs = await SharedPreferences.getInstance();
    expect(StudentState(prefs).learningReport.attempts, 0);
  });
}
