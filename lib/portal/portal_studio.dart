import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models.dart';
import '../ui/design.dart';
import 'portal_service.dart';

Widget _page(Widget child)=>Center(child:ConstrainedBox(
  constraints:const BoxConstraints(maxWidth:980),child:child));

class TeacherStudio extends StatefulWidget {
  const TeacherStudio({super.key,required this.role,required this.onSignOut});
  final String role;
  final Future<void> Function() onSignOut;
  @override
  State<TeacherStudio> createState()=>_TeacherStudioState();
}
class _TeacherStudioState extends State<TeacherStudio> {
  late Future<List<Map<String,dynamic>>> resources;
  @override
  void initState(){super.initState();refresh();}
  void refresh()=>resources=PortalService.instance.mine();
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.role=='trainer'?'استوديو المدرب':'استوديو المعلم'),
      actions:[IconButton(tooltip:'تسجيل الخروج',
        onPressed:widget.onSignOut,icon:const Icon(Icons.logout))]),
    floatingActionButton:FloatingActionButton.extended(
      icon:const Icon(Icons.add_rounded),label:const Text('إضافة محتوى'),
      onPressed:() async {
        await Navigator.push(context,MaterialPageRoute<void>(
          builder:(_)=>const ResourceComposer()));
        if (mounted) setState(refresh);
      }),
    body:_page(ListView(padding:const EdgeInsets.fromLTRB(20,18,20,95),children:[
      Container(padding:const EdgeInsets.all(24),
        decoration:BoxDecoration(
          gradient:const LinearGradient(
            colors:[PColors.royal,PColors.midnight,Color(0xFF087D88)]),
          borderRadius:BorderRadius.circular(28)),
        child:const Column(crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Icon(Icons.co_present_rounded,color:PColors.gold,size:43),
            SizedBox(height:12),
            Text('اصنع تعلّماً يترك أثراً',style:TextStyle(
              color:Colors.white,fontSize:25,fontWeight:FontWeight.w900)),
            SizedBox(height:8),
            Text('كتب، ملازم، فيديوهات ودروس بانتظار اعتماد الإدارة',
              style:TextStyle(color:Colors.white,fontSize:15)),
          ])),
      const SizedBox(height:21),
      Row(children:[
        Expanded(child:Text('المحتوى الذي أضفته',
          style:Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight:FontWeight.w900))),
        IconButton(onPressed:()=>setState(refresh),
          tooltip:'تحديث',icon:const Icon(Icons.refresh)),
      ]),
      const SizedBox(height:11),
      FutureBuilder<List<Map<String,dynamic>>>(
        future:resources,builder:(context,snapshot) {
          if (snapshot.hasError) return const Panel(
            child:Text('تعذّر تحميل المواد. حاول إعادة التحديث.'));
          if (!snapshot.hasData) return const Center(
            child:CircularProgressIndicator());
          final list=snapshot.data!;
          if (list.isEmpty) return const Panel(
            child:Text('لا توجد مواد بعد. اختر إضافة محتوى لبدء العمل.'));
          return Column(children:[
            for(final item in list) Padding(
              padding:const EdgeInsets.only(bottom:10),
              child:Panel(child:ListTile(
                leading:const Icon(Icons.article_outlined,color:PColors.teal),
                title:Text(item['title']?.toString()??''),
                subtitle:Text((item['subject']?.toString()??'')+' • '+
                  (item['grade']?.toString()??'')),
                trailing:Chip(label:Text(_status(item['status']?.toString()))))),
          ]);
        }),
      const SizedBox(height:15),
      const Panel(child:Text('أي مادة يرفعها المعلم لا تظهر للطلاب حتى يعتمدها المدير ويُراجع حقوق استخدامها.')),
    ])),
  );
  String _status(String? s)=>switch(s){
    'draft'=>'مسودة',
    'pending'=>'بانتظار المراجعة',
    'published'=>'منشور',
    'rejected'=>'مرفوض',
    _=>'غير معروف',
  };
}

