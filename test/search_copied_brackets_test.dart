import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/lesson_search.dart';
import 'package:paledu/data/resource_search.dart';

void main() {
  test('pasted worksheet brackets and slash delimit search terms', () {
    const resource = <String, dynamic>{
      'title': 'ملزمة الجبر',
      'subject': 'الرياضيات',
    };
    expect(matchesResourceSearch(resource, 'الرياضيات(الجبر)'), isTrue);
    expect(matchesResourceSearch(resource, 'الرياضيات[الجبر]'), isTrue);
    expect(matchesResourceSearch(resource, 'الرياضيات/الجبر'), isTrue);
    expect(matchesResourceSearch(resource, 'الرياضيات\\الجبر'), isTrue);
    expect(matchesResourceSearch(resource, 'الرياضيات（الجبر）'), isTrue);
    expect(matchesResourceSearch(resource, 'الرياضيات{الجبر}'), isTrue);
    expect(matchesResourceSearch(resource, 'الرياضيات|الجبر'), isTrue);
    expect(matchesResourceSearch(resource, 'الرياضيات|العلوم'), isFalse);
    expect(matchesResourceSearch(resource, 'العلوم/الجبر'), isFalse);
  });

  test('contracted Arabic articles normalize after copied brackets', () {
    const resource = <String, dynamic>{
      'title': 'مدخل للأعداد',
      'subject': 'الرياضيات',
      'url': 'https://example.org/private?token=never-search-this',
    };
    expect(normalizeLessonSearch('الرياضيات(للأعداد)'),
        'الرياضيات لالاعداد');
    expect(matchesResourceSearch(resource, 'الرياضيات(للأعداد)'), isTrue);
    expect(matchesResourceSearch(resource, 'الرياضيات/never-search-this'),
        isFalse);
  });
  test('copied RTL marks and Arabic-Indic digits remain searchable', () {
    const resource = <String, dynamic>{
      'title': 'تمارين الجبر 12',
      'subject': 'الرياضيات',
      'description': 'private-instructor-notes',
      'url': 'https://example.org/private?token=secret-12',
    };
    const pasted = 'الرياضيات(\u200Fالجبر/١٢)';
    expect(pasted.runes, contains(0x200F));
    expect(matchesResourceSearch(resource, pasted), isTrue);
    expect(matchesResourceSearch(resource, 'الرياضيات{الجبر|۱۲}'), isTrue);
    expect(matchesResourceSearch(resource, 'الرياضيات(private-instructor-notes)'), isFalse);
    expect(matchesResourceSearch(resource, 'الرياضيات{secret-12}'), isFalse);
  });
  test('nested mixed worksheet delimiters preserve cross-field AND matching', () {
    const resource = <String, dynamic>{
      'title': 'تمارين الجبر 12',
      'subject': 'الرياضيات',
      'description': 'teacher-only-geometry',
      'url': 'https://example.org/private?token=geometry-12',
    };
    expect(matchesResourceSearch(resource, '（الرياضيات）(الجبر/١٢)'), isTrue);
    expect(matchesResourceSearch(resource, '{١٢|الجبر}[الرياضيات]'), isTrue);
    expect(matchesResourceSearch(resource, '{١٢|الهندسة}[الرياضيات]'), isFalse);
    expect(matchesResourceSearch(resource, '(teacher-only-geometry)/الجبر'), isFalse);
  });

}
