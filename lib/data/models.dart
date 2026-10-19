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
    final prompt = data['prompt'] as String;
    final explanation = data['explanation'] as String;
    if (options.length < 2 || answer < 0 || answer >= options.length ||
        prompt.trim().isEmpty || explanation.trim().isEmpty ||
        options.any((option) => option.trim().isEmpty) ||
        options.toSet().length != options.length) {
      throw const FormatException('Invalid quiz question');
    }
    return QuizQuestion(
      prompt: prompt,
      options: options,
      correct: answer,
      explanation: explanation,
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

  factory Lesson.fromJson(Map<String, dynamic> data) {
    final id = data['id'] as String;
    final grade = data['grade'] as int;
    final track = data['track'] as String? ?? 'عام';
    final subject = data['subject'] as String;
    final title = data['title'] as String;
    final summary = data['summary'] as String;
    final duration = data['duration'] as int? ?? 7;
    final sections = List<String>.from(data['sections'] as List);
    final questions = (data['questions'] as List)
        .map((q) => QuizQuestion.fromJson(
            Map<String, dynamic>.from(q as Map)))
        .toList(growable: false);
    final allowedTracks = grade <= 10
        ? const <String>['عام']
        : <String>['عام', ...LessonCatalog.tracks];
    if (grade < 1 || grade > 12 || !allowedTracks.contains(track) ||
        id.trim().isEmpty || subject.trim().isEmpty ||
        title.trim().isEmpty || summary.trim().isEmpty ||
        duration < 1 || duration > 240 ||
        sections.isEmpty || sections.any((section) => section.trim().isEmpty) ||
        questions.isEmpty ||
        questions.map((q) => q.options[q.correct]).toSet().length !=
            questions.length) {
      throw const FormatException('Invalid lesson content');
    }
    return Lesson(
      id: id, grade: grade, track: track, subject: subject,
      title: title, summary: summary, sections: sections,
      questions: questions, duration: duration,
    );
  }
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
