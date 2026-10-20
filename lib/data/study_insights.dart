import '../state/student_state.dart';
import 'models.dart';
import 'review_schedule.dart';

/// Derived dashboard statistics based on device-persisted quiz activity.
class StudyDay {
  const StudyDay(this.date,this.attempts,this.firstCompletions);
  final String date;
  final int attempts,firstCompletions;
}

class LearningBadge {
  const LearningBadge(this.id,this.title,this.description,this.earned);
  final String id,title,description;
  final bool earned;
}

class StudyInsights {
  factory StudyInsights({
    required StudentState student,
    required Iterable<Lesson> lessons,
    DateTime? now,
  }) => StudyInsights._calculate(student,lessons,now??DateTime.now());

  static StudyInsights _calculate(StudentState student,
      Iterable<Lesson> lessons,DateTime now) {
    final available=lessons.toList(growable:false);
    final ids=available.map((e)=>e.id).toSet();
    final completedIds=student.completed.intersection(ids);
    final strongScores=available.where((l)=>
      (student.reviews[l.id]?.lastScore??0)>=80).length;
    final coveredSubjects=available.where((l)=>completedIds.contains(l.id))
      .map((l)=>l.subject).toSet();
    final week=List<StudyDay>.generate(7,(i){
      final date=DateTime.utc(now.year,now.month,now.day)
        .subtract(Duration(days:6-i));
      final key=ReviewSchedule.dayKey(date);
      return StudyDay(key,student.practiceDays[key]??0,
        student.firstCompletionDays[key]??0);
    });
    var cursor=DateTime.utc(now.year,now.month,now.day);
    if((student.practiceDays[ReviewSchedule.dayKey(cursor)]??0)==0){
      cursor=cursor.subtract(const Duration(days:1));
    }
    var streak=0;
    while(streak<365&&(student.practiceDays[
        ReviewSchedule.dayKey(cursor)]??0)>0) {
      streak++;
      cursor=cursor.subtract(const Duration(days:1));
    }
    final count=completedIds.length;
    final badges=[
      LearningBadge('first','البداية المشرقة','إنهاء اختبار درس واحد',count>=1),
      LearningBadge('explorer','مستكشف المعرفة','إنهاء 3 دروس',count>=3),
      LearningBadge('focus','قوة الاستمرار','إنهاء 10 دروس',count>=10),
      LearningBadge('streak3','مواظب','التدرّب 3 أيام متتالية',streak>=3),
      LearningBadge('streak7','نجم الأسبوع','التدرّب 7 أيام متتالية',streak>=7),
      LearningBadge('mastery','إجابات متقنة',
        'تحقيق 80٪ أو أكثر في 3 دروس',strongScores>=3),
      LearningBadge('variety','متعدد المعارف',
        'إنهاء دروس في 3 مباحث مختلفة',coveredSubjects.length>=3),
      LearningBadge('review5','صديق المراجعة',
        'بدء مراجعة 5 دروس',
        available.where((l)=>student.reviewFor(l.id)!=null).length>=5),
    ];
    return StudyInsights._internal(
      completed:count,total:ids.length,excellentLessons:strongScores,
      streakDays:streak,todayAttempts:student.practiceDays[
        ReviewSchedule.dayKey(now)]??0,
      lastSevenDays:week,badges:badges,
      dueReviews:student.dueCount(ids,now:now));
  }

  const StudyInsights._internal({
    required this.completed,required this.total,required this.excellentLessons,
    required this.streakDays,required this.todayAttempts,
    required this.lastSevenDays,required this.badges,required this.dueReviews,
  });

  final int completed,total,excellentLessons,streakDays,todayAttempts,dueReviews;
  final List<StudyDay> lastSevenDays;
  final List<LearningBadge> badges;
  static const dailyGoal=2;

  int get earnedBadges=>badges.where((b)=>b.earned).length;
  int get weeklyAttempts=>lastSevenDays.fold(0,(n,d)=>n+d.attempts);
  double get goalProgress=>(todayAttempts/dailyGoal).clamp(0.0,1.0);
  double get completionRate=>total==0?0:completed/total;
}
