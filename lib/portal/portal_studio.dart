import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/media_favourites.dart';
import '../data/resource_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../ui/internal_pdf_reader.dart';
import '../ui/internal_video_player.dart';
import '../ui/internal_image_viewer.dart';
import '../data/resource_media.dart';
import '../data/models.dart';
import '../ui/design.dart';
import '../ui/royal_portal_components.dart';
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
      RoyalPortalBanner(
        icon:Icons.co_present_rounded,
        title:widget.role=='trainer'?'استوديو المدرب':'استوديو المعلم',
        subtitle:'أنشئ المحتوى وتابع حالة مراجعته قبل نشره للطلاب.',
        actionLabel:'إنشاء محتوى جديد',
        onAction:() async {
          await Navigator.push(context,MaterialPageRoute<void>(
            builder:(_)=>const ResourceComposer()));
          if(mounted)setState(refresh);
        }),
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
          if (list.isEmpty) return const RoyalEmptyState(
            title:'لا توجد مواد بعد',
            message:'اضغط إضافة محتوى لبدء إنشاء أول درس أو كتاب أو فيديو.');
          return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const RoyalSectionHeading(
              title:'إحصاءات المحتوى',subtitle:'ضمن آخر 100 مادة تم تحميلها'),
            const SizedBox(height:12),
            RoyalMetricsGrid(metrics:[
              RoyalMetricTile(label:'إجمالي المواد',
                value:list.length.toString(),icon:Icons.auto_stories_rounded),
              RoyalMetricTile(label:'منشورة',
                value:list.where((x)=>x['status']=='published').length.toString(),
                icon:Icons.verified_rounded,color:PColors.royal),
              RoyalMetricTile(label:'بانتظار المراجعة',
                value:list.where((x)=>x['status']=='pending').length.toString(),
                icon:Icons.schedule_rounded,color:PColors.orange),
              RoyalMetricTile(label:'مسودات ومرفوضة',
                value:list.where((x)=>x['status']=='draft'||x['status']=='rejected').length.toString(),
                icon:Icons.edit_note_rounded,color:PColors.blue),
            ]),
            const SizedBox(height:17),
            const RoyalSectionHeading(title:'المحتويات التي أضفتها'),
            const SizedBox(height:12),
            for(final item in list) Padding(
              padding:const EdgeInsets.only(bottom:10),
              child:RoyalAuthorResourceCard(
                title:item['title']?.toString()??'بدون عنوان',
                subject:item['subject']?.toString()??'',
                grade:item['grade']?.toString()??'-',
                kind:item['kind']?.toString()??'',
                status:item['status']?.toString()??'')),
          ]);
        }),
      const SizedBox(height:15),
      const Panel(child:Text('أي مادة يرفعها المعلم لا تظهر للطلاب حتى يعتمدها المدير ويُراجع حقوق استخدامها.')),
    ])),
  );
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
  int grade=1,semester=1;
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
        allowedExtensions:ResourceMedia.extensions[kind]!,
        withData:true);
      if(result==null) return;
      final file=result.files.single;
      if(file.size>50*1024*1024) throw ArgumentError('Large file');
      if(!ResourceMedia.acceptsFile(kind,file.name)) throw ArgumentError('Unsupported format');
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
        kind:kind,grade:grade,branch:branch,semester:semester,
        rights:rights.text,
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
          ],onChanged:(v)=>setState((){
            kind=v??'book';
            bytes=null;fileName='';
          })),
        const SizedBox(height:8),
        Text(ResourceMedia.description(kind),
          style:TextStyle(fontSize:12,
            color:Theme.of(context).colorScheme.onSurfaceVariant)),
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
        DropdownButtonFormField<int>(
          initialValue:semester,
          decoration:const InputDecoration(labelText:'الفصل الدراسي'),
          items:const [
            DropdownMenuItem(value:1,child:Text('الفصل الدراسي الأول')),
            DropdownMenuItem(value:2,child:Text('الفصل الدراسي الثاني')),
          ],
          onChanged:(v)=>setState(()=>semester=v??1)),
        const SizedBox(height:10),
        TextField(controller:summary,maxLines:3,
          decoration:const InputDecoration(labelText:'ملخص المادة')),
        const SizedBox(height:10),
        OutlinedButton.icon(
          onPressed:pick,icon:const Icon(Icons.upload_file_rounded),
          label:Text(fileName.isEmpty?'اختيار ملف '+ResourceMedia.description(kind):fileName)),
        const SizedBox(height:10),
        TextField(controller:link,
          keyboardType:TextInputType.url,
          decoration:const InputDecoration(
            labelText:'رابط HTTPS مباشر مطابق لنوع المحتوى (بديل للملف)',
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
  final Set<String> busy=<String>{};
  Future<void> decide(String id,bool yes,bool educator) async {
    if(busy.contains(id))return;
    final approved=await showDialog<bool>(context:context,
      builder:(ctx)=>AlertDialog(
        title:Text(yes?'تأكيد الاعتماد':'تأكيد الرفض'),
        content:Text(yes
          ? 'هل راجعت بيانات الطلب ومصدر المحتوى وحقوق الاستخدام؟'
          : 'هل تريد رفض هذا الطلب؟'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:const Text('إلغاء')),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:Text(yes?'تأكيد الاعتماد':'تأكيد الرفض')),
        ]));
    if(approved!=true||!mounted)return;
    setState(()=>busy.add(id));
    try {
      if(educator) {
        await PortalService.instance.reviewEducator(id,yes);
      } else {
        await PortalService.instance.reviewResource(id,yes);
      }
      if(mounted) {
        setState(refresh);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:Text(yes?'تم اعتماد الطلب':'تم رفض الطلب')));
      }
    } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text(
          'لم تُنفذ العملية؛ تحقق من الإذن أو الحقوق أو حالة الطلب')));
    } finally {
      if(mounted)setState(()=>busy.remove(id));
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
      const RoyalPortalBanner(
        icon:Icons.admin_panel_settings_rounded,
        title:'القيادة والإدارة المركزية',
        subtitle:'اعتماد المعلمين ومراجعة المناهج والمواد وحقوق نشرها.',
      ),
      const SizedBox(height:21),
      FutureBuilder<List<List<Map<String,dynamic>>>>(
        future:pending,builder:(context,snapshot){
          if(snapshot.hasError) return const Panel(
            child:Text('تعذّر تحميل الطلبات، جرّب التحديث.'));
          if(!snapshot.hasData) return const Center(
            child:CircularProgressIndicator());
          final roles=snapshot.data![0], resources=snapshot.data![1];
          return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            RoyalMetricsGrid(metrics:[
              RoyalMetricTile(label:'طلبات اعتماد المدرسين',
                value:roles.length.toString(),
                icon:Icons.co_present_rounded,color:PColors.blue),
              RoyalMetricTile(label:'مواد بانتظار المراجعة',
                value:resources.length.toString(),
                icon:Icons.library_books_rounded,color:PColors.orange),
            ]),
            const SizedBox(height:20),
            const Text('طلبات اعتماد المعلمين',style:TextStyle(
              fontSize:20,fontWeight:FontWeight.w900)),
            const SizedBox(height:10),
            if(roles.isEmpty) const RoyalEmptyState(
              title:'لا توجد طلبات معلمين',
              message:'ستظهر طلبات اعتماد المدرسين والمدربين هنا.'),
            for(final item in roles) _reviewCard(
              title:item['requested_role']=='trainer'?'طلب مدرب':'طلب معلم',
              subtitle:item['statement']?.toString()??'',
              approve:()=>decide(item['request_id'].toString(),true,true),
              reject:()=>decide(item['request_id'].toString(),false,true)),
            const SizedBox(height:21),
            const Text('مراجعة المواد التعليمية',style:TextStyle(
              fontSize:20,fontWeight:FontWeight.w900)),
            const SizedBox(height:10),
            if(resources.isEmpty) const RoyalEmptyState(
              title:'لا توجد مواد للمراجعة',
              message:'المواد الجديدة قيد الاعتماد ستظهر هنا.'),
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
      child:RoyalApprovalCard(title:title,description:subtitle,
        onApprove:approve,onReject:reject));

}

class PublishedLibrary extends StatefulWidget {
  const PublishedLibrary({super.key,required this.grade,this.branch='عام'});
  final int grade;
  final String branch;
  @override
  State<PublishedLibrary> createState()=>_PublishedLibraryState();
}
class _PublishedLibraryState extends State<PublishedLibrary> {
  late Future<List<Map<String,dynamic>>> future;
  String query='',kind='all',semesterFilter='all';
  bool onlySaved=false;
  Set<String> savedIds=<String>{};
  MediaFavourites? favouriteStore;

  Future<void> loadFavourites() async {
    final userId=PortalService.instance.user?.id;
    if(userId==null)return;
    final prefs=await SharedPreferences.getInstance();
    if(!mounted)return;
    final store=MediaFavourites(prefs,userId:userId);
    setState((){
      favouriteStore=store;
      savedIds=store.getAll();
    });
  }

  Future<void> toggleFavourite(String id) async {
    final store=favouriteStore;
    if(store==null)return;
    try{
      await store.toggle(id);
      if(mounted)setState(()=>savedIds=store.getAll());
    }catch(_){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('تعذّر حفظ المادة، حاول مرة أخرى.')));
    }
  }
  @override
  void initState() {
    super.initState();refresh();loadFavourites();
  }
  void refresh()=>future=PortalService.instance.published(widget.grade);
  Future<void> open(Map<String,dynamic> item) async {
    try {
      final link=await PortalService.instance.accessUrl(item);
      if(!mounted)return;
      final name=item['title']?.toString()??'مادة تعليمية';
      final id=item['resource_id']?.toString()??link;
      final format=ResourceMedia.forResource(item);
      if(format==null){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:Text('نوع هذا المورد غير مدعوم للعرض داخل التطبيق.')));
        return;
      }
      await Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>
        switch(format){
          ResourceFormat.video=>InternalVideoPlayer(title:name,url:link,resourceId:id),
          ResourceFormat.image=>InternalImageViewer(title:name,url:link),
          ResourceFormat.pdf=>InternalPdfReader(
            title:name,url:link,documentId:id),
        }));
    } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('لا يمكن فتح المادة حالياً؛ تحقق من الاتصال والصلاحيات')));
    }
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('مكتبة المناهج والموارد'),
      actions:[IconButton(tooltip:'تحديث الموارد',
        icon:const Icon(Icons.refresh_rounded),
        onPressed:()=>setState(refresh))]),
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
      const SizedBox(height:12),
      Wrap(spacing:8,runSpacing:7,children:[
        for(final option in const [
          ('all','كلا الفصلين'),('1','الفصل الأول'),('2','الفصل الثاني')
        ])
          ChoiceChip(label:Text(option.$2),
            selected:semesterFilter==option.$1,
            onSelected:(_)=>setState(()=>semesterFilter=option.$1)),
      ]),
      const SizedBox(height:8),
      Wrap(spacing:8,runSpacing:6,children:[
        FilterChip(
          avatar:const Icon(Icons.bookmark_rounded,size:17),
          label:Text('مفضلتي ('+savedIds.length.toString()+')'),
          selected:onlySaved,
          onSelected:(value)=>setState(()=>onlySaved=value)),
        if(favouriteStore==null)
          const Padding(padding:EdgeInsets.symmetric(vertical:8),
            child:Text('تسجيل الدخول مطلوب لحفظ المفضلة.',
              style:TextStyle(fontSize:11))),
      ]),
      const SizedBox(height:15),
      FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(context,snapshot){
        if(snapshot.hasError) return const Panel(
          child:Text('تعذر تحميل المكتبة. تحقق من الاتصال والصلاحيات.'));
        if(!snapshot.hasData) return const Center(child:CircularProgressIndicator());
        final list=snapshot.data!.where((item)=>
          (!onlySaved||savedIds.contains(item['resource_id']?.toString())) &&
          (kind=='all'||item['kind']==kind) &&
          (semesterFilter=='all'||item['semester']==null||
             item['semester']==int.tryParse(semesterFilter)) &&
          (widget.grade<=10||widget.branch=='عام'||
            item['branch']==widget.branch||item['branch']=='عام') &&
          matchesResourceSearch(item, query)).toList();
        if(list.isEmpty) return Panel(child:Text(onlySaved
          ?'لا توجد مواد محفوظة تطابق البحث. افتح عرض الكل وأضف كتبك أو فيديوهاتك المفضلة.'
          :'لا توجد مواد منشورة لهذا الصف أو البحث بعد.'));
        return Column(children:[
          for(final item in list)
            Padding(padding:const EdgeInsets.only(bottom:9),
              child:Panel(child:ListTile(
                leading:Icon(
                  item['kind']=='video'?Icons.play_circle_outline_rounded:
                  item['kind']=='handout'?Icons.description_outlined:
                  item['kind']=='lesson'?Icons.school_outlined:
                  Icons.menu_book_rounded,
                  color:PColors.teal,size:34),
                title:Text(item['title']?.toString()??''),
                subtitle:Text((item['subject']?.toString()??'')+
                  (item['semester']==null?'':' • الفصل '+item['semester'].toString())+
                  ' • '+ResourceMedia.description(item['kind']?.toString()??'')),
                trailing:IconButton(
                  tooltip:savedIds.contains(item['resource_id']?.toString())
                    ?'إزالة من مفضلتي':'حفظ في مفضلتي',
                  onPressed:favouriteStore==null?null:()=>
                    toggleFavourite(item['resource_id']?.toString()??''),
                  icon:Icon(
                    savedIds.contains(item['resource_id']?.toString())
                      ?Icons.bookmark_rounded:Icons.bookmark_outline_rounded,
                    color:PColors.teal)),
                onTap:()=>open(item)))),
        ]);
      }),
    ])),
  );
}
