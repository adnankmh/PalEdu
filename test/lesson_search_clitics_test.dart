import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/lesson_search.dart';
import 'package:paledu/data/models.dart';

const lessonWithClitic = Lesson(
  id: 'search-lam-contraction',
  grade: 5,
  track: 'عام',
  subject: 'الرياضيات',
  title: 'التدرب على الجمع',
  summary: 'تمهيد للأعداد والجمع والطرح',
  sections: <String>['تمارين للأعداد'], 
  questions: <QuizQuestion>[],
  duration: 10,
);

void main() {
  test('lam + definite article contraction matches unprefixed noun', () {
    expect(matchesLessonSearch(lessonWithClitic, 'الاعداد'), isTrue);
    expect(matchesLessonSearch(lessonWithClitic, 'للأعداد'), isTrue);
    expect(normalizeLessonSearch('للأعداد'), 'لالاعداد');
  });

  test('contracted lam still rejects unrelated search terms', () {
    expect(matchesLessonSearch(lessonWithClitic, 'الجغرافيا'), isFalse);
    expect(matchesLessonSearch(lessonWithClitic, 'العداد'), isFalse);
  });
}
