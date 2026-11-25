import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/data/models.dart';
import 'package:paledu/state/student_state.dart';
import 'package:paledu/ui/design.dart';
import 'package:paledu/ui/royal_learning_report.dart';

Lesson lesson(String id, String subject, String title) => Lesson(
  id: id, grade: 5, track: 'عام', subject: subject, title: title,
  summary: '', sections: const [], questions: const [], duration: 5,
);

void main() {
  late StudentState student;
  final math = lesson('math', 'الرياضيات', 'الكسور');
  final science = lesson('science', 'العلوم', 'الطاقة');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    student = StudentState(await SharedPreferences.getInstance());
  });

  tearDown(() => student.dispose());

  Future<void> show(WidgetTester tester, ValueChanged<Lesson> onLesson) =>
      tester.pumpWidget(MaterialApp(
        theme: palTheme(false),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl, child: child!,
        ),
        home: RoyalLearningReportScreen(
          student: student, lessons: [math, science], onLesson: onLesson,
        ),
      ));

  testWidgets('empty report does not fabricate scores and updates after quiz',
    (tester) async {
      await show(tester, (_) {});
      expect(find.text('لا توجد محاولات مكتملة بعد'), findsOneWidget);
      expect(find.byKey(const Key('report-accuracy')), findsNothing);
      await student.finish('math', 2, 4);
      await tester.pumpAndSettle();
      expect(find.text('نسبة الإجابات الصحيحة: 50.0%'), findsOneWidget);
      expect(find.text('المحاولات: 1'), findsOneWidget);
      await student.erase();
      await tester.pumpAndSettle();
      expect(find.text('لا توجد محاولات مكتملة بعد'), findsOneWidget);
    },
  );

  testWidgets('subject filters scope totals and revision opens matching lesson',
    (tester) async {
      await student.finish('math', 2, 4);
      await student.finish('science', 8, 8);
      await student.finish('other-grade', 0, 100);
      Lesson? selected;
      await show(tester, (value) => selected = value);
      expect(find.text('نسبة الإجابات الصحيحة: 83.3%'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'الرياضيات'));
      await tester.pumpAndSettle();
      expect(find.text('نسبة الإجابات الصحيحة: 50.0%'), findsOneWidget);
      final revision = find.byKey(const ValueKey('revision-math'));
      await tester.scrollUntilVisible(revision, 180);
      await tester.tap(revision);
      expect(selected, same(math));
      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'العلوم'), -200,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'العلوم'));
      await tester.pumpAndSettle();
      expect(find.text('نسبة الإجابات الصحيحة: 100.0%'), findsOneWidget);
      expect(find.byKey(const ValueKey('revision-math')), findsNothing);
    },
  );

  testWidgets('CSV sharing requests consent and can be cancelled',
    (tester) async {
      await student.finish('math', 1, 2);
      await show(tester, (_) {});
      final copy = find.widgetWithText(OutlinedButton, 'نسخ تقرير CSV');
      await tester.scrollUntilVisible(copy, 200);
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(find.text('نسخ التقرير؟'), findsOneWidget);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(find.text('نسخ التقرير؟'), findsNothing);
      expect(find.text('تم نسخ التقرير بصيغة CSV'), findsNothing);
    },
  );
}
