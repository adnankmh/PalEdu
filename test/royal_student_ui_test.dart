import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/data/models.dart';
import 'package:paledu/state/student_state.dart';
import 'package:paledu/ui/design.dart';
import 'package:paledu/ui/royal_student_home.dart';
import 'package:paledu/ui/royal_subject_library.dart';

const sample=Lesson(
  id:'sample',grade:12,track:'علمي',subject:'الرياضيات',
  title:'تجربة التفاضل',summary:'مثال تعليمي',sections:['تجربة'],
  questions:[],duration:8);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('premium home displays actual zero progress, not fake stats',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final student=StudentState(await SharedPreferences.getInstance());
      await student.configure('أحمد',12,'علمي');
      await tester.pumpWidget(MaterialApp(
        theme:palTheme(false),
        home:Directionality(textDirection:TextDirection.rtl,
          child:Scaffold(body:RoyalStudentHome(
            student:student,lessons:const [sample],
            onSubjects:(){},onGames:(){},onReview:(){},
            onAchievements:(){},onMistakes:(){},
            onOfficialSources:(){},onLesson:(_){},
          )))));
      expect(find.text('مرحباً، أحمد'), findsOneWidget);
      expect(find.text('0%'), findsWidgets);
      expect(find.text('متابعة التعلّم'), findsOneWidget);
    });
  testWidgets('subject accordion reveals lesson and invokes navigation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final student=StudentState(await SharedPreferences.getInstance());
      await student.configure('طالب',12,'علمي');
      var tapped=false;
      await tester.pumpWidget(MaterialApp(
        theme:palTheme(false),
        home:Directionality(textDirection:TextDirection.rtl,
          child:Scaffold(body:RoyalSubjectLibrary(
            student:student,lessons:const [sample],
            onOfficialSources:(){},
            onLesson:(_){tapped=true;},
          )))));
      expect(find.text('المقررات والوحدات الدراسية'),findsOneWidget);
      await tester.tap(find.text('الرياضيات').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('تجربة التفاضل'));
      await tester.tap(find.text('تجربة التفاضل'));
      expect(tapped,isTrue);
    });
}
