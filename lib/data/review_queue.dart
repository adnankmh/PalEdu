import 'models.dart';
import 'review_schedule.dart';

/// A deterministic, offline review queue built only from saved quiz results.
/// Due lessons come first, with older deadlines and weaker scores prioritised.
class ReviewQueueItem {
  const ReviewQueueItem({
    required this.lesson,
    required this.dueDate,
    required this.lastScore,
    required this.daysUntilDue,
  });

  final Lesson lesson;
  final String dueDate;
  final int lastScore;
  /// Negative values indicate overdue reviews; zero means due today.
  final int daysUntilDue;
  bool get isDue => daysUntilDue <= 0;
}

class ReviewQueue {
  const ReviewQueue._(this.due, this.upcoming);

  final List<ReviewQueueItem> due;
  final List<ReviewQueueItem> upcoming;

  static ReviewQueue plan({
    required Iterable<Lesson> lessons,
    required Map<String, ReviewSchedule> reviews,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final midnight = DateTime.utc(today.year, today.month, today.day);
    final seen = <String>{};
    final due = <ReviewQueueItem>[];
    final upcoming = <ReviewQueueItem>[];
    for (final lesson in lessons) {
      // A lesson without an actionable quiz cannot be scheduled for practice.
      if (!seen.add(lesson.id) || lesson.questions.isEmpty) continue;
      final schedule = reviews[lesson.id];
      if (schedule == null) continue;
      final deadline = DateTime.tryParse(schedule.dueDate);
      if (deadline == null ||
          ReviewSchedule.dayKey(deadline) != schedule.dueDate) continue;
      final remaining = deadline.difference(midnight).inDays;
      final item = ReviewQueueItem(
        lesson: lesson,
        dueDate: schedule.dueDate,
        lastScore: schedule.lastScore,
        daysUntilDue: remaining,
      );
      (item.isDue ? due : upcoming).add(item);
    }
    int compare(ReviewQueueItem a, ReviewQueueItem b) {
      final deadline = a.dueDate.compareTo(b.dueDate);
      if (deadline != 0) return deadline;
      final score = a.lastScore.compareTo(b.lastScore);
      if (score != 0) return score;
      return a.lesson.id.compareTo(b.lesson.id);
    }
    due.sort(compare);
    upcoming.sort(compare);
    return ReviewQueue._(
      List<ReviewQueueItem>.unmodifiable(due),
      List<ReviewQueueItem>.unmodifiable(upcoming),
    );
  }
}
