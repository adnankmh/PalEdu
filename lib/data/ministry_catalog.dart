import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MinistryDocument {
  const MinistryDocument({required this.title,required this.grade,
    required this.branch,required this.kind,required this.url});
  final String title,branch,kind,url;
  final int grade;
  String get id=>sha256.convert(utf8.encode(url)).toString().substring(0,24);
  bool matches(int grade,String branch)=>this.grade==grade &&
    (grade<=10||this.branch==branch||this.branch=='عام');
  factory MinistryDocument.fromJson(Map<String,dynamic> v)=>MinistryDocument(
    title:v['title'] as String,grade:v['grade'] as int,
    branch:v['branch'] as String,kind:v['kind'] as String,url:v['url'] as String);
  Map<String,dynamic> toJson()=>{'title':title,'grade':grade,
    'branch':branch,'kind':kind,'url':url};
}

class MinistryIndex {
  static const _grades=['الأول','الثاني','الثالث','الرابع','الخامس',
    'السادس','السابع','الثامن','التاسع','العاشر'];
  static int? parseGrade(String heading) {
    if(heading.contains('الحادي عشر'))return 11;
    if(heading.contains('الثاني عشر'))return 12;
    for(var i=0;i<_grades.length;i++){
      if(heading.contains('الصف '+_grades[i]))return i+1;
    }
    return null;
  }
  static String parseBranch(String heading,int grade){
    if(grade<11)return 'عام';
    if(heading.contains('صناعي'))return 'صناعي';
    if(heading.contains('زراعي'))return 'زراعي';
    if(heading.contains('شرعي'))return 'شرعي';
    if(heading.contains('ريادة'))return 'ريادة وأعمال';
    if(heading.contains('اقتصاد منزلي'))return 'اقتصاد منزلي';
    if(heading.contains('إنسانية')||heading.contains('الأدبي'))return 'أدبي';
    if(heading.contains('علمي'))return 'علمي';
    return 'عام';
  }
  static bool official(Uri uri)=>uri.scheme=='https'&&
    (uri.host=='moe.edu.ps'||uri.host.endsWith('.moe.edu.ps'));
  static List<MinistryDocument> parse(String source,
      {required String origin,required String kind}){
    final root=parser.parse(source);
    final current=Uri.parse(origin);
    int? grade;
    var branch='عام';
    final result=<MinistryDocument>[];
    for(final el in root.querySelectorAll('h2,h3,h4,h5,table')){
      if(el.localName!='table'){
        final number=parseGrade(el.text);
        if(number!=null){grade=number;branch=parseBranch(el.text,number);}
        continue;
      }
      if(grade==null)continue;
      for(final tr in el.querySelectorAll('tr')){
        final anchor=tr.querySelector('a[href]');
        final href=anchor?.attributes['href'];
        if(href==null||href.trim().isEmpty)continue;
        final uri=current.resolve(href.trim());
        if(!official(uri))continue;
        final path=uri.path.toLowerCase();
        if(!path.endsWith('.pdf')&&!path.startsWith('/m/')&&
          !path.contains('/storage/app/'))continue;
        final cells=tr.querySelectorAll('td');
        if(cells.length<2)continue;
        final title=cells[cells.length-2].text.trim()
          .replaceAll(RegExp(r'\s+'),' ');
        if(title.isEmpty||title=='تحميل')continue;
        result.add(MinistryDocument(title:title,grade:grade,
          branch:branch,kind:kind,url:uri.toString()));
      }
    }
    return result;
  }
}

class MinistryRepository {
  MinistryRepository({http.Client? client}):_client=client??http.Client();
  final http.Client _client;
  static const cacheKey='paledu_official_pdf_index_v1';
  static const links={
    'https://moe.edu.ps/gaza/subjects':'رزمة تعليمية',
    'https://www.moe.edu.ps/class12/books':'كتاب وزاري',
  };
  static const fallback=<MinistryDocument>[
    MinistryDocument(title:'الرياضيات',grade:12,branch:'علمي',kind:'كتاب وزاري',
      url:'https://moe.edu.ps/storage/app/class12/MathElmi12%202025%20Tawjihi.pdf'),
    MinistryDocument(title:'الفيزياء',grade:12,branch:'علمي',kind:'كتاب وزاري',
      url:'https://moe.edu.ps/storage/app/class12/Physics12%202025%20Tawjihi.pdf'),
    MinistryDocument(title:'الكيمياء',grade:12,branch:'علمي',kind:'كتاب وزاري',
      url:'https://moe.edu.ps/storage/app/class12/Chemistry12%202025%20Tawjihi%20Elmi.pdf'),
    MinistryDocument(title:'اللغة العربية',grade:12,branch:'علمي',kind:'كتاب وزاري',
      url:'https://moe.edu.ps/storage/app/class12/ArabicMotalaa12%202025%20Tawjihi.pdf'),
    MinistryDocument(title:'الدراسات الجغرافية',grade:12,branch:'أدبي',kind:'كتاب وزاري',
      url:'https://moe.edu.ps/storage/app/class12/Geography12%202025%20Tawjihi.pdf'),
    MinistryDocument(title:'الدراسات التاريخية',grade:12,branch:'أدبي',kind:'كتاب وزاري',
      url:'https://moe.edu.ps/storage/app/class12/History12%202025%20Tawjihi.pdf'),
    MinistryDocument(title:'الرياضيات - الرزمة التعليمية',grade:10,branch:'عام',
      kind:'رزمة تعليمية',url:'https://moe.edu.ps/m/4099'),
    MinistryDocument(title:'الرياضيات - الرزمة التعليمية',grade:11,branch:'علمي',
      kind:'رزمة تعليمية',url:'https://moe.edu.ps/m/4107'),
    MinistryDocument(title:'التربية الإسلامية - الرزمة التعليمية',grade:12,
      branch:'علمي',kind:'رزمة تعليمية',url:'https://moe.edu.ps/m/4064'),
  ];
  Future<List<MinistryDocument>> getAll({bool refresh=false}) async {
    final prefs=await SharedPreferences.getInstance();
    final docs=<String,MinistryDocument>{
      for(final d in fallback) _key(d):d,
    };
    final cached=prefs.getString(cacheKey);
    if(cached!=null){
      try{
        for(final v in jsonDecode(cached) as List){
          final d=MinistryDocument.fromJson(Map<String,dynamic>.from(v as Map));
          if(MinistryIndex.official(Uri.parse(d.url)))docs[_key(d)]=d;
        }
      }catch(_){/* A corrupted cache never blocks access to fallback PDFs. */}
    }
    if(cached!=null&&!refresh)return docs.values.toList();
    var updated=false;
    for(final source in links.entries){
      try{
        final reply=await _client.get(Uri.parse(source.key))
          .timeout(const Duration(seconds:12));
        if(reply.statusCode!=200)continue;
        final results=MinistryIndex.parse(
          utf8.decode(reply.bodyBytes,allowMalformed:true),
          origin:source.key,kind:source.value);
        if(results.isNotEmpty){
          updated=true;
          for(final d in results)docs[_key(d)]=d;
        }
      }catch(_){/* Offline: keep known/cached ministry URLs. */}
    }
    if(updated)await prefs.setString(cacheKey,
      jsonEncode(docs.values.map((v)=>v.toJson()).toList()));
    return docs.values.toList();
  }
  static String _key(MinistryDocument d)=>
    d.url+':'+d.grade.toString()+':'+d.branch;
  void dispose()=>_client.close();
}
