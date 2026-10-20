import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/data/models.dart';
import 'package:paledu/state/student_state.dart';
import 'package:paledu/ui/design.dart';
import 'package:paledu/ui/royal_lesson_reader.dart';

const lesson=Lesson(id:'e1',grade:12,track:'علمي',subject:'الرياضيات',
  title:'أمثلة حقيقية',summary:'درس للمراجعة',
  sections:['تعلّم قاعدة جديدة'],duration:9,questions:[
    QuizQuestion(prompt:'سؤال تجريبي',options:['أ','ب'],
      correct:1,explanation:'توضيح'),
  ]);

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  test('lesson note saves, restores and clears from device',() async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final student=StudentState(prefs);
    await student.saveLessonNote('e1','ملحوظة مهمة');
    expect(student.noteFor('e1'),'ملحوظة مهمة');
    final restored=StudentState(prefs);
    expect(restored.noteFor('e1'),'ملحوظة مهمة');
    await restored.erase();
    expect(restored.noteFor('e1'),isEmpty);
    expect(StudentState(prefs).noteFor('e1'),isEmpty);
  });
  testWidgets('lesson tabs keep real content and working actions',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final student=StudentState(await SharedPreferences.getInstance());
      var tested=false;
      await tester.pumpWidget(MaterialApp(theme:palTheme(false),
        home:Directionality(textDirection:TextDirection.rtl,
          child:RoyalLessonReader(
            lesson:lesson,student:student,onQuiz:(){tested=true;},
            onFlashcards:(){},onMatch:(){}))));
      expect(find.text('أمثلة حقيقية'),findsOneWidget);
      await tester.tap(find.text('اختبر نفسك'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ابدأ الاختبار التفاعلي'));
      await tester.tap(find.text('ابدأ الاختبار التفاعلي'));
      expect(tested,isTrue);
    });
}
