import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/state/student_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('progress grants XP once per lesson and supports deletion', () async {
    SharedPreferences.setMockInitialValues({});
    final state = StudentState(await SharedPreferences.getInstance());
    await state.configure('طالب', 12, 'علمي');
    await state.finish('demo-1', 2, 3);
    final xp = state.xp;
    await state.finish('demo-1', 3, 3);
    expect(state.xp, xp);
    expect(state.completed, contains('demo-1'));
    await state.erase();
    expect(state.xp, 0);
    expect(state.configured, isFalse);
  });
}
