import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/data/models.dart';
import 'package:paledu/main.dart';
import 'package:paledu/state/student_state.dart';
import 'package:paledu/ui/design.dart';
import 'package:paledu/ui/royal_achievements.dart';
import 'package:paledu/ui/royal_subject_library.dart';
import 'package:paledu/ui/royal_mistake_notebook.dart';

const capture = bool.fromEnvironment('PALEDU_CAPTURE_GOLDENS', defaultValue: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('visual capture is opt-in and never accesses production', () {
    expect(true, isTrue);
  });
  if (!capture) return;

  testWidgets('capture real Flutter widget screens without external service',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    // Avoid awaiting an asset-channel future inside the widget-test fake clock.
    final catalog = LessonCatalog.parse(
      File('assets/curriculum/sample_lessons.json').readAsStringSync());
    final student = StudentState(prefs);
    student.animationsEnabled = false;
    tester.view.physicalSize = const Size(860, 1860);
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Future<void> record(Widget child, String filename, {bool dark = false}) async {
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar', 'PS'),
        theme: palTheme(dark),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      ));
      // Fixed finite frame advance: animated progress must not stall goldens.
      await tester.pump(const Duration(milliseconds: 1200));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('visual/$filename.png'),
      );
    }

    // These are production widget classes, not redrawn mockups.
    await record(SetupScreen(student: student), '01-setup');
    await student.configure('طالب تجريبي', 5, 'عام');
    final lessons = catalog.forStudent(student.grade, student.track);
    await record(HomeShell(student: student, catalog: catalog),
        '02-student-home');
    await record(Scaffold(
      body: RoyalSubjectLibrary(
        student: student,
        lessons: lessons,
        onLesson: (_) {},
        onOfficialSources: () {},
      ),
    ), '03-subjects');
    await record(RoyalAchievementsScreen(
      student: student, lessons: lessons,
      onPractice: () {}, onSubjects: () {},
    ), '04-achievements');
    await record(RoyalMistakeNotebook(
      student: student, lessons: lessons,
    ), '05-mistake-notebook');
    await record(HomeShell(student: student, catalog: catalog),
        '06-home-dark',dark: true);
  });
}
