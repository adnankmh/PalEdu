import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/data/models.dart';
import 'package:paledu/state/student_state.dart';
import 'package:paledu/ui/design.dart';
import 'package:paledu/ui/subject_progress_report.dart';

const lessons=[
  Lesson(id:'m1',grade:9,track:'عام',subject:'الرياضيات',
    title:'الجبر',summary:'',sections:[],questions:[],duration:5),
  Lesson(id:'m2',grade:9,track:'عام',subject:'الرياضيات',
    title:'الهندسة',summary:'',sections:[],questions:[],duration:5),
  Lesson(id:'a1',grade:9,track:'عام',subject:'اللغة العربية',
    title:'القراءة',summary:'',sections:[],questions:[],duration:5),
];

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();

  test('per-subject progress uses only local completed lessons and last score',() async {
    SharedPreferences.setMockInitialValues({});
    final student=StudentState(await SharedPreferences.getInstance());
    await student.finish('m1',9,10,now:DateTime(2026,11,17));
    await student.finish('a1',3,10,now:DateTime(2026,11,17));
    final report=calculateSubjectProgress(student,lessons);
    final math=report.singleWhere((e)=>e.subject=='الرياضيات');
    final arabic=report.singleWhere((e)=>e.subject=='اللغة العربية');
    expect(math.total,2);
    expect(math.completed,1);
    expect(math.strong,1);
    expect(math.ratio,0.5);
    expect(math.percent,50);
    expect(arabic.percent,100);
    expect(arabic.completed,1);
    expect(arabic.strong,0);
    expect(calculateSubjectProgress(student,[]),isEmpty);
    await student.erase();
    expect(calculateSubjectProgress(student,lessons)
      .every((e)=>e.completed==0 && e.strong==0),isTrue);
  });

  test('duplicate lesson IDs do not inflate progress',() async {
    SharedPreferences.setMockInitialValues({});
    final student=StudentState(await SharedPreferences.getInstance());
    await student.finish('m1',8,10,now:DateTime(2026,11,17));
    final report=calculateSubjectProgress(student,[lessons.first,lessons.first]);
    expect(report.single.total,1);
    expect(report.single.completed,1);
    expect(report.single.strong,1);
    expect(report.single.percent,100);
  });

  testWidgets('subject percentages render from local records',(tester) async {
    SharedPreferences.setMockInitialValues({});
    final student=StudentState(await SharedPreferences.getInstance());
    await student.finish('m1',9,10,now:DateTime(2026,11,17));
    await tester.pumpWidget(MaterialApp(
      theme:palTheme(false),
      home:Directionality(textDirection:TextDirection.rtl,
        child:SubjectProgressReport(student:student,lessons:lessons))));
    expect(find.text('المكتملة: 1 من 2 • 50٪'),findsOneWidget);
    expect(find.text('المكتملة: 0 من 1 • 0٪'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  testWidgets('RTL report renders with zero lessons on narrow screens',(tester) async {
    tester.view.physicalSize=const Size(320,690);
    tester.view.devicePixelRatio=1;
    addTearDown((){
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues({});
    final student=StudentState(await SharedPreferences.getInstance());
    await tester.pumpWidget(MaterialApp(
      theme:palTheme(false),
      home:Directionality(textDirection:TextDirection.rtl,
        child:SubjectProgressReport(student:student,lessons:const []))));
    expect(find.text('تقرير تقدمي حسب المبحث'),findsOneWidget);
    expect(find.text('لا توجد دروس متاحة لعرض التقرير.'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
