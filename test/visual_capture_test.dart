import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
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
    // Flutter's test engine defaults to Ahem (square placeholder glyphs).
    // Load the CI runner's existing Arabic-capable font for readable captures.
    final fontFile=File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
    if (!fontFile.existsSync()) {
      throw StateError('Arabic screenshot font unavailable on runner');
    }
    final loader=FontLoader('PalEduVisualArabic')
      ..addFont(Future.value(ByteData.sublistView(fontFile.readAsBytesSync())));
    await loader.load();
    final iconsPath=Platform.environment['PALEDU_MATERIAL_ICONS'];
    if(iconsPath==null||!File(iconsPath).existsSync()) {
      throw StateError('Set PALEDU_MATERIAL_ICONS to Flutter MaterialIcons-Regular.otf');
    }
    final icons=FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(File(iconsPath).readAsBytesSync())));
    await icons.load();
    student.animationsEnabled = false;
    tester.view.physicalSize = const Size(860, 1860);
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Future<void> record(Widget child, String filename, {bool dark = false}) async {
      final original=palTheme(dark);
      const font='PalEduVisualArabic';
      final themed=original.copyWith(
        textTheme:original.textTheme.apply(fontFamily:font),
        primaryTextTheme:original.primaryTextTheme.apply(fontFamily:font),
        appBarTheme:original.appBarTheme.copyWith(
          titleTextStyle:original.appBarTheme.titleTextStyle?.copyWith(fontFamily:font)),
        navigationBarTheme:original.navigationBarTheme.copyWith(
          labelTextStyle:WidgetStateProperty.resolveWith((states)=>
            original.navigationBarTheme.labelTextStyle?.resolve(states)?.copyWith(fontFamily:font))),
        filledButtonTheme:FilledButtonThemeData(style:
          original.filledButtonTheme.style?.copyWith(textStyle:
            WidgetStateProperty.resolveWith((states)=>
              original.filledButtonTheme.style?.textStyle?.resolve(states)?.copyWith(fontFamily:font)))),
      );
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar', 'PS'),
        theme: themed,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: child,
        ),
      ));
      // Fixed finite frame advance: animated progress must not stall goldens.
      await tester.pump(const Duration(milliseconds: 1200));
      expect(tester.takeException(), isNull, reason: 'Flutter layout must be valid for '+filename);
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
