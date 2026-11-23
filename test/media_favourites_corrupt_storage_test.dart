import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/data/media_favourites.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const valid = '2aa8cd65-56d6-4ab9-a58a-508792ac4183';

  test('corrupt and non-list saved data fail closed without throwing', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final favourites = MediaFavourites(prefs, userId: 'student');
    for (final raw in ['{broken json', '{"id":"$valid"}', 'null']) {
      await prefs.setString(favourites.key, raw);
      expect(favourites.getAll(), isEmpty);
    }
  });

  test('restoration discards private links and invalid IDs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final favourites = MediaFavourites(prefs, userId: 'student');
    await prefs.setString(favourites.key, jsonEncode([
      valid,
      valid,
      'https://example.org/file?token=private',
      'not-a-resource-id',
      123,
      null,
    ]));
    expect(favourites.getAll(), {valid});
    expect(() => favourites.toggle('https://example.org/private'),
        throwsArgumentError);
    expect(favourites.getAll(), {valid});
  });

  test('restoration limits oversized legacy arrays to 250 UUIDs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final favourites = MediaFavourites(prefs, userId: 'student');
    final ids = List.generate(300,
        (index) => '00000000-0000-0000-0000-${index.toRadixString(16).padLeft(12, '0')}');
    await prefs.setString(favourites.key, jsonEncode(ids));
    expect(favourites.getAll().length, MediaFavourites.maximum);
    expect(favourites.getAll().contains(ids.last), isFalse);
  });
}
