import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/state/student_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('completed quiz persists a privacy-limited local learning report', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final student = StudentState(prefs);
    await student.finish('رياضيات-١', 2, 3);
    await student.finish('رياضيات-١', 1, 2);
    expect(student.learningReport.attempts, 2);
    expect(student.learningReport.lessonsPracticed, 1);
    expect(student.learningReport.correctAnswers, 3);
    expect(student.learningReport.totalQuestions, 5);
    final stored = prefs.getString('learning_attempts_v1')!;
    expect(stored, isNot(contains('name')));
    expect(stored, isNot(contains('email')));
    final restored = StudentState(prefs);
    expect(restored.learningReport.accuracyPercent, 60);
    await restored.erase();
    expect(prefs.containsKey('learning_attempts_v1'), isFalse);
    expect(restored.learningReport.attempts, 0);
  });

  test('corrupt and invalid stored attempts do not prevent startup', () async {
    SharedPreferences.setMockInitialValues({
      'learning_attempts_v1': jsonEncode([
        {'lesson': 'علوم', 'correct': 1, 'total': 2},
        {'lesson': 'علوم', 'correct': 3, 'total': 2},
        {'lesson': '', 'correct': 0, 'total': 1},
        {'lesson': 'رياضيات', 'correct': 1, 'total': 'bad'},
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    expect(StudentState(prefs).learningReport.attempts, 1);
    await prefs.setString('learning_attempts_v1', '{broken');
    expect(StudentState(prefs).learningReport.attempts, 0);
  });

  test('oversized restored history keeps the newest 200 records', () async {
    SharedPreferences.setMockInitialValues({
      'learning_attempts_v1': jsonEncode([
        for (var i = 0; i < 205; i++)
          {'lesson': 'lesson-$i', 'correct': 1, 'total': 1},
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final restored = StudentState(prefs);
    expect(restored.learningReport.attempts, 200);
    expect(restored.learningAttempts.first.lessonId, 'lesson-5');
    expect(restored.learningAttempts.last.lessonId, 'lesson-204');
  });

  test('invalid newest records do not displace valid restored attempts', () async {
    SharedPreferences.setMockInitialValues({
      'learning_attempts_v1': jsonEncode([
        for (var i = 0; i < 205; i++)
          {'lesson': 'lesson-$i', 'correct': 1, 'total': 1},
        for (var i = 0; i < 10; i++)
          {'lesson': 'invalid-$i', 'correct': 2, 'total': 1},
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final restored = StudentState(prefs);
    expect(restored.learningReport.attempts, 200);
    expect(restored.learningAttempts.first.lessonId, 'lesson-5');
    expect(restored.learningAttempts.last.lessonId, 'lesson-204');
  });

  test('local history retains only the most recent 200 attempts', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final student = StudentState(prefs);
    for (var i = 0; i < 205; i++) {
      await student.finish('lesson-$i', 1, 1);
    }
    expect(student.learningReport.attempts, 200);
    expect(student.learningAttempts.first.lessonId, 'lesson-5');
    expect(StudentState(prefs).learningReport.attempts, 200);
  });
}
