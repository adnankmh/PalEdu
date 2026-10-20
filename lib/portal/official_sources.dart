import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/reading_shelf.dart';
import '../data/ministry_catalog.dart';
import '../data/models.dart';
import '../ui/design.dart';
import '../ui/internal_pdf_reader.dart';

/// Ministry index as an app-owned screen. Clicking a PDF opens its document
/// viewer, NOT an external browser.
class OfficialSourcesScreen extends StatefulWidget {
  const OfficialSourcesScreen({super.key,this.initialGrade=12,
    this.initialBranch='علمي'});
  final int initialGrade;
  final String initialBranch;
  @override
  State<OfficialSourcesScreen> createState()=>_OfficialSourcesScreenState();
}
class _OfficialSourcesScreenState extends State<OfficialSourcesScreen> {
  final repo=MinistryRepository();
  late Future<List<MinistryDocument>> catalog;
  late int grade;
  late String branch;
  String query='',kind='الكل',shelfFilter='all';
  Map<String,ReadingEntry> reading=<String,ReadingEntry>{};

  Future<void> loadReading() async {
    final prefs=await SharedPreferences.getInstance();
    final entries=ReadingShelf(prefs).all();
    if(mounted)setState(() {
      reading={for(final e in entries)e.id:e};
    });
  }
  Future<void> openBook(MinistryDocument doc) async {
    await Navigator.push(context,MaterialPageRoute<void>(
      builder:(_)=>InternalPdfReader(
        title:doc.title,url:doc.url,documentId:doc.id,ministryDocument:doc)));
    if(mounted)await loadReading();
  }
  @override
  void initState(){
    super.initState();
    grade=widget.initialGrade.clamp(1,12);
    branch=LessonCatalog.tracksFor(grade).contains(widget.initialBranch)
      ?widget.initialBranch:LessonCatalog.tracksFor(grade).first;
    catalog=repo.getAll();
    loadReading();
  }
  @override
  void dispose(){repo.dispose();super.dispose();}
  void reload()=>setState(()=>catalog=repo.getAll(refresh:true));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar:AppBar(title:const Text('مكتبة المنهاج الفلسطيني'),
      actions:[IconButton(tooltip:'تحديث فهرس الوزارة',
        onPressed:reload,icon:const Icon(Icons.refresh_rounded))]),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:980),
      child:ListView(padding:const EdgeInsets.fromLTRB(18,14,18,34),children:[
        Container(padding:const EdgeInsets.all(22),
          decoration:BoxDecoration(
            gradient:const LinearGradient(
              colors:[PColors.midnight,PColors.royal,Color(0xFF087E67)]),
            borderRadius:BorderRadius.circular(26)),
          child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Icon(Icons.auto_stories_rounded,color:PColors.gold,size:37),
            SizedBox(height:11),
            Text('كتبك ورزمك في مكان واحد',
              style:TextStyle(color:Colors.white,
                fontSize:24,fontWeight:FontWeight.w900)),
            SizedBox(height:7),
            Text('قراءة الكتب الرسمية داخل PalEdu مع حفظ الصفحة والمفضلة.',
              style:TextStyle(color:Colors.white,fontSize:13)),
          ])),
        const SizedBox(height:18),
        Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,
          children:[
            DropdownButtonFormField<int>(
              key:ValueKey('ministry-grade-'+grade.toString()),
              initialValue:grade,
              isExpanded:true,
              decoration:const InputDecoration(labelText:'الصف الدراسي'),
              items:List.generate(12,(i)=>DropdownMenuItem(
                value:i+1,child:Text(LessonCatalog.gradeName(i+1)))),
              onChanged:(n){
                if(n==null)return;
                setState((){
                  grade=n;
                  branch=LessonCatalog.tracksFor(n).first;
                });
              }),
            if(grade>=11) ...[
              const SizedBox(height:10),
              DropdownButtonFormField<String>(
                key:ValueKey('ministry-branch-'+grade.toString()),
                initialValue:branch,
                decoration:const InputDecoration(labelText:'الفرع أو المسار'),
                isExpanded:true,
                items:LessonCatalog.tracksFor(grade)
                  .map((b)=>DropdownMenuItem(value:b,child:Text(b))).toList(),
                onChanged:(b)=>setState(()=>branch=b??branch)),
            ],
            const SizedBox(height:10),
            TextField(
              onChanged:(v)=>setState(()=>query=v.trim()),
              decoration:const InputDecoration(
                hintText:'ابحث عن كتاب، رزمة أو ملزمة',
                prefixIcon:Icon(Icons.search_rounded))),
          ])),
        const SizedBox(height:12),
        SingleChildScrollView(scrollDirection:Axis.horizontal,
          child:Row(children:[
            for(final k in const ['الكل','كتاب وزاري','رزمة تعليمية']) ...[
              Padding(padding:const EdgeInsets.only(left:8),
                child:ChoiceChip(label:Text(k),selected:kind==k,
                  onSelected:(_)=>setState(()=>kind=k))),
            ],
          ])),
        const SizedBox(height:12),
        SingleChildScrollView(scrollDirection:Axis.horizontal,
          child:Row(children:[
            for(final pair in const [
              ('all','جميع الكتب'),('favourites','مفضلتي'),
              ('recent','متابعة القراءة')
            ]) ...[
              Padding(padding:const EdgeInsets.only(left:8),
                child:ChoiceChip(
                  avatar:Icon(pair.$1=='favourites'
                    ?Icons.bookmark_border_rounded:
                    pair.$1=='recent'?Icons.history_rounded:
                    Icons.library_books_outlined,size:17),
                  label:Text(pair.$2),selected:shelfFilter==pair.$1,
                  onSelected:(_)=>setState(()=>shelfFilter=pair.$1))),
            ],
          ])),
        const SizedBox(height:16),
        FutureBuilder<List<MinistryDocument>>(future:catalog,
          builder:(context,snapshot){
            if(snapshot.hasError) return Panel(
              child:Column(children:[
                const Text('تعذّر تحميل الفهرس. حاول مجدداً عند توفر الإنترنت.'),
                FilledButton(onPressed:reload,child:const Text('إعادة التحميل')),
              ]));
            if(!snapshot.hasData)return const Center(
              child:Padding(padding:EdgeInsets.all(35),
                child:CircularProgressIndicator()));
            final current=snapshot.data!.where((doc)=>
              doc.matches(grade,branch)&&
              (kind=='الكل'||doc.kind==kind)&&
              (shelfFilter=='all'||
                (shelfFilter=='favourites'&&
                  (reading[doc.id]?.favourite??false))||
                (shelfFilter=='recent'&&reading.containsKey(doc.id)))&&
              (doc.title.contains(query)||doc.kind.contains(query)))
              .toList();
            current.sort((a,b)=>shelfFilter=='recent'
              ?(reading[b.id]?.openedAt??0)
                  .compareTo(reading[a.id]?.openedAt??0)
              :a.title.compareTo(b.title));
            if(current.isEmpty) return Column(children:[
              const RoyalSectionHeading(title:'المكتبة'),
              const SizedBox(height:12),
              const Panel(child:Text(
                'لا توجد روابط مباشرة لهذا الصف أو الفرع في الفهرس الحالي. '
                'يمكن تحديث الفهرس عند توفر الإنترنت؛ لن نعرض كتباً وهمية.')),
              const SizedBox(height:10),
              OutlinedButton.icon(onPressed:reload,
                icon:const Icon(Icons.sync),
                label:const Text('تحديث روابط الوزارة')),
            ]);
            return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              RoyalSectionHeading(title:'مكتبتي',
                subtitle:'عدد المواد المتاحة: '+current.length.toString()),
              const SizedBox(height:11),
              ...current.map((doc)=>Padding(
                padding:const EdgeInsets.only(bottom:10),
                child:Card(child:ListTile(
                  contentPadding:const EdgeInsets.all(13),
                  leading:Container(width:48,height:48,
                    decoration:BoxDecoration(color:PColors.mint,
                      borderRadius:BorderRadius.circular(14)),
                    child:const Icon(Icons.picture_as_pdf_rounded,
                      color:PColors.royal,size:27)),
                  title:Text(doc.title,style:const TextStyle(
                    fontWeight:FontWeight.w900)),
                  subtitle:Text(doc.kind+
                    (reading[doc.id]==null?' • وزارة التربية والتعليم الفلسطينية':
                      ' • آخر صفحة '+reading[doc.id]!.lastPage.toString()),
                    style:const TextStyle(fontSize:11.5)),
                  trailing:Icon((reading[doc.id]?.favourite??false)
                    ?Icons.bookmark_rounded:Icons.menu_book_rounded,
                    color:PColors.teal),
                  onTap:()=>openBook(doc),
                )))),
            ]);
          }),
        const SizedBox(height:14),
        Text('تُقرأ الملفات مباشرة من موقع الوزارة؛ لا يعيد التطبيق نشرها. '
          'يتطلب فتح كتاب جديد اتصالاً بالشبكة. تعمل فهرسة الروابط المحفوظة دون اتصال، '
          'لكن قراءة الملف نفسه دون إنترنت تحتاج إلى تنزيل مرخّص.',
          textAlign:TextAlign.center,style:TextStyle(fontSize:11.5,
            color:Theme.of(context).colorScheme.onSurfaceVariant)),
      ]))),
  );
}
