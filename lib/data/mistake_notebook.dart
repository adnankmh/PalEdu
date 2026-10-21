import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Local-only missed-question fingerprints. No answers, names, or question
/// text are stored. A changed curriculum question invalidates its fingerprint.
class MistakeNotebook {
  MistakeNotebook(this.prefs) {
    final raw=prefs.getString(storageKey);
    if(raw==null)return;
    try {
      final decoded=jsonDecode(raw);
      if(decoded is! Map)return;
      for(final pair in decoded.entries){
        if(pair.key is! String || pair.value is! List)continue;
        final lessonId=pair.key as String;
        if(lessonId.isEmpty||lessonId.length>160)continue;
        final fingerprints=<String>{};
        for(final value in pair.value as List){
          if(value is String && RegExp(r'^[a-f0-9]{24}$').hasMatch(value)){
            fingerprints.add(value);
          }
          if(fingerprints.length>=maxPerLesson)break;
        }
        if(fingerprints.isNotEmpty)_entries[lessonId]=fingerprints;
        if(_entries.length>=maxLessons)break;
      }
    }catch(_){/* A corrupted local cache must not prevent logging in. */}
  }
  final SharedPreferences prefs;
  final Map<String,Set<String>> _entries={};
  static const storageKey='mistake_fingerprints_v1';
  static const maxPerLesson=80;
  static const maxLessons=120;

  static String fingerprint(Lesson lesson,int index){
    if(index<0||index>=lesson.questions.length) {
      throw RangeError.index(index,lesson.questions,'index');
    }
    final question=lesson.questions[index];
    final parts=[lesson.id,question.prompt,...question.options,
      question.correct.toString(),question.explanation];
    return sha256.convert(utf8.encode(parts.join('\u0000')))
      .toString().substring(0,24);
  }

  bool contains(Lesson lesson,int index)=>
    _entries[lesson.id]?.contains(fingerprint(lesson,index))??false;
  int get total=>_entries.values.fold(0,(n,set)=>n+set.length);

  int countFor(Lesson lesson){
    var count=0;
    for(var i=0;i<lesson.questions.length;i++){
      if(contains(lesson,i))count++;
    }
    return count;
  }

  /// Update only questions actually answered in this quiz attempt.
  /// Correct answers resolve their corresponding previous mistakes.
  Future<void> record(Lesson lesson,Map<int,bool> answers) async {
    if(lesson.id.isEmpty||lesson.id.length>160)return;
    final values={...?_entries[lesson.id]};
    for(final answer in answers.entries){
      if(answer.key<0||answer.key>=lesson.questions.length)continue;
      final key=fingerprint(lesson,answer.key);
      if(answer.value){values.remove(key);}
      else if(values.length<maxPerLesson){values.add(key);}
    }
    if(values.isEmpty){_entries.remove(lesson.id);}
    else if(_entries.containsKey(lesson.id)||_entries.length<maxLessons){
      _entries[lesson.id]=values;
    }
    await _save();
  }

  Future<void> resolve(Lesson lesson,int index) async {
    final values=_entries[lesson.id];
    if(values==null)return;
    values.remove(fingerprint(lesson,index));
    if(values.isEmpty)_entries.remove(lesson.id);
    await _save();
  }

  Future<void> clear() async {
    _entries.clear();
    await prefs.remove(storageKey);
  }

  Future<void> _save() async {
    if(_entries.isEmpty){await prefs.remove(storageKey);return;}
    await prefs.setString(storageKey,jsonEncode(_entries.map(
      (lesson,keys)=>MapEntry(lesson,keys.toList()..sort()))));
  }
}
