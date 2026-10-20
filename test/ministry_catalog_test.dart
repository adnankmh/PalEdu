import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paledu/data/ministry_catalog.dart';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  test('ministry parser reads first grade and tawjihi branches',(){
    const markup='''
    <html><body>
      <h4>الرزم التعليمية- الصف الأول</h4>
      <table><tr><td>1</td><td>الرياضيات</td><td><a href="/m/4070">تحميل</a></td></tr></table>
      <h4>الرزم التعليمية- الثاني عشر/ علمي</h4>
      <table><tr><td>1</td><td>الكيمياء</td><td><a href="/m/4060">تحميل</a></td></tr></table>
      <h4>الرزم التعليمية- الثاني عشر/ العلوم الإنسانية</h4>
      <table><tr><td>1</td><td>التاريخ</td><td><a href="/m/4061">تحميل</a></td></tr></table>
    </body></html>
    ''';
    final docs=MinistryIndex.parse(markup,
      origin:'https://moe.edu.ps/gaza/subjects',kind:'رزمة تعليمية');
    expect(docs.length,3);
    expect(docs[0].grade,1);
    expect(docs[0].branch,'عام');
    expect(docs[0].url,'https://moe.edu.ps/m/4070');
    expect(docs[1].matches(12,'علمي'),isTrue);
    expect(docs[2].matches(12,'أدبي'),isTrue);
    expect(docs[2].matches(12,'علمي'),isFalse);
  });
  test('never index untrusted external download domains',(){
    const markup='<h4>الرزم التعليمية- الصف الخامس</h4>'
      '<table><tr><td>1</td><td>كتاب مزور</td>'
      '<td><a href="https://untrusted.example/file.pdf">تحميل</a></td></tr></table>';
    final docs=MinistryIndex.parse(markup,
      origin:'https://moe.edu.ps/gaza/subjects',kind:'رزمة تعليمية');
    expect(docs,isEmpty);
    expect(MinistryIndex.official(Uri.parse('http://moe.edu.ps/m/123')),isFalse);
  });
  test('fallback index remains accessible without a network',() async {
    SharedPreferences.setMockInitialValues({});
    final repo=MinistryRepository(client:MockClient(
      (_) async=>http.Response('Unavailable',503)));
    final result=await repo.getAll(refresh:true);
    expect(result,contains(predicate<MinistryDocument>((d)=>
      d.grade==12&&d.title=='الفيزياء')));
    repo.dispose();
  });
}
