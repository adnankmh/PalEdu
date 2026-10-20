import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/state/student_state.dart';
import 'package:paledu/ui/royal_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('original Lottie files contain vector animation layers',() async {
    for(final asset in const [
      'assets/animations/welcome_book.json',
      'assets/animations/achievement_stars.json',
    ]){
      final source=await rootBundle.loadString(asset);
      final data=jsonDecode(source) as Map<String,dynamic>;
      expect(data['fr'],30);
      expect(data['ip'],0);
      expect(data['op'],greaterThan(0));
      expect(data['w'],greaterThan(100));
      final layers=data['layers'] as List;
      expect(layers.length,greaterThanOrEqualTo(3));
      expect(layers.every((layer)=>layer is Map &&
        layer['ty']==4 && layer['shapes'] is List),isTrue);
    }
  });

  test('motion preference persists and user deletion resets it',() async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final student=StudentState(prefs);
    expect(student.animationsEnabled,isTrue);
    await student.appearance(motion:false);
    expect(StudentState(prefs).animationsEnabled,isFalse);
    await student.erase();
    expect(StudentState(prefs).animationsEnabled,isTrue);
  });

  testWidgets('system reduce motion uses an accessible static icon',(tester) async {
    await tester.pumpWidget(MaterialApp(
      home:MediaQuery(
        data:const MediaQueryData(disableAnimations:true),
        child:const Scaffold(body:RoyalMotionGraphic(
          asset:'assets/animations/welcome_book.json',
          fallback:Icons.auto_stories_rounded,label:'كتاب المعرفة')))));
    expect(find.byIcon(Icons.auto_stories_rounded),findsOneWidget);
    expect(find.byType(Lottie),findsNothing);
  });

  testWidgets('user motion off prevents animation from loading',(tester) async {
    await tester.pumpWidget(const MaterialApp(
      home:Scaffold(body:RoyalMotionGraphic(
        asset:'assets/animations/achievement_stars.json',
        fallback:Icons.emoji_events_rounded,enabled:false))));
    expect(find.byIcon(Icons.emoji_events_rounded),findsOneWidget);
    expect(find.byType(Lottie),findsNothing);
  });

  testWidgets('the animated variant instantiates the Lottie renderer',(tester) async {
    await tester.pumpWidget(const MaterialApp(
      home:Scaffold(body:RoyalMotionGraphic(
        asset:'assets/animations/welcome_book.json',
        fallback:Icons.auto_stories_rounded))));
    expect(find.byType(Lottie),findsOneWidget);
    await tester.pump(const Duration(milliseconds:300));
  });
}
