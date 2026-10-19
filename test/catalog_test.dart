import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/models.dart';

Map<String, dynamic> sampleLesson() => {
  'id': 'demo-1',
  'grade': 2,
  'track': 'عام',
  'subject': 'الرياضيات',
  'title': 'درس',
  'summary': 'ملخص',
  'sections': ['شرح'],
  'questions': [
    {
      'prompt': 'السؤال الأول',
      'options': ['1', '2'],
      'answer': 0,
      'explanation': 'الشرح الأول',
    },
    {
      'prompt': 'السؤال الثاني',
      'options': ['3', '4'],
      'answer': 1,
      'explanation': 'الشرح الثاني',
    },
  ],
};

String catalogFor(Map<String, dynamic> lesson) => jsonEncode({
  'contentStatus': 'demonstration_only',
  'lessons': [lesson],
});

void main() {
  test('student track selection covers grade 12', () {
    expect(LessonCatalog.tracksFor(1), ['عام']);
    expect(LessonCatalog.tracksFor(12), hasLength(7));
    expect(LessonCatalog.gradeName(12), contains('التوجيهي'));
  });

  test('catalog rejects unverified official label', () {
    expect(() => LessonCatalog.parse(
      '{"contentStatus":"official","lessons":[]}'), throwsFormatException);
    expect(() => LessonCatalog.parse(
      '{"contentStatus":"demonstration_only","lessons":[]}'), returnsNormally);
  });

  test('rejects invalid quiz answer indices', () {
    expect(() => QuizQuestion.fromJson({
      'prompt': 'سؤال', 'options': ['أ', 'ب'], 'answer': 4,
      'explanation': 'شرح',
    }), throwsFormatException);
  });

  test('rejects lessons without quiz questions', () {
    final lesson = sampleLesson()..['questions'] = [];
    expect(() => LessonCatalog.parse(catalogFor(lesson)), throwsFormatException);
  });

  test('rejects repeated correct-answer labels within a matching lesson', () {
    final lesson = sampleLesson();
    final questions = lesson['questions'] as List;
    final second = questions[1] as Map<String, dynamic>;
    second['options'] = ['4', '1'];
    second['answer'] = 1;
    expect(() => LessonCatalog.parse(catalogFor(lesson)), throwsFormatException);
  });

  test('rejects duplicate choices and blank explanations', () {
    expect(() => QuizQuestion.fromJson({
      'prompt': 'سؤال', 'options': ['أ', ' أ '], 'answer': 0,
      'explanation': 'شرح',
    }), throwsFormatException);
    expect(() => QuizQuestion.fromJson({
      'prompt': 'سؤال', 'options': ['أ', 'ب'], 'answer': 0,
      'explanation': ' ',
    }), throwsFormatException);
  });

  test('all checked-in demonstration lessons load safely', () {
    final raw = File('assets/curriculum/sample_lessons.json').readAsStringSync();
    final catalog = LessonCatalog.parse(raw);
    expect(catalog.lessons, hasLength(48));
    for (final lesson in catalog.lessons) {
      expect(lesson.questions, isNotEmpty);
      expect(lesson.questions.map((q) => q.options[q.correct]).toSet().length,
          lesson.questions.length);
    }
  });
}
