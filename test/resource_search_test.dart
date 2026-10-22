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

  test('contracted lam is indexed; missing metadata does not crash', () {
    final contractions = <String, dynamic>{
      'title': 'التدرب على الجمع',
      'subject': 'مقدمة للأعداد',
    };
    expect(matchesResourceSearch(contractions, 'الاعداد'), isTrue);
    expect(matchesResourceSearch(<String, dynamic>{}, 'الاعداد'), isFalse);
    expect(matchesResourceSearch(<String, dynamic>{}, ''), isTrue);
  });
}