class ResourceComposer extends StatefulWidget {
  const ResourceComposer({super.key});
  @override
  State<ResourceComposer> createState()=>_ResourceComposerState();
}
class _ResourceComposerState extends State<ResourceComposer> {
  final title=TextEditingController();
  final summary=TextEditingController();
  final subject=TextEditingController();
  final rights=TextEditingController();
  final link=TextEditingController();
  String kind='book',branch='عام',fileName='';
  int grade=1;
  Uint8List? bytes;
  bool sending=false;
  @override
  void dispose(){
    title.dispose();summary.dispose();subject.dispose();
    rights.dispose();link.dispose();super.dispose();
  }
  Future<void> pick() async {
    try {
      final result=await FilePicker.platform.pickFiles(
        type:FileType.custom,
        allowedExtensions:['pdf','mp4','jpg','jpeg','png'],
        withData:true);
      if(result==null) return;
      final file=result.files.single;
      if(file.size>50*1024*1024) throw ArgumentError('Large file');
      if(file.bytes==null) throw ArgumentError('No file data');
      if(mounted)setState((){bytes=file.bytes;fileName=file.name;});
    } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('تعذر قراءة الملف؛ يجب ألا يتجاوز 50MB')));
    }
  }
  Future<void> send() async {
    if(sending) return;
    setState(()=>sending=true);
    try {
      await PortalService.instance.submit(
        title:title.text,summary:summary.text,subject:subject.text,
        kind:kind,grade:grade,branch:branch,rights:rights.text,
        bytes:bytes,fileName:bytes==null?null:fileName,
        url:link.text.trim().isEmpty?null:link.text.trim());
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content:Text('أُرسل المحتوى لانتظار موافقة المدير')));
        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('فشل رفع المادة. تحقق من الحقول والصلاحيات وحجم الملف.')));
    } finally {if(mounted)setState(()=>sending=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('إضافة مادة تعليمية')),
    body:_page(ListView(padding:const EdgeInsets.all(20),children:[
      const Text('استوديو تأليف المحتوى',
        style:TextStyle(fontSize:25,fontWeight:FontWeight.w900)),
      const SizedBox(height:6),
      const Text('صف المحتوى وارفع ملفاً أو ضع رابط فيديو آمن مع توضيح حق الاستخدام.'),
      const SizedBox(height:16),
      Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        TextField(controller:title,maxLength:180,
          decoration:const InputDecoration(labelText:'عنوان المادة')),
        const SizedBox(height:10),
        TextField(controller:subject,maxLength:100,
          decoration:const InputDecoration(labelText:'اسم المادة الدراسية')),
        const SizedBox(height:10),
        DropdownButtonFormField<String>(
          initialValue:kind,
          decoration:const InputDecoration(labelText:'نوع المحتوى'),
          items:const [
            DropdownMenuItem(value:'book',child:Text('كتاب')),
            DropdownMenuItem(value:'handout',child:Text('ملزمة / ورقة عمل')),
            DropdownMenuItem(value:'video',child:Text('فيديو')),
            DropdownMenuItem(value:'lesson',child:Text('درس / محتوى تفاعلي')),
          ],onChanged:(v)=>setState(()=>kind=v??'book')),
        const SizedBox(height:10),
        DropdownButtonFormField<int>(
          initialValue:grade,isExpanded:true,
          decoration:const InputDecoration(labelText:'الصف الدراسي'),
          items:List.generate(12,(i)=>DropdownMenuItem(value:i+1,
            child:Text(LessonCatalog.gradeName(i+1)))),
          onChanged:(v)=>setState(() {
            grade=v??1;branch=LessonCatalog.tracksFor(grade).first;
          })),
        if(grade>=11) ...[
          const SizedBox(height:10),
          DropdownButtonFormField<String>(
            key:ValueKey('branch-$grade'),initialValue:branch,
            decoration:const InputDecoration(labelText:'الفرع'),
            items:LessonCatalog.tracksFor(grade)
              .map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
            onChanged:(v)=>setState(()=>branch=v??'علمي')),
        ],
        const SizedBox(height:10),
        TextField(controller:summary,maxLines:3,
          decoration:const InputDecoration(labelText:'ملخص المادة')),
        const SizedBox(height:10),
        OutlinedButton.icon(
          onPressed:pick,icon:const Icon(Icons.upload_file_rounded),
          label:Text(fileName.isEmpty?'اختيار PDF أو فيديو أو صورة':fileName)),
        const SizedBox(height:10),
        TextField(controller:link,
          keyboardType:TextInputType.url,
          decoration:const InputDecoration(
            labelText:'رابط HTTPS (بديل للملف)',
            prefixIcon:Icon(Icons.link))),
        const SizedBox(height:10),
        TextField(controller:rights,maxLines:3,minLines:2,
          decoration:const InputDecoration(
            labelText:'مصدر المادة وتفاصيل حقوق الاستخدام',
            hintText:'مثلاً: عمل أصلي من تأليفي أو لدي تصريح إعادة نشر')),
        const SizedBox(height:16),
        FilledButton.icon(onPressed:sending?null:send,
          icon:const Icon(Icons.send_rounded),
          label:Text(sending?'جارٍ الإرسال...':'إرسال للمراجعة')),
      ])),
    ])),
  );
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key,required this.onSignOut});
  final Future<void> Function() onSignOut;
  @override
  State<AdminDashboard> createState()=>_AdminDashboardState();
}
class _AdminDashboardState extends State<AdminDashboard> {
  late Future<List<List<Map<String,dynamic>>>> pending;
  void refresh()=>pending=Future.wait([
    PortalService.instance.pending('paledu_role_requests'),
    PortalService.instance.pending('paledu_resources'),
  ]);
  @override
  void initState(){super.initState();refresh();}
  Future<void> decide(String id,bool yes,bool educator) async {
    try {
      if(educator) {
        await PortalService.instance.reviewEducator(id,yes);
      } else {
        await PortalService.instance.reviewResource(id,yes);
      }
      if(mounted)setState(refresh);
    } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('لم تُنفذ العملية؛ تحقق من الإذن أو الحقوق أو حالة الطلب')));
    }
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('مركز قيادة PalEdu'),actions:[
      IconButton(tooltip:'تحديث البيانات',onPressed:()=>setState(refresh),
        icon:const Icon(Icons.refresh)),
      IconButton(tooltip:'تسجيل الخروج',onPressed:widget.onSignOut,
        icon:const Icon(Icons.logout)),
    ]),
    body:_page(ListView(padding:const EdgeInsets.all(20),children:[
      Container(padding:const EdgeInsets.all(25),
        decoration:BoxDecoration(
          gradient:const LinearGradient(
            colors:[PColors.midnight,PColors.royal,Color(0xFF087D88)]),
          borderRadius:BorderRadius.circular(27)),
        child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Icon(Icons.admin_panel_settings_rounded,color:PColors.gold,size:42),
          SizedBox(height:12),
          Text('الإدارة والتحكم المركزي',style:TextStyle(
            fontSize:25,fontWeight:FontWeight.w900,color:Colors.white)),
          SizedBox(height:8),
          Text('طلبات المعلمين • مراجعة المناهج • حقوق النشر',
            style:TextStyle(color:Colors.white)),
        ])),
      const SizedBox(height:21),
      FutureBuilder<List<List<Map<String,dynamic>>>>(
        future:pending,builder:(context,snapshot){
          if(snapshot.hasError) return const Panel(
            child:Text('تعذّر تحميل الطلبات، جرّب التحديث.'));
          if(!snapshot.hasData) return const Center(
            child:CircularProgressIndicator());
          final roles=snapshot.data![0], resources=snapshot.data![1];
          return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              Expanded(child:Panel(child:Column(children:[
                const Icon(Icons.person_add_alt_1_rounded,color:PColors.teal),
                const SizedBox(height:8),
                Text(roles.length.toString(),style:const TextStyle(
                  fontSize:29,fontWeight:FontWeight.w900)),
                const Text('طلبات مدرسين'),
              ]))),
              const SizedBox(width:11),
              Expanded(child:Panel(child:Column(children:[
                const Icon(Icons.library_books_rounded,color:PColors.teal),
                const SizedBox(height:8),
                Text(resources.length.toString(),style:const TextStyle(
                  fontSize:29,fontWeight:FontWeight.w900)),
                const Text('مواد للمراجعة'),
              ]))),
            ]),
            const SizedBox(height:20),
            const Text('طلبات اعتماد المعلمين',style:TextStyle(
              fontSize:20,fontWeight:FontWeight.w900)),
            const SizedBox(height:10),
            if(roles.isEmpty) const Panel(child:Text('لا توجد طلبات معلقة')),
            for(final item in roles) _reviewCard(
              title:item['requested_role']=='trainer'?'طلب مدرب':'طلب معلم',
              subtitle:item['statement']?.toString()??'',
              approve:()=>decide(item['request_id'].toString(),true,true),
              reject:()=>decide(item['request_id'].toString(),false,true)),
            const SizedBox(height:21),
            const Text('مراجعة المواد التعليمية',style:TextStyle(
              fontSize:20,fontWeight:FontWeight.w900)),
            const SizedBox(height:10),
            if(resources.isEmpty) const Panel(child:Text('لا توجد مواد بانتظار النشر')),
            for(final item in resources) _reviewCard(
              title:item['title']?.toString()??'',
              subtitle:(item['subject']?.toString()??'')+
                ' • حقوق: '+(item['rights_note']?.toString()??''),
              approve:()=>decide(item['resource_id'].toString(),true,false),
              reject:()=>decide(item['resource_id'].toString(),false,false)),
            const SizedBox(height:15),
            const Panel(child:Text('أي اعتماد يُفحص مرة ثانية داخل قاعدة البيانات، ويُسجل في سجل العمليات.')),
          ]);
        }),
    ])),
  );
  Widget _reviewCard({required String title,required String subtitle,
    required VoidCallback approve,required VoidCallback reject})=>
    Padding(padding:const EdgeInsets.only(bottom:10),
      child:Panel(child:Column(
        crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text(title,style:const TextStyle(
            fontSize:17,fontWeight:FontWeight.w900)),
          const SizedBox(height:7),
          Text(subtitle,maxLines:5),
          const SizedBox(height:12),
          Wrap(spacing:10,children:[
            FilledButton.icon(onPressed:approve,
              icon:const Icon(Icons.check),label:const Text('اعتماد')),
            OutlinedButton.icon(onPressed:reject,
              icon:const Icon(Icons.close),label:const Text('رفض')),
          ]),
        ])));
}

