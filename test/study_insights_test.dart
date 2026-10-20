import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/data/models.dart';
import 'package:paledu/data/study_insights.dart';
import 'package:paledu/state/student_state.dart';
import 'package:paledu/ui/design.dart';
import 'package:paledu/ui/royal_achievements.dart';

const lessons=[
  Lesson(id:'l1',grade:12,track:'علمي',subject:'الرياضيات',
    title:'التفاضل',summary:'درس',sections:['شرح'],questions:[],duration:7),
  Lesson(id:'l2',grade:12,track:'علمي',subject:'الفيزياء',
    title:'القوة',summary:'درس',sections:['شرح'],questions:[],duration:7),
  Lesson(id:'l3',grade:12,track:'علمي',subject:'الكيمياء',
    title:'العناصر',summary:'درس',sections:['شرح'],questions:[],duration:7),
];

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();

  test('daily practice increases per attempt; XP only on first finish',() async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final student=StudentState(prefs);
    final today=DateTime(2026,10,20);
    await student.finish('l1',3,4,now:today);
    final originalXp=student.xp;
    await student.finish('l1',4,4,now:today);
    expect(student.xp,originalXp);
    final insights=StudyInsights(student:student,lessons:lessons,now:today);
    expect(insights.todayAttempts,2);
    expect(insights.completed,1);
    expect(insights.goalProgress,1);
    expect(student.firstCompletionDays['2026-10-20'],1);
    final restored=StudentState(prefs);
    expect(restored.practiceDays['2026-10-20'],2);
  });

  test('streak permits yesterday if today had no activity',() async {
    SharedPreferences.setMockInitialValues({});
    final student=StudentState(await SharedPreferences.getInstance());
    await student.finish('l1',4,4,now:DateTime(2026,10,15));
    await student.finish('l2',4,4,now:DateTime(2026,10,16));
    await student.finish('l3',4,4,now:DateTime(2026,10,17));
    final yesterday=StudyInsights(student:student,lessons:lessons,
      now:DateTime(2026,10,18));
    expect(yesterday.streakDays,3);
    expect(yesterday.badges.firstWhere((b)=>b.id=='streak3').earned,isTrue);
    final broken=StudyInsights(student:student,lessons:lessons,
      now:DateTime(2026,10,20));
    expect(broken.streakDays,0);
  });

  test('badges use real lesson subjects and quiz scores',() async {
    SharedPreferences.setMockInitialValues({});
    final student=StudentState(await SharedPreferences.getInstance());
    await student.finish('l1',5,5,now:DateTime(2026,10,20));
    await student.finish('l2',5,5,now:DateTime(2026,10,20));
    await student.finish('l3',5,5,now:DateTime(2026,10,20));
    final stats=StudyInsights(student:student,lessons:lessons,
      now:DateTime(2026,10,20));
    expect(stats.earnedBadges,greaterThanOrEqualTo(3));
    expect(stats.badges.firstWhere((b)=>b.id=='mastery').earned,isTrue);
    expect(stats.badges.firstWhere((b)=>b.id=='variety').earned,isTrue);
    expect(stats.total,3);
  });

  test('corrupt date counters ignored; delete local history',() async {
    SharedPreferences.setMockInitialValues({
      'practice_days_v1':'{"bad":12,"2026-10-20":2,"2026-02-99":3,"2026-10-18":-2}',
    });
    final prefs=await SharedPreferences.getInstance();
    final student=StudentState(prefs);
    expect(student.practiceDays.keys,toListEquals(['2026-10-20']));
    await student.erase();
    expect(prefs.containsKey('practice_days_v1'),isFalse);
    expect(StudentState(prefs).practiceDays,isEmpty);
  });

  testWidgets('achievement screen renders on a narrow mobile device',
      (tester) async {
    tester.view.physicalSize=const Size(320,690);
    tester.view.devicePixelRatio=1;
    addTearDown((){
      tester.view.resetPhysicalSize();tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues({'animationsEnabled':false});
    final student=StudentState(await SharedPreferences.getInstance());
    await tester.pumpWidget(MaterialApp(
      theme:palTheme(false),
      home:Directionality(
        textDirection:TextDirection.rtl,
        child:RoyalAchievementsScreen(
          student:student,lessons:lessons,
          onPractice:(){},onSubjects:(){}),
      )));
    expect(find.text('إنجازاتي التعليمية'),findsOneWidget);
    expect(find.text('هدفي اليومي'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
