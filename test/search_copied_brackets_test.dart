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
}
