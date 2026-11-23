import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/resource_search.dart';

void main() {
  test('only public scalar title and subject are indexed', () {
    final resource = <String, dynamic>{
      'title': 'ملزمة الهندسة',
      'subject': 'الرياضيات',
      'description': 'hidden-description-marker',
      'file_name': 'hidden-filename-marker',
      'signed_url': 'https://example.invalid/hidden-signed-marker',
      'owner_id': 'hidden-owner-marker',
      'metadata': <String, dynamic>{
        'title': 'hidden-nested-marker',
        'access_token': 'hidden-token-marker',
      },
    };

    expect(matchesResourceSearch(resource, 'الهندسة الرياضيات'), isTrue);
    for (final privateTerm in <String>[
      'hidden-description-marker',
      'hidden-filename-marker',
      'hidden-signed-marker',
      'hidden-owner-marker',
      'hidden-nested-marker',
      'hidden-token-marker',
    ]) {
      expect(matchesResourceSearch(resource, privateTerm), isFalse,
          reason: 'Only approved public scalar fields may be searchable');
    }
  });

  test('valid subject remains searchable if title is malformed', () {
    final resource = <String, dynamic>{
      'title': <String, dynamic>{'token': 'private-title-token'},
      'subject': 'الفيزياء',
    };
    expect(matchesResourceSearch(resource, 'الفيزياء'), isTrue);
    expect(matchesResourceSearch(resource, 'private-title-token'), isFalse);
    expect(resourceText(resource['title'], fallback: 'مورد تعليمي'),
        'مورد تعليمي');
  });

  test('valid title remains searchable if subject is malformed', () {
    final resource = <String, dynamic>{
      'title': 'مراجعة الكيمياء',
      'subject': <String>['private-subject-token'],
    };
    expect(matchesResourceSearch(resource, 'مراجعة الكيمياء'), isTrue);
    expect(matchesResourceSearch(resource, 'private-subject-token'), isFalse);
    expect(resourceText(resource['subject']), isEmpty);
  });
}
