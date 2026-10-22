import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/lesson_search.dart';
import 'package:paledu/data/models.dart';

const lesson = Lesson(
  id: 'demo-math-1',
  grade: 5,
  track: 'عام',
  subject: 'الرياضيات',
  title: 'مقدمة في الكسور',
  summary: 'شرح أساسي للأعداد الكسرية',
  sections: ['نقارن بين البسط والمقام', 'أمثلة وتدريبات عملية'],
  questions: <QuizQuestion>[],
  duration: 8,
);

void main() {
  test('Arabic diacritics and alef forms do not block matching', () {
    expect(matchesLessonSearch(lesson, 'مُقَدِّمَة الكسور'), isTrue);
    expect(matchesLessonSearch(lesson, 'الاعداد'), isTrue);
  });

  test('search includes subject, summary and section text', () {
    expect(matchesLessonSearch(lesson, 'رياضيات'), isTrue);
    expect(matchesLessonSearch(lesson, 'المقام'), isTrue);
    expect(matchesLessonSearch(lesson, 'الكسريه'), isTrue);
  });

  test('all query words must match, regardless of order', () {
    expect(matchesLessonSearch(lesson, 'المقام الكسور'), isTrue);
    expect(matchesLessonSearch(lesson, 'الكسور الكيمياء'), isFalse);
  });

  test('empty queries match and search is case-insensitive', () {
    expect(matchesLessonSearch(lesson, '   '), isTrue);
    expect(normalizeLessonSearch('  Flutter   WEB '), 'flutter web');
  });
}
