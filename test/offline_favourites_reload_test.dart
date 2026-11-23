import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/data/media_favourites.dart';

const resourceId = '2aa8cd65-56d6-4ab9-a58a-508792ac4183';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('offline favourites survive store recreation without media bytes', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final original = MediaFavourites(prefs, userId: 'offline-student');
    expect(await original.toggle(resourceId), isTrue);

    // No network or Supabase instance is needed to read saved UUIDs.
    final restored = MediaFavourites(prefs, userId: 'offline-student');
    expect(restored.getAll(), {resourceId});
    final stored = prefs.getString(restored.key)!;
    expect(stored, contains(resourceId));
    expect(stored, isNot(contains('offline-student')));
    expect(stored, isNot(contains('https://')));
    expect(stored, isNot(contains('signed_url')));

    final differentAccount = MediaFavourites(prefs, userId: 'another-student');
    expect(differentAccount.getAll(), isEmpty);
    await restored.clear();
    expect(MediaFavourites(prefs, userId: 'offline-student').getAll(), isEmpty);
  });
}
