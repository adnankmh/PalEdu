import 'models.dart';

/// Normalizes Arabic spelling variants for local, offline lesson search.
/// This never sends a learner's search terms to a server.
String normalizeLessonSearch(String input) => input
    .toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
    .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Matches every query word, in any order, across the actual lesson fields.
bool matchesLessonSearch(Lesson lesson, String query) {
  final terms = normalizeLessonSearch(query)
      .split(' ')
      .where((term) => term.isNotEmpty);
  final searchable = normalizeLessonSearch([
    lesson.title,
    lesson.subject,
    lesson.summary,
    ...lesson.sections,
  ].join(' '));
  return terms.every(searchable.contains);
}
