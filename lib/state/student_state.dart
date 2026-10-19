import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models.dart';
import '../data/review_schedule.dart';

class StudentState extends ChangeNotifier {
  StudentState(this.prefs)
      : name = prefs.getString('name') ?? '',
        grade = prefs.getInt('grade') ?? 1,
        track = prefs.getString('track') ?? 'عام',
        darkMode = prefs.getBool('darkMode') ?? false,
        scale = prefs.getDouble('scale') ?? 1,
        completed = (prefs.getStringList('completed') ?? []).toSet(),
        favourites = (prefs.getStringList('favourites') ?? []).toSet(),
        xp = prefs.getInt('xp') ?? 0 {
    try {
      final data = jsonDecode(prefs.getString('reviews_v1') ?? '{}');
      if (data is Map) {
        for (final entry in data.entries) {
          try {
            reviews[entry.key as String] = ReviewSchedule.fromJson(
                Map<String, dynamic>.from(entry.value as Map));
          } catch (_) { /* Ignore only corrupted entries. */ }
        }
      }
    } catch (_) { /* Invalid local data must not block app startup. */ }
  }

  final SharedPreferences prefs;
  String name;
  int grade;
  String track;
  bool darkMode;
  double scale;
  Set<String> completed;
  Set<String> favourites;
  int xp;
  final Map<String, ReviewSchedule> reviews = {};

  bool get configured => prefs.getBool('configured') ?? false;
  bool done(String id) => completed.contains(id);
  bool saved(String id) => favourites.contains(id);
  ReviewSchedule? reviewFor(String id) => reviews[id];
  bool reviewDue(String id, {DateTime? now}) =>
      reviews[id]?.isDue(now ?? DateTime.now()) ?? false;
  int dueCount(Iterable<String> ids, {DateTime? now}) =>
      ids.where((id) => reviewDue(id, now: now)).length;

  Future<void> configure(String nickname, int level, String branch) async {
    if (level < 1 || level > 12 || !LessonCatalog.tracksFor(level).contains(branch)) {
      throw ArgumentError('Invalid student grade or branch');
    }
    name = nickname.trim().isEmpty ? 'يا بطل' : nickname.trim();
    grade = level; track = branch;
    await prefs.setString('name', name);
    await prefs.setInt('grade', grade);
    await prefs.setString('track', track);
    await prefs.setBool('configured', true);
    notifyListeners();
  }

  Future<void> finish(String id, int score, int total) async {
    if (total <= 0 || score < 0 || score > total) {
      throw ArgumentError('Invalid score');
    }
    if (completed.add(id)) {
      xp += score * 10 + 10;
      await prefs.setStringList('completed', completed.toList()..sort());
      await prefs.setInt('xp', xp);
    }
    reviews[id] = ReviewSchedule.next(
      (score * 100 / total).round(), DateTime.now(), previous: reviews[id]);
    await prefs.setString('reviews_v1', jsonEncode(
      reviews.map((id, review) => MapEntry(id, review.toJson()))));
    notifyListeners();
  }

  Future<void> toggleSaved(String id) async {
    if (!favourites.add(id)) favourites.remove(id);
    await prefs.setStringList('favourites', favourites.toList()..sort());
    notifyListeners();
  }

  Future<void> appearance({bool? dark, double? textScale}) async {
    if (dark != null) {
      darkMode = dark;
      await prefs.setBool('darkMode', dark);
    }
    if (textScale != null) {
      scale = textScale.clamp(.9, 1.3);
      await prefs.setDouble('scale', scale);
    }
    notifyListeners();
  }

  Future<void> erase() async {
    for (final key in ['name','grade','track','darkMode','scale',
      'completed','favourites','xp','configured','reviews_v1']) {
      await prefs.remove(key);
    }
    name=''; grade=1; track='عام'; darkMode=false; scale=1;
    completed=<String>{}; favourites=<String>{}; xp=0; reviews.clear();
    notifyListeners();
  }
}
