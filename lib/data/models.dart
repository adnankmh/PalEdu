import 'dart:convert';

class QuizQuestion {
  const QuizQuestion({required this.prompt, required this.options,
    required this.correct, required this.explanation});
  final String prompt;
  final List<String> options;
  final int correct;
  final String explanation;

  factory QuizQuestion.fromJson(Map<String, dynamic> data) {
    final options = List<String>.from(data['options'] as List);
    final answer = data['answer'] as int;
    if (options.length < 2 || answer < 0 || answer >= options.length) {
      throw const FormatException('Invalid answer index');
    }
    return QuizQuestion(
      prompt: data['prompt'] as String,
      options: options,
      correct: answer,
      explanation: data['explanation'] as String,
    );
  }
}

class Lesson {
  const Lesson({required this.id, required this.grade, required this.track,
    required this.subject, required this.title, required this.summary,
    required this.sections, required this.questions, required this.duration});
  final String id;
  final int grade;
  final String track;
  final String subject;
  final String title;
  final String summary;
  final List<String> sections;
  final List<QuizQuestion> questions;
  final int duration;

  factory Lesson.fromJson(Map<String, dynamic> data) => Lesson(
    id: data['id'] as String, grade: data['grade'] as int,
    track: data['track'] as String? ?? 'عام',
    subject: data['subject'] as String,
    title: data['title'] as String, summary: data['summary'] as String,
    sections: List<String>.from(data['sections'] as List),
    questions: (data['questions'] as List)
      .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
      .toList(growable: false),
    duration: data['duration'] as int? ?? 7,
  );
}

class LessonCatalog {
  const LessonCatalog(this.lessons);
  final List<Lesson> lessons;

  factory LessonCatalog.parse(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['contentStatus'] != 'demonstration_only') {
      throw const FormatException('Unverified curriculum status');
    }
    final lessons = (data['lessons'] as List)
      .map((v) => Lesson.fromJson(Map<String, dynamic>.from(v as Map)))
      .toList(growable: false);
    if (lessons.map((l) => l.id).toSet().length != lessons.length) {
      throw const FormatException('Duplicate lesson id');
    }
    return LessonCatalog(lessons);
  }

  List<Lesson> forStudent(int grade, String branch) => lessons
    .where((l) => l.grade == grade && (l.track == 'عام' || l.track == branch))
    .toList(growable: false);

  static const tracks = <String>['علمي', 'أدبي', 'ريادة وأعمال',
    'شرعي', 'صناعي', 'زراعي', 'فندقي'];
  static List<String> tracksFor(int grade) =>
      grade < 11 ? <String>['عام'] : tracks;
  static String gradeName(int grade) => grade == 12
      ? 'الثاني عشر - التوجيهي'
      : grade == 11 ? 'الحادي عشر' : 'الصف $grade';
}
