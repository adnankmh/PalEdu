import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/lesson_search.dart';
import 'package:paledu/data/resource_search.dart';

void main() {
  test('Arabic and Latin question marks separate copied search terms', () {
    expect(normalizeLessonSearch('العلوم؟ الطاقة?'), 'العلوم الطاقه');
    final resource = <String, dynamic>{
      'title': 'الطاقة المتجددة',
      'subject': 'العلوم والحياة',
    };
    expect(matchesResourceSearch(resource, 'العلوم؟ الطاقة?'), isTrue);
    expect(matchesResourceSearch(resource, 'العلوم؟ الكيمياء?'), isFalse);
  });

  test('colon separators work across titles and subjects', () {
    final resource = <String, dynamic>{
      'title': 'ملزمة الجبر',
      'subject': 'الرياضيات',
      'url': 'https://example.org/private?token=secret-colon',
    };
    expect(matchesResourceSearch(resource, 'الرياضيات:الجبر'), isTrue);
    expect(matchesResourceSearch(resource, 'الرياضيات：الجبر'), isTrue);
    expect(matchesResourceSearch(resource, 'الرياضيات:secret-colon'), isFalse);
  });
}
