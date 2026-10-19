import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/review_schedule.dart';

void main() {
  final start = DateTime(2026, 10, 19);
  test('weak results schedule the next-day review', () {
    final review = ReviewSchedule.next(45, start);
    expect(review.dueDate, '2026-10-20');
    expect(review.successStreak, 0);
    expect(review.isDue(DateTime(2026, 10, 20)), isTrue);
  });
  test('strong results gradually extend intervals', () {
    final first = ReviewSchedule.next(91, start);
    final second = ReviewSchedule.next(95, start, previous: first);
    expect(first.dueDate, '2026-10-20');
    expect(second.dueDate, '2026-10-22');
    expect(second.successStreak, 2);
  });
  test('rejects corrupted local review data', () {
    expect(() => ReviewSchedule.fromJson({
      'dueDate': 'not-a-date', 'successStreak': 2, 'lastScore': 90,
    }), throwsFormatException);
  });
}
