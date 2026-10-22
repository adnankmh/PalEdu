import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/lesson_search.dart';
import 'package:paledu/data/models.dart';

const scienceLesson = Lesson(
  id: 'offline-search-edge',
  grade: 7,
  track: 'عام',
  subject: 'العلوم والحياة',
  title: 'الطاقة المُتَجَدِّدَة',
  summary: 'مقدمة عن البيئة',
  sections: ['الطاقة الشمسية', 'المياه والرياح'],
  questions: <QuizQuestion>[],
  duration: 12,
);

void main() {
  test('offline search finds words across distinct lesson fields', () {
    expect(matchesLessonSearch(scienceLesson, 'علوم شمسيه'), isTrue);
    expect(matchesLessonSearch(scienceLesson, 'الرياح البيئة'), isTrue);
  });

  test('Arabic variants and elongation do not hide matching lessons', () {
    expect(matchesLessonSearch(scienceLesson, 'الطاقــة المتجددة'), isTrue);
    expect(matchesLessonSearch(scienceLesson, 'المِيَاه'), isTrue);
  });

  test('unrelated terms do not match', () {
    expect(matchesLessonSearch(scienceLesson, 'الرياضيات'), isFalse);
    expect(matchesLessonSearch(scienceLesson, 'العلوم الكيمياء'), isFalse);
  });
}
