import 'lesson_search.dart';

/// On-device search over public resource metadata only.
/// Do not index signed media URLs, file bytes, user identifiers or credentials.
bool matchesResourceSearch(Map<String, dynamic> resource, String query) {
  final words = normalizeLessonSearch(query)
      .split(' ')
      .where((word) => word.isNotEmpty);
  // Only published text fields may be indexed. Malformed metadata can contain
  // nested maps or lists with private URLs; never stringify those values.
  String publicText(String key) {
    final value = resource[key];
    return value is String ? value : '';
  }

  final searchable = normalizeLessonSearch([
    publicText('title'),
    publicText('subject'),
  ].join(' '));
  return words.every(searchable.contains);
}
