import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models.dart';
import '../data/reading_shelf.dart';
import '../data/review_schedule.dart';
import '../data/mistake_notebook.dart';

class StudentState extends ChangeNotifier {
  StudentState(this.prefs)
      : name = prefs.getString('name') ?? '',
        grade = prefs.getInt('grade') ?? 1,
        track = prefs.getString('track') ?? 'عام',
        darkMode = prefs.getBool('darkMode') ?? false,
        animationsEnabled = prefs.getBool('animationsEnabled') ?? true,
        scale = prefs.getDouble('scale') ?? 1,
        completed = (prefs.getStringList('completed') ?? []).toSet(),
        favourites = (prefs.getStringList('favourites') ?? []).toSet(),
        xp = prefs.getInt('xp') ?? 0 {
    mistakes=MistakeNotebook(prefs);
    practiceDays.addAll(_readDailyCount(prefs.getString('practice_days_v1')));
    firstCompletionDays.addAll(_readDailyCount(
      prefs.getString('lesson_first_days_v1')));
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
    try {
      final raw=jsonDecode(prefs.getString('lesson_notes_v1')??'{}');
      if(raw is Map) {
        for(final entry in raw.entries){
          if(entry.key is String && entry.value is String) {
            notes[entry.key as String]=(entry.value as String);
          }
        }
      }
    } catch (_) { /* Do not let malformed local notes crash startup. */ }
  }

  final SharedPreferences prefs;
  late final MistakeNotebook mistakes;
  String name;
  int grade;
  String track;
  bool darkMode;
  bool animationsEnabled;
  double scale;
  Set<String> completed;
  Set<String> favourites;
  int xp;
  final Map<String, ReviewSchedule> reviews = {};
  final Map<String,String> notes = {};
  // Counts only, held on the device and erased with the local profile.
  final Map<String,int> practiceDays = {};
  final Map<String,int> firstCompletionDays = {};

  static Map<String,int> _readDailyCount(String? raw) {
    if(raw==null)return {};
    try {
      final input=jsonDecode(raw);
      if(input is! Map)return {};
      final result=<String,int>{};
      for(final pair in input.entries){
        if(pair.key is! String||pair.value is! int)continue;
        final key=pair.key as String, count=pair.value as int;
        final date=DateTime.tryParse(key);
        if(date==null||ReviewSchedule.dayKey(date)!=key ||
          count<1||count>999)continue;
        result[key]=count;
      }
      return result;
    } catch (_){ return {}; }
  }

  Future<void> _saveActivity() async {
    void limit(Map<String,int> values) {
      final sorted=values.keys.toList()..sort();
      final removeCount=(sorted.length-180).clamp(0,sorted.length);
      for(final key in sorted.take(removeCount)){values.remove(key);}
    }
    limit(practiceDays);
    limit(firstCompletionDays);
    await prefs.setString('practice_days_v1',jsonEncode(practiceDays));
    await prefs.setString('lesson_first_days_v1',
      jsonEncode(firstCompletionDays));
  }

  bool get configured => prefs.getBool('configured') ?? false;
  bool done(String id) => completed.contains(id);
  bool saved(String id) => favourites.contains(id);
  String noteFor(String lessonId) => notes[lessonId]??'';
  Future<void> saveLessonNote(String lessonId,String note) async {
    if(lessonId.trim().isEmpty || note.length>2000) {
      throw ArgumentError('Invalid note');
    }
    final value=note.trim();
    if(value.isEmpty) { notes.remove(lessonId); }
    else { notes[lessonId]=value; }
    await prefs.setString('lesson_notes_v1',jsonEncode(notes));
    notifyListeners();
  }
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

  Future<void> finish(String id, int score, int total,{DateTime? now}) async {
    if (total <= 0 || score < 0 || score > total) {
      throw ArgumentError('Invalid score');
    }
    final timestamp=now??DateTime.now();
    final day=ReviewSchedule.dayKey(timestamp);
    practiceDays[day]=((practiceDays[day]??0)+1).clamp(1,999);
    if (completed.add(id)) {
      firstCompletionDays[day]=
        ((firstCompletionDays[day]??0)+1).clamp(1,999);
      xp += score * 10 + 10;
      await prefs.setStringList('completed', completed.toList()..sort());
      await prefs.setInt('xp', xp);
    }
    reviews[id] = ReviewSchedule.next(
      (score * 100 / total).round(), timestamp, previous: reviews[id]);
    await prefs.setString('reviews_v1', jsonEncode(
      reviews.map((id, review) => MapEntry(id, review.toJson()))));
    await _saveActivity();
    notifyListeners();
  }

  /// Saves wrong-question fingerprints after each completed full lesson quiz.
  /// Never serializes answer text or personal identifying information.
  Future<void> recordQuizAnswers(Lesson lesson,Map<int,bool> answers) async {
    await mistakes.record(lesson,answers);
    notifyListeners();
  }

  Future<void> resolveWrongAnswer(Lesson lesson,int index) async {
    await mistakes.resolve(lesson,index);
    notifyListeners();
  }

  Future<void> toggleSaved(String id) async {
    if (!favourites.add(id)) favourites.remove(id);
    await prefs.setStringList('favourites', favourites.toList()..sort());
    notifyListeners();
  }

  Future<void> appearance({bool? dark, bool? motion, double? textScale}) async {
    if (dark != null) {
      darkMode = dark;
      await prefs.setBool('darkMode', dark);
    }
    if (motion != null) {
      animationsEnabled = motion;
      await prefs.setBool('animationsEnabled', motion);
    }
    if (textScale != null) {
      scale = textScale.clamp(.9, 1.3);
      await prefs.setDouble('scale', scale);
    }
    notifyListeners();
  }

  Future<void> erase() async {
    for (final key in ['name','grade','track','darkMode','scale',
      'completed','favourites','xp','configured','reviews_v1','lesson_notes_v1',
      'animationsEnabled','practice_days_v1','lesson_first_days_v1']) {
      await prefs.remove(key);
    }
    await ReadingShelf(prefs).clear();
    await mistakes.clear();
    // Legacy per-book metadata is deleted alongside the new reading shelf.
    for(final key in prefs.getKeys().where((v)=>
      v.startsWith('paledu_pdf_page_')||
      v.startsWith('paledu_pdf_bookmark_')||
      v.startsWith('paledu_video_pos_')).toList()){
      await prefs.remove(key);
    }
    name=''; grade=1; track='عام'; darkMode=false; animationsEnabled=true; scale=1;
    completed=<String>{}; favourites=<String>{}; xp=0; reviews.clear(); notes.clear(); practiceDays.clear();
    firstCompletionDays.clear();
    notifyListeners();
  }
}
