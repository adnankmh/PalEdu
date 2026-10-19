/// Local, deterministic practice review intervals. Not a diagnosis of mastery.
class ReviewSchedule {
  const ReviewSchedule({
    required this.dueDate,
    required this.successStreak,
    required this.lastScore,
  });

  final String dueDate;
  final int successStreak;
  final int lastScore;

  static String dayKey(DateTime date) =>
      date.year.toString().padLeft(4, '0') + '-' +
      date.month.toString().padLeft(2, '0') + '-' +
      date.day.toString().padLeft(2, '0');

  static String afterDays(DateTime now, int days) => dayKey(
      DateTime.utc(now.year, now.month, now.day).add(Duration(days: days)));

  bool isDue(DateTime now) => dueDate.compareTo(dayKey(now)) <= 0;

  static ReviewSchedule next(int score, DateTime now,
      {ReviewSchedule? previous}) {
    final bounded = score.clamp(0, 100).toInt();
    if (bounded < 60) {
      return ReviewSchedule(dueDate: afterDays(now, 1),
        successStreak: 0, lastScore: bounded);
    }
    if (bounded < 80) {
      return ReviewSchedule(dueDate: afterDays(now, 2),
        successStreak: 0, lastScore: bounded);
    }
    final streak = ((previous?.successStreak ?? 0) + 1).clamp(1, 6).toInt();
    const intervals = <int>[1, 3, 7, 14, 30, 60];
    return ReviewSchedule(dueDate: afterDays(now, intervals[streak - 1]),
      successStreak: streak, lastScore: bounded);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'dueDate': dueDate,
    'successStreak': successStreak,
    'lastScore': lastScore,
  };

  factory ReviewSchedule.fromJson(Map<String, dynamic> json) {
    final date = json['dueDate'];
    final streak = json['successStreak'];
    final score = json['lastScore'];
    if (date is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
        streak is! int || streak < 0 || streak > 6 ||
        score is! int || score < 0 || score > 100) {
      throw const FormatException('Invalid local review schedule');
    }
    final parsed = DateTime.tryParse(date);
    if (parsed == null || dayKey(parsed) != date) {
      throw const FormatException('Invalid review calendar day');
    }
    return ReviewSchedule(dueDate: date, successStreak: streak,
      lastScore: score);
  }
}
