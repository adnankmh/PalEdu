import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/resource_search.dart';

void main() {
  final approved = <String, dynamic>{
    'title': 'ملزمة الطاقة المُتَجَدِّدَة',
    'subject': 'العلوم والحياة',
    'url': 'https://example.org/private?token=should-not-be-searched',
  };

  test('Arabic spelling variants match approved resource metadata', () {
    expect(matchesResourceSearch(approved, 'الطاقه المتجددة'), isTrue);
    expect(matchesResourceSearch(approved, 'علوم مُتَجَدِّدَة'), isTrue);
    expect(matchesResourceSearch(approved, 'الحياه ملزمة'), isTrue);
  });

  test('all query words must be present across title and subject', () {
    expect(matchesResourceSearch(approved, 'العلوم الطاقة'), isTrue);
    expect(matchesResourceSearch(approved, 'كيمياء الطاقة'), isFalse);
    expect(matchesResourceSearch(approved, '  '), isTrue);
  });

  test('private URLs and credentials are not searchable fields', () {
    expect(matchesResourceSearch(approved, 'should-not-be-searched'), isFalse);
    expect(matchesResourceSearch(approved, 'example.org'), isFalse);
  });

  test('grade numbers match across Arabic keyboards and copied text', () {
    final resource = <String, dynamic>{'title': 'رياضيات الصف 12'};
    expect(matchesResourceSearch(resource, '\u2067رياضيات ١٢\u2069'), isTrue);
    expect(matchesResourceSearch(resource, 'رياضيات ۱۲'), isTrue);
    expect(matchesResourceSearch(resource, 'رياضيات ١١'), isFalse);
  });

  test('comma and semicolon keyword lists search only approved metadata', () {
    expect(matchesResourceSearch(approved, 'العلوم، الطاقة'), isTrue);
    expect(matchesResourceSearch(approved, 'ملزمة;الحياة'), isTrue);
    expect(matchesResourceSearch(approved, 'العلوم،should-not-be-searched'), isFalse);
  });

  test('contracted lam is indexed; missing metadata does not crash', () {
    final contractions = <String, dynamic>{
      'title': 'التدرب على الجمع',
      'subject': 'مقدمة للأعداد',
    };
    expect(matchesResourceSearch(contractions, 'الاعداد'), isTrue);
    expect(matchesResourceSearch(<String, dynamic>{}, 'الاعداد'), isFalse);
    expect(matchesResourceSearch(<String, dynamic>{}, ''), isTrue);
  });

  test('malformed nested metadata never exposes private URL tokens', () {
    final malformed = <String, dynamic>{
      'title': <String, dynamic>{
        'name': 'الطاقة',
        'url': 'https://example.org/private?token=secret-in-title',
      },
      'subject': <String>['العلوم', 'secret-in-subject'],
      'url': 'https://example.org/private?token=secret-in-url',
    };
    expect(matchesResourceSearch(malformed, 'secret-in-title'), isFalse);
    expect(matchesResourceSearch(malformed, 'secret-in-subject'), isFalse);
    expect(matchesResourceSearch(malformed, 'secret-in-url'), isFalse);
    expect(matchesResourceSearch(malformed, 'الطاقة'), isFalse);
    expect(matchesResourceSearch(malformed, 'العلوم'), isFalse);
    expect(matchesResourceSearch(malformed, ''), isTrue);
    expect(resourceText(malformed['title'], fallback: 'مادة تعليمية'),
        'مادة تعليمية');
    expect(resourceText(malformed['subject']), isEmpty);
    expect(resourceText(approved['title']), approved['title']);
  });
}
