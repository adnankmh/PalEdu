import 'learning_report_snapshot.dart';

/// Exports only aggregate lesson statistics, never learner identities or raw
/// attempts. The caller is responsible for obtaining consent before sharing.
String exportLearningReportCsv(LearningReportSnapshot snapshot) {
  final rows = <String>[
    'lesson_id,attempts,correct_answers,total_questions,accuracy_percent',
  ];
  for (final entry in snapshot.byLesson.entries) {
    final report = entry.value;
    final accuracy = report.accuracyPercent;
    rows.add([
      _safeCsvCell(entry.key),
      report.attempts.toString(),
      report.correctAnswers.toString(),
      report.totalQuestions.toString(),
      accuracy == null ? '' : accuracy.toStringAsFixed(2),
    ].join(','));
  }
  return '${rows.join('\r\n')}\r\n';
}

/// Quoting alone does not prevent spreadsheet formula execution. Prefix any
/// dangerous leading character (even after whitespace) with a literal quote.
String _safeCsvCell(String value) {
  final trimmed = value.trimLeft();
  final dangerous = trimmed.isNotEmpty &&
      ('=+-@'.contains(trimmed[0]) || trimmed[0] == '\t' || trimmed[0] == '\r');
  final escaped = (dangerous ? "'$value" : value).replaceAll('"', '""');
  return '"$escaped"';
}
