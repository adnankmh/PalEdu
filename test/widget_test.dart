import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/main.dart';
import 'package:paledu/data/models.dart';
import 'package:paledu/state/student_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('welcomes the learner and offers grade choice', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(PalEduApp(
      catalog: const LessonCatalog([]), student: StudentState(prefs)));
    expect(find.text('اختر طريقة الدخول'), findsOneWidget);
    expect(find.text('مدير المنصة'), findsOneWidget);
  });
}
