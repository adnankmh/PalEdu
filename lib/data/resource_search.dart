import 'lesson_search.dart';

/// On-device search over public resource metadata only.
/// Do not index signed media URLs, file bytes, user identifiers or credentials.
bool matchesResourceSearch(Map<String, dynamic> resource, String query) {
  final words = normalizeLessonSearch(query)
      .split(' ')
      .where((word) => word.isNotEmpty);
  final searchable = normalizeLessonSearch([
    resource['title']?.toString() ?? '',
    resource['subject']?.toString() ?? '',
  ].join(' '));
  return words.every(searchable.contains);
}
