import 'lesson_search.dart';

/// Use published scalar text in both the index and the resource display.
String resourceText(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

/// On-device search over public resource metadata only.
/// Do not index signed media URLs, file bytes, user identifiers or credentials.
bool matchesResourceSearch(Map<String, dynamic> resource, String query) {
  final words = normalizeLessonSearch(query)
      .split(' ')
      .where((word) => word.isNotEmpty);
  // Only published text fields may be indexed. Malformed metadata can contain
  // nested maps or lists with private URLs; never stringify those values.
  final searchable = normalizeLessonSearch([
    resourceText(resource['title']),
    resourceText(resource['subject']),
  ].join(' '));
  return words.every(searchable.contains);
}
