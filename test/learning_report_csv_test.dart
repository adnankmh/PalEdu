import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/learning_report.dart';
import 'package:paledu/data/learning_report_csv.dart';
import 'package:paledu/data/learning_report_snapshot.dart';

void main() {
  test('exports weighted local lesson statistics with CRLF rows', () {
    final snapshot = buildLearningReportSnapshot(const [
      LearningAttempt(lessonId: 'رياضيات', correctAnswers: 1, totalQuestions: 2),
      LearningAttempt(lessonId: 'رياضيات', correctAnswers: 2, totalQuestions: 3),
      LearningAttempt(lessonId: 'علوم', correctAnswers: 0, totalQuestions: 1),
    ]);
    expect(exportLearningReportCsv(snapshot),
        'lesson_id,attempts,correct_answers,total_questions,accuracy_percent\r\n'
        '"رياضيات",2,3,5,60.00\r\n'
        '"علوم",1,0,1,0.00\r\n');
  });

  test('quotes commas and embedded quotes without losing Arabic text', () {
    final snapshot = buildLearningReportSnapshot(const [
      LearningAttempt(lessonId: 'درس "أ", ب', correctAnswers: 1, totalQuestions: 1),
    ]);
    expect(exportLearningReportCsv(snapshot),
        contains('"درس ""أ"", ب",1,1,1,100.00'));
  });

  test('neutralizes spreadsheet formulas in lesson IDs', () {
    for (final id in ['=1+1', '+SUM(1,2)', '-2+3', '@cmd', '  =1+1']) {
      final snapshot = buildLearningReportSnapshot([
        LearningAttempt(lessonId: id, correctAnswers: 0, totalQuestions: 1),
      ]);
      expect(exportLearningReportCsv(snapshot), contains('"\'${id.trim()}"'));
    }
  });

  test('neutralizes formulas behind invisible Unicode formatting marks', () {
    for (final prefix in [
      '\u034F', // combining grapheme joiner
      '\u061C', // Arabic letter mark
      '\u180E', // Mongolian vowel separator
      '\u200B', // zero-width space
      '\u200E', // left-to-right mark
      '\u200F', // right-to-left mark
      '\u202E', // right-to-left override
      '\u2060', // word joiner
      '\u2066', // left-to-right isolate
      '\uFEFF', // byte-order mark
      '\u00A0', // non-breaking space
      '\t',
    ]) {
      for (final operator in ['=', '+', '-', '@']) {
        final id = '${prefix}${operator}SUM(1,2)';
        final snapshot = buildLearningReportSnapshot([
          LearningAttempt(lessonId: id, correctAnswers: 0, totalQuestions: 1),
        ]);
        final csv = exportLearningReportCsv(snapshot);
        expect(csv, contains('"\'${id.trim()}"'));
      }
    }
  });

  test('does not alter ordinary Unicode lesson identifiers', () {
    final snapshot = buildLearningReportSnapshot(const [
      LearningAttempt(
        lessonId: 'درس\u200F الرياضيات',
        correctAnswers: 1,
        totalQuestions: 1,
      ),
    ]);
    expect(exportLearningReportCsv(snapshot),
        contains('"درس\u200F الرياضيات",1,1,1,100.00'));
  });

  test('empty report exports headers only', () {
    final snapshot = buildLearningReportSnapshot(const <LearningAttempt>[]);
    expect(exportLearningReportCsv(snapshot).split('\r\n').length, 2);
    expect(exportLearningReportCsv(snapshot), isNot(contains('null')));
  });
}
