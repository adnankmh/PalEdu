import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/models.dart';
import 'package:paledu/data/review_queue.dart';
import 'package:paledu/data/review_schedule.dart';

const question = QuizQuestion(
  prompt: 'سؤال تجريبي',
  options: ['صحيح', 'خطأ'],
  correct: 0,
  explanation: 'شرح',
);

Lesson lesson(String id, {bool hasQuiz = true}) => Lesson(
  id: id,
  grade: 12,
  track: 'علمي',
  subject: 'الرياضيات',
  title: 'درس $id',
  summary: 'تجريبي',
  sections: const ['شرح'],
  questions: hasQuiz ? const [question] : const [],
  duration: 7,
);

ReviewSchedule review(String date, int score) => ReviewSchedule(
  dueDate: date, successStreak: 0, lastScore: score,
);

void main() {
  final today = DateTime(2026, 10, 20, 22, 15);

  test('overdue first, then earliest deadline and weaker result', () {
    final queue = ReviewQueue.plan(
      lessons: [lesson('future'), lesson('weak'), lesson('old'), lesson('strong')],
      reviews: {
        'future': review('2026-10-23', 50),
        'weak': review('2026-10-20', 30),
        'old': review('2026-10-18', 90),
        'strong': review('2026-10-20', 85),
      },
      now: today,
    );
    expect(queue.due.map((e) => e.lesson.id),
        orderedEquals(['old', 'weak', 'strong']));
    expect(queue.due.first.daysUntilDue, -2);
    expect(queue.due[1].daysUntilDue, 0);
    expect(queue.upcoming.single.lesson.id, 'future');
    expect(queue.upcoming.single.daysUntilDue, 3);
  });

  test('does not invent reviews, duplicate lessons or quiz-less actions', () {
    final queue = ReviewQueue.plan(
      lessons: [
        lesson('valid'),
        lesson('valid'),
        lesson('no-quiz', hasQuiz: false),
        lesson('never-attempted'),
      ],
      reviews: {
        'valid': review('2026-10-20', 72),
        'no-quiz': review('2026-10-20', 40),
        'missing-from-catalog': review('2026-10-19', 20),
      },
      now: today,
    );
    expect(queue.due.map((e) => e.lesson.id), ['valid']);
    expect(queue.upcoming, isEmpty);
  });

  test('calendar-day comparison is stable near midnight', () {
    final queue = ReviewQueue.plan(
      lessons: [lesson('due')],
      reviews: {'due': review('2026-10-21', 60)},
      now: DateTime(2026, 10, 20, 23, 59),
    );
    expect(queue.due, isEmpty);
    expect(queue.upcoming.single.daysUntilDue, 1);
  });

  test('returns empty queues for a new student', () {
    final queue = ReviewQueue.plan(
      lessons: [lesson('first')],
      reviews: const {},
      now: today,
    );
    expect(queue.due, isEmpty);
    expect(queue.upcoming, isEmpty);
  });
}
