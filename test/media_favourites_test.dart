import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/data/media_favourites.dart';
import 'package:paledu/state/student_state.dart';

const id1='2aa8cd65-56d6-4ab9-a58a-508792ac4183';
const id2='87b9c601-b25d-47dd-a8df-e2507a482d43';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saved teacher resources persist as UUIDs, not media URLs',() async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final store=MediaFavourites(prefs,userId:'student-1');
    expect(await store.toggle(id1),isTrue);
    expect(await store.toggle(id2),isTrue);
    final saved=MediaFavourites(prefs,userId:'student-1').getAll();
    expect(saved,containsAll([id1,id2]));
    final raw=prefs.getString(store.key)!;
    expect(raw.contains('http'),isFalse);
    expect(raw.contains('student-1'),isFalse);
    expect(await store.toggle(id1),isFalse);
    expect(store.getAll(),{id2});
  });

  test('favourites from one account stay hidden in another account',() async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final alice=MediaFavourites(prefs,userId:'alice');
    final bob=MediaFavourites(prefs,userId:'bob');
    expect(alice.key,isNot(bob.key));
    await alice.toggle(id1);
    expect(bob.getAll(),isEmpty);
    await bob.toggle(id2);
    expect(alice.getAll(),{id1});
    expect(bob.getAll(),{id2});
  });

  test('invalid and malicious IDs are never persisted',() async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final store=MediaFavourites(prefs,userId:'student-1');
    await expectLater(store.toggle(
      'https://example.org/private.pdf?token=secret'),throwsArgumentError);
    expect(store.getAll(),isEmpty);
    expect(()=>MediaFavourites(prefs,userId:''),throwsArgumentError);
  });

  test('delete-my-data clears all local account-scoped saved resources',() async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final alice=MediaFavourites(prefs,userId:'alice');
    final bob=MediaFavourites(prefs,userId:'bob');
    await alice.toggle(id1);
    await bob.toggle(id2);
    final student=StudentState(prefs);
    await student.erase();
    expect(alice.getAll(),isEmpty);
    expect(bob.getAll(),isEmpty);
    expect(prefs.getKeys().where((k)=>
      k.startsWith(MediaFavourites.prefix)),isEmpty);
  });

  test('corrupt stored favourite data fails closed without crashing',() async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final store=MediaFavourites(prefs,userId:'alice');
    await prefs.setString(store.key,'not JSON');
    expect(store.getAll(),isEmpty);
    await prefs.setString(store.key,'["not-a-uuid","'+id1+'"]');
    expect(store.getAll(),{id1});
  });
}
