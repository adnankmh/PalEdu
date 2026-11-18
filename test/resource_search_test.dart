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
  test('valid title remains searchable when subject is malformed', () {
    final resource = <String, dynamic>{
      'title': 'دليل الرياضيات للصف ١٢',
      'subject': <String, dynamic>{
        'private': 'https://example.org/signed?token=hidden-subject',
      },
    };
    expect(matchesResourceSearch(resource, 'رياضيات 12'), isTrue);
    expect(matchesResourceSearch(resource, 'hidden-subject'), isFalse);
    expect(matchesResourceSearch(resource, 'رياضيات hidden-subject'), isFalse);
    expect(resourceText(resource['subject']), isEmpty);
  });

  test('valid subject remains searchable when title is malformed', () {
    final resource = <String, dynamic>{
      'title': <String>['hidden-title', 'https://example.org/private'],
      'subject': 'اللغة العربية',
    };
    expect(matchesResourceSearch(resource, 'اللغه العربيه'), isTrue);
    expect(matchesResourceSearch(resource, 'hidden-title'), isFalse);
    expect(matchesResourceSearch(resource, 'العربية hidden-title'), isFalse);
    expect(resourceText(resource['title'], fallback: 'مادة تعليمية'),
        'مادة تعليمية');
  });

  test('resource type and unrelated metadata cannot influence search', () {
    for (final type in <String>['book', 'worksheet', 'video']) {
      final resource = <String, dynamic>{
        'type': type,
        'title': 'مراجعة الكسور',
        'subject': 'الرياضيات',
        'description': 'private-description-marker',
        'storage_path': 'private-storage-marker',
        'signed_url': 'https://example.org/?token=private-token-marker',
      };
      expect(matchesResourceSearch(resource, 'الكسور الرياضيات'), isTrue);
      expect(matchesResourceSearch(resource, 'private-description-marker'), isFalse);
      expect(matchesResourceSearch(resource, 'private-storage-marker'), isFalse);
      expect(matchesResourceSearch(resource, 'private-token-marker'), isFalse);
      expect(matchesResourceSearch(resource, 'الكسور private-token-marker'), isFalse);
    }
  });

  test('malformed objects are never stringified while indexing', () {
    final resource = <String, dynamic>{
      'title': _ThrowingPrivateMetadata(),
      'subject': 'العلوم والحياة',
    };
    expect(matchesResourceSearch(resource, 'العلوم'), isTrue);
    expect(matchesResourceSearch(resource, 'private-object-token'), isFalse);
    expect(resourceText(resource['title'], fallback: 'مادة تعليمية'),
        'مادة تعليمية');
  });

  test('malformed subject objects cannot be stringified or indexed', () {
    final resource = <String, dynamic>{
      'title': 'دليل العلوم للصف التاسع',
      'subject': _ThrowingPrivateMetadata(),
      'url': 'https://example.org/private?token=hidden-media-token',
    };
    expect(matchesResourceSearch(resource, 'العلوم التاسع'), isTrue);
    expect(matchesResourceSearch(resource, 'private-object-token'), isFalse);
    expect(matchesResourceSearch(resource, 'hidden-media-token'), isFalse);
    expect(resourceText(resource['subject'], fallback: 'مبحث غير معروف'),
        'مبحث غير معروف');
  });

  test('non-string scalar metadata cannot leak into resource search', () {
    for (final invalid in <Object?>[null, 12, false, true, 3.14]) {
      final resource = <String, dynamic>{
        'title': invalid,
        'subject': 'الرياضيات',
        'signed_url': 'https://example.org/?token=hidden-token',
      };
      expect(matchesResourceSearch(resource, 'الرياضيات'), isTrue);
      expect(matchesResourceSearch(resource, '12'), isFalse);
      expect(matchesResourceSearch(resource, 'true'), isFalse);
      expect(matchesResourceSearch(resource, 'hidden-token'), isFalse);
      expect(resourceText(invalid, fallback: 'مادة تعليمية'), 'مادة تعليمية');
    }
  });

}

class _ThrowingPrivateMetadata {
  @override
  String toString() => throw StateError('private-object-token must not be read');
}
