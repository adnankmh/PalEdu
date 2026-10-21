import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/data/models.dart';
import 'package:paledu/data/mistake_notebook.dart';
import 'package:paledu/state/student_state.dart';
import 'package:paledu/ui/design.dart';
import 'package:paledu/ui/royal_mistake_notebook.dart';

const lesson=Lesson(
  id:'math-demo',grade:12,track:'علمي',
  subject:'الرياضيات',title:'تجربة حسابية',
  summary:'تجريبي',sections:['تجربة'],duration:7,
  questions:[
    QuizQuestion(prompt:'ما ناتج 2 + 2؟',
      options:['3','4','5'],correct:1,
      explanation:'نجمع العددين فنحصل على أربعة.'),
    QuizQuestion(prompt:'ما ناتج 3 × 3؟',
      options:['6','8','9'],correct:2,
      explanation:'ثلاث مجموعات من ثلاثة تساوي تسعة.'),
  ]);

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wrong answer tracked by fingerprint and stored without answer text',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final student=StudentState(prefs);
    await student.recordQuizAnswers(lesson,{0:false,1:true});
    expect(student.mistakes.countFor(lesson),1);
    final raw=prefs.getString(MistakeNotebook.storageKey)!;
    expect(raw,contains('math-demo'));
    expect(raw.contains('ما ناتج'),isFalse);
    expect(raw.contains('نجمع'),isFalse);
    final reloaded=StudentState(prefs);
    expect(reloaded.mistakes.contains(lesson,0),isTrue);
    expect(reloaded.mistakes.contains(lesson,1),isFalse);
  });

  test('correct self-practice removes wrong question, never grants XP',
      () async {
    SharedPreferences.setMockInitialValues({});
    final student=StudentState(await SharedPreferences.getInstance());
    await student.recordQuizAnswers(lesson,{0:false,1:false});
    final previousXp=student.xp;
    await student.resolveWrongAnswer(lesson,0);
    expect(student.mistakes.contains(lesson,0),isFalse);
    expect(student.mistakes.contains(lesson,1),isTrue);
    expect(student.xp,previousXp);
    await student.recordQuizAnswers(lesson,{1:true});
    expect(student.mistakes.countFor(lesson),0);
  });

  test('changed question fingerprint does not link to old answer',() async {
    SharedPreferences.setMockInitialValues({});
    final student=StudentState(await SharedPreferences.getInstance());
    await student.recordQuizAnswers(lesson,{0:false});
    const updated=Lesson(
      id:'math-demo',grade:12,track:'علمي',subject:'الرياضيات',
      title:'معدل',summary:'',sections:[],duration:7,
      questions:[QuizQuestion(prompt:'سؤال جديد بعد تعديل المنهج',
        options:['س','ص'],correct:1,explanation:'مراجعة')]);
    expect(student.mistakes.contains(updated,0),isFalse);
    expect(pendingWrongQuestions(student,[updated]),isEmpty);
    expect(pendingWrongQuestions(student,[lesson]).length,1);
  });

  test('malformed local records do not crash startup, erasure removes state',
      () async {
    SharedPreferences.setMockInitialValues({
      MistakeNotebook.storageKey:'{"fake":["bad","a".padLeft(24)]}',
    });
    final prefs=await SharedPreferences.getInstance();
    final student=StudentState(prefs);
    expect(student.mistakes.total,0);
    await student.recordQuizAnswers(lesson,{0:false});
    await student.erase();
    expect(StudentState(prefs).mistakes.total,0);
    expect(prefs.containsKey(MistakeNotebook.storageKey),isFalse);
  });

  testWidgets('mistake notebook opens the internal correction practice',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final student=StudentState(await SharedPreferences.getInstance());
    await student.recordQuizAnswers(lesson,{0:false});
    await tester.pumpWidget(MaterialApp(theme:palTheme(false),
      home:RoyalMistakeNotebook(student:student,lessons:const [lesson])));
    expect(find.text('دفتر أخطائي'),findsOneWidget);
    expect(find.text('أسئلة تحتاج مراجعة: 1'),findsOneWidget);
    await tester.tap(find.text('ابدأ تصحيح أخطائي'));
    await tester.pumpAndSettle();
    expect(find.text('ما ناتج 2 + 2؟'),findsOneWidget);
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    expect(student.mistakes.total,0);
  });
}