class PublishedLibrary extends StatefulWidget {
  const PublishedLibrary({super.key,required this.grade});
  final int grade;
  @override
  State<PublishedLibrary> createState()=>_PublishedLibraryState();
}
class _PublishedLibraryState extends State<PublishedLibrary> {
  late Future<List<Map<String,dynamic>>> future;
  String query='',kind='all';
  @override
  void initState() {
    super.initState();future=PortalService.instance.published(widget.grade);
  }
  Future<void> open(Map<String,dynamic> item) async {
    try {
      final link=await PortalService.instance.accessUrl(item);
      final uri=Uri.tryParse(link);
      if(uri==null || uri.scheme!='https' ||
        !await launchUrl(uri,mode:LaunchMode.externalApplication)) {
        throw StateError('Cannot open');
      }
    } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('لا يمكن فتح المادة حالياً؛ حاول لاحقاً')));
    }
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('مكتبة المناهج والموارد')),
    body:_page(ListView(padding:const EdgeInsets.all(20),children:[
      Text('مكتبة الصف '+widget.grade.toString(),
        style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),
      const SizedBox(height:8),
      TextField(onChanged:(v)=>setState(()=>query=v),
        decoration:const InputDecoration(labelText:'ابحث باسم المادة أو الكتاب',
          prefixIcon:Icon(Icons.search))),
      const SizedBox(height:11),
      Wrap(spacing:8,children:[
        for(final entry in const {'all':'الكل','book':'الكتب',
          'handout':'الملازم','video':'الفيديو','lesson':'الدروس'}.entries)
          ChoiceChip(label:Text(entry.value),selected:kind==entry.key,
            onSelected:(_)=>setState(()=>kind=entry.key)),
      ]),
      const SizedBox(height:15),
      FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(context,snapshot){
        if(snapshot.hasError) return const Panel(
          child:Text('تعذر تحميل المكتبة. تحقق من الاتصال والصلاحيات.'));
        if(!snapshot.hasData) return const Center(child:CircularProgressIndicator());
        final list=snapshot.data!.where((item)=>
          (kind=='all'||item['kind']==kind) &&
          ((item['title']?.toString()??'').contains(query) ||
          (item['subject']?.toString()??'').contains(query))).toList();
        if(list.isEmpty) return const Panel(
          child:Text('لا توجد مواد منشورة لهذا الصف أو البحث بعد.'));
        return Column(children:[
          for(final item in list)
            Padding(padding:const EdgeInsets.only(bottom:9),
              child:Panel(child:ListTile(
                leading:Icon(item['kind']=='video'?
                  Icons.play_circle_outline:Icons.book_rounded,
                  color:PColors.teal,size:34),
                title:Text(item['title']?.toString()??''),
                subtitle:Text(item['subject']?.toString()??''),
                trailing:const Icon(Icons.open_in_new),
                onTap:()=>open(item)))),
        ]);
      }),
    ])),
  );
}
