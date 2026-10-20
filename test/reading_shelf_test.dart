import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/data/ministry_catalog.dart';
import 'package:paledu/data/reading_shelf.dart';
import 'package:paledu/state/student_state.dart';

const book=MinistryDocument(title:'الرياضيات',grade:12,branch:'علمي',
  kind:'كتاب وزاري',url:'https://moe.edu.ps/m/4099');
const untrusted=MinistryDocument(title:'ملف غير موثوق',grade:12,branch:'علمي',
  kind:'كتاب وزاري',url:'https://example.org/secret?token=test');

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  test('remember last-read page and public ministry bookmark locally',() async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final shelf=ReadingShelf(prefs);
    await shelf.recordOpen(book);
    await shelf.setPage(book.id,37);
    await shelf.setFavourite(book,true);
    final entry=shelf.first(book.id)!;
    expect(entry.lastPage,37);
    expect(entry.favourite,isTrue);
    expect(entry.url,book.url);
    expect(ReadingShelf(prefs).first(book.id)?.lastPage,37);
    expect(prefs.getString(ReadingShelf.key),contains('moe.edu.ps'));
  });
  test('never persist temporary credentials or non-ministry links',() async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final shelf=ReadingShelf(prefs);
    await shelf.recordOpen(untrusted);
    await shelf.setFavourite(untrusted,true);
    expect(shelf.all(),isEmpty);
    expect(prefs.getString(ReadingShelf.key),isNull);
  });
  test('erase student data also clears reading history and legacy pages',() async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance();
    final shelf=ReadingShelf(prefs);
    await shelf.recordOpen(book);
    await shelf.setPage(book.id,22);
    await prefs.setInt('paledu_pdf_page_'+book.id,22);
    await prefs.setBool('paledu_pdf_bookmark_'+book.id,true);
    final student=StudentState(prefs);
    await student.erase();
    expect(shelf.all(),isEmpty);
    expect(prefs.containsKey('paledu_pdf_page_'+book.id),isFalse);
    expect(prefs.containsKey('paledu_pdf_bookmark_'+book.id),isFalse);
  });
  test('corrupted reading cache is ignored safely',() async {
    SharedPreferences.setMockInitialValues({ReadingShelf.key:'{not-json'});
    final prefs=await SharedPreferences.getInstance();
    expect(ReadingShelf(prefs).all(),isEmpty);
  });
}
