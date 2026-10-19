import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models.dart';
import '../state/student_state.dart';
import '../ui/design.dart';
import '../main.dart' show HomeShell, SetupScreen;
import 'portal_service.dart';
import 'portal_studio.dart';

class PortalGateway extends StatefulWidget {
  const PortalGateway({super.key,required this.student,
    required this.catalog, required this.preview});
  final StudentState student;
  final LessonCatalog catalog;
  final Widget Function() preview;
  @override
  State<PortalGateway> createState()=>_PortalGatewayState();
}

class _PortalGatewayState extends State<PortalGateway> {
  StreamSubscription<AuthState>? subscription;
  Future<Map<String,dynamic>>? currentProfile;
  @override
  void initState() {
    super.initState();
    if (PortalConfig.enabled) {
      subscription=Supabase.instance.client.auth.onAuthStateChange.listen((_) {
        if (mounted) setState(() {
          currentProfile=PortalService.instance.user==null
            ? null : PortalService.instance.profile();
        });
      });
      if (PortalService.instance.user!=null) {
        currentProfile=PortalService.instance.profile();
      }
    }
  }
  @override
  void dispose() { subscription?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (PortalConfig.enabled && PortalService.instance.user!=null) {
      return FutureBuilder<Map<String,dynamic>>(
        future: currentProfile ??= PortalService.instance.profile(),
        builder: (context,snapshot) {
          if (snapshot.hasError) return Scaffold(
            appBar: AppBar(title:const Text('تعذّر تحميل الصلاحيات')),
            body: Center(child: Column(mainAxisSize:MainAxisSize.min,
              children:[
                const Text('راجع إعداد قاعدة البيانات واتصالك بالشبكة.'),
                FilledButton(onPressed:()=>setState(() =>
                  currentProfile=PortalService.instance.profile()),
                  child:const Text('إعادة المحاولة')),
                TextButton(onPressed:()=>PortalService.instance.db.auth.signOut(),
                  child:const Text('تسجيل الخروج')),
              ])));
          if (!snapshot.hasData) return const Scaffold(
            body:Center(child:CircularProgressIndicator()));
          final profile=snapshot.data!;
          final role=profile['role'] as String? ?? 'student';
          if (role=='admin') return AdminDashboard(
            onSignOut: ()=>PortalService.instance.db.auth.signOut());
          if (role=='teacher' || role=='trainer') return TeacherStudio(
            role:role,onSignOut:()=>PortalService.instance.db.auth.signOut());
          return StudentCloudHub(
            student:widget.student,catalog:widget.catalog,
            onSignOut:()=>PortalService.instance.db.auth.signOut());
        });
    }
    return PortalWelcome(student:widget.student,catalog:widget.catalog);
  }
}

class PortalWelcome extends StatelessWidget {
  const PortalWelcome({super.key,required this.student,required this.catalog});
  final StudentState student;
  final LessonCatalog catalog;
  @override
  Widget build(BuildContext context)=>Scaffold(
    body:SafeArea(child:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:880),
      child:ListView(padding:const EdgeInsets.all(22),children:[
        Container(padding:const EdgeInsets.all(25),
          decoration:BoxDecoration(
            gradient:const LinearGradient(
              colors:[PColors.midnight,PColors.royal,Color(0xFF087E83)]),
            borderRadius:BorderRadius.circular(30)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Icon(Icons.auto_stories_rounded,color:PColors.gold,size:52),
            const SizedBox(height:16),
            const Text('PalEdu | تعلّم فلسطين',
              style:TextStyle(color:Colors.white,fontSize:28,
                fontWeight:FontWeight.w900)),
            const SizedBox(height:8),
            const Text('منصة تعلّم متكاملة، تبدأ من أول درس وتمتد إلى التوجيهي.',
              style:TextStyle(color:Colors.white,fontSize:16)),
            const SizedBox(height:14),
            const Text('تعلّم • تدرّب • ابتكر',
              style:TextStyle(color:PColors.gold,
                fontWeight:FontWeight.bold)),
          ])),
        const SizedBox(height:27),
        Text('اختر طريقة الدخول',style:Theme.of(context)
          .textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),
        const SizedBox(height:12),
        _role(context,Icons.school_rounded,'طالب',
          'مناهج ودروس وكتب واختبارات وألعاب ومتابعة تقدّم'),
        _role(context,Icons.co_present_rounded,'مدرس أو مدرب',
          'استوديو إنشاء الدروس ورفع الكتب والفيديوهات'),
        _role(context,Icons.admin_panel_settings_rounded,'مدير المنصة',
          'اعتماد المعلمين وإدارة ونشر المحتوى'),
        const SizedBox(height:9),
        if (!PortalConfig.enabled) ...[
          const Panel(child:Text('خدمة الحسابات لم تُربط بخادم بعد. يمكنك تجربة دروس الطالب دون تسجيل لحين إعداد قاعدة البيانات.')),
          const SizedBox(height:14),
        ],
        FilledButton.icon(onPressed:()=>Navigator.push(context,
          MaterialPageRoute<void>(builder:(_)=>OfflineLearning(
            student:student,catalog:catalog))),
          icon:const Icon(Icons.explore_outlined),
          label:const Text('معاينة تعليمية دون حساب')),
        const SizedBox(height:12),
        const Text('لا توجد صلاحيات إدارية محلية أو كلمة مرور افتراضية.',
          textAlign:TextAlign.center,style:TextStyle(fontSize:12)),
      ])))),
  );
  Widget _role(BuildContext context,IconData icon,String title,String subtitle)=>
    Padding(padding:const EdgeInsets.only(bottom:10),child:Panel(
      child:Row(children:[
        Container(height:54,width:54,
          decoration:BoxDecoration(color:PColors.mint,
            borderRadius:BorderRadius.circular(17)),
          child:Icon(icon,color:PColors.midnight,size:29)),
        const SizedBox(width:14),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Text(title,style:const TextStyle(
              fontWeight:FontWeight.w900,fontSize:17)),
            Text(subtitle,style:const TextStyle(fontSize:12)),
          ])),
        IconButton(
          tooltip:'تسجيل الدخول',
          icon:Icon(Icons.arrow_back_ios_new_rounded,
            color:PortalConfig.enabled?PColors.teal:Colors.grey),
          onPressed:PortalConfig.enabled
            ? ()=>Navigator.push(context,MaterialPageRoute<void>(
                builder:(_)=>PortalLogin(roleLabel:title)))
            : null),
      ])));
}

class OfflineLearning extends StatelessWidget {
  const OfflineLearning({super.key,required this.student,required this.catalog});
  final StudentState student;
  final LessonCatalog catalog;
  @override
  Widget build(BuildContext context)=>AnimatedBuilder(
    animation:student,builder:(context,_)=>student.configured
      ? HomeShell(student:student,catalog:catalog)
      : SetupScreen(student:student));
}

class PortalLogin extends StatefulWidget {
  const PortalLogin({super.key,required this.roleLabel});
  final String roleLabel;
  @override
  State<PortalLogin> createState()=>_PortalLoginState();
}
class _PortalLoginState extends State<PortalLogin> {
  final key=GlobalKey<FormState>();
  final email=TextEditingController();
  final password=TextEditingController();
  final name=TextEditingController();
  bool register=false,loading=false,hidden=true;
  String? notice;
  @override
  void dispose() {
    email.dispose(); password.dispose(); name.dispose(); super.dispose();
  }
  Future<void> submit() async {
    if (!key.currentState!.validate() || loading) return;
    setState(()=>loading=true);
    try {
      if (register) {
        await PortalService.instance.register(email.text,password.text,name.text);
        if (mounted) setState(() {
          register=false;
          notice='راجع بريدك الإلكتروني لتأكيد الحساب، ثم سجل الدخول.';
        });
      } else {
        await PortalService.instance.signIn(email.text,password.text);
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) setState(() =>
        notice='تعذّر تنفيذ الطلب. تحقق من البيانات والاتصال أو حاول لاحقاً.');
    } finally {
      if (mounted) setState(()=>loading=false);
    }
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(register?'حساب طالب جديد':'دخول '+widget.roleLabel)),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:500),
      child:ListView(padding:const EdgeInsets.all(24),children:[
        const SizedBox(height:15),
        const Center(child:CircleAvatar(radius:42,
          backgroundColor:PColors.mint,
          child:Icon(Icons.lock_person_rounded,color:PColors.midnight,size:43))),
        const SizedBox(height:14),
        Text(register?'ابدأ رحلتك التعليمية':'مرحباً بعودتك',
          textAlign:TextAlign.center,style:const TextStyle(
            fontSize:25,fontWeight:FontWeight.w900)),
        const SizedBox(height:20),
        Form(key:key,child:Column(children:[
          if (register) ...[
            TextFormField(controller:name,
              decoration:const InputDecoration(
                labelText:'الاسم الظاهر',prefixIcon:Icon(Icons.person)),
              validator:(v)=>v==null||v.trim().length<2?'اكتب اسماً':null),
            const SizedBox(height:12),
          ],
          TextFormField(controller:email,
            keyboardType:TextInputType.emailAddress,
            autofillHints:const [AutofillHints.email],
            decoration:const InputDecoration(labelText:'البريد الإلكتروني',
              prefixIcon:Icon(Icons.alternate_email)),
            validator:(v)=>v==null||!v.contains('@')?'أدخل بريدك':null),
          const SizedBox(height:12),
          TextFormField(controller:password,obscureText:hidden,
            autofillHints:const [AutofillHints.password],
            decoration:InputDecoration(labelText:'كلمة المرور',
              prefixIcon:const Icon(Icons.lock_outline),
              suffixIcon:IconButton(
                onPressed:()=>setState(()=>hidden=!hidden),
                icon:Icon(hidden?Icons.visibility:Icons.visibility_off))),
            validator:(v)=>v==null||v.length<8?'8 أحرف على الأقل':null),
        ])),
        const SizedBox(height:17),
        if (notice!=null) ...[
          Panel(child:Text(notice!)),
          const SizedBox(height:10),
        ],
        FilledButton(onPressed:loading?null:submit,
          child:loading?const CircularProgressIndicator()
            :Text(register?'إنشاء حساب طالب':'تسجيل الدخول')),
        const SizedBox(height:9),
        TextButton(onPressed:()=>setState(() {
          register=!register;notice=null;
        }),child:Text(register?'لدي حساب بالفعل':'ليس لديك حساب؟ سجّل كطالب')),
        const SizedBox(height:12),
        const Text('صلاحيات المعلم والمدير لا تمنح بالتسجيل الذاتي. يدقق المدير في طلبات الاعتماد.',
          textAlign:TextAlign.center,style:TextStyle(fontSize:12)),
      ]))),
  );
}

class StudentCloudHub extends StatelessWidget {
  const StudentCloudHub({super.key,required this.student,
    required this.catalog,required this.onSignOut});
  final StudentState student;
  final LessonCatalog catalog;
  final Future<void> Function() onSignOut;
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('بوابة الطالب'),
      actions:[IconButton(tooltip:'تسجيل الخروج',
        onPressed:onSignOut,icon:const Icon(Icons.logout))]),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:880),
      child:ListView(padding:const EdgeInsets.all(22),children:[
        Container(padding:const EdgeInsets.all(24),
          decoration:BoxDecoration(
            gradient:const LinearGradient(
              colors:[PColors.midnight,PColors.royal]),
            borderRadius:BorderRadius.circular(28)),
          child:const Column(crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Icon(Icons.school_rounded,color:PColors.gold,size:37),
              SizedBox(height:12),
              Text('رحلتك التعليمية الخاصة',
                style:TextStyle(color:Colors.white,
                  fontSize:25,fontWeight:FontWeight.w900)),
              SizedBox(height:7),
              Text('مكتبة المناهج، مواد المعلمين، الدروس والألعاب',
                style:TextStyle(color:Colors.white)),
            ])),
        const SizedBox(height:19),
        Panel(child:ListTile(
          leading:const Icon(Icons.library_books_rounded,color:PColors.teal),
          title:const Text('مكتبة الكتب والملازم والفيديوهات'),
          subtitle:const Text('مواد راجعها واعتمدها مدير المنصة'),
          trailing:const Icon(Icons.chevron_left),
          onTap:()=>Navigator.push(context,MaterialPageRoute<void>(
            builder:(_)=>PublishedLibrary(grade:student.grade)))),
        const SizedBox(height:10),
        Panel(child:ListTile(
          leading:const Icon(Icons.emoji_events,color:PColors.teal),
          title:const Text('التعلّم التفاعلي'),
          subtitle:const Text('الدروس والاختبارات والمراجعات والألعاب'),
          trailing:const Icon(Icons.chevron_left),
          onTap:()=>Navigator.push(context,MaterialPageRoute<void>(
            builder:(_)=>OfflineLearning(student:student,catalog:catalog)))),
        const SizedBox(height:10),
        Panel(child:ListTile(
          leading:const Icon(Icons.co_present_rounded,color:PColors.teal),
          title:const Text('طلب اعتماد معلم أو مدرب'),
          subtitle:const Text('تتم مراجعة الطلب قبل تفعيل الصلاحيات'),
          trailing:const Icon(Icons.chevron_left),
          onTap:()=>Navigator.push(context,MaterialPageRoute<void>(
            builder:(_)=>const EducatorRequestPage()))),
      ]))),
  );
}

class EducatorRequestPage extends StatefulWidget {
  const EducatorRequestPage({super.key});
  @override
  State<EducatorRequestPage> createState()=>_EducatorRequestPageState();
}
class _EducatorRequestPageState extends State<EducatorRequestPage> {
  final description=TextEditingController();
  String role='teacher';
  bool sending=false;
  @override
  void dispose(){description.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('طلب اعتماد تربوي')),
    body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:600),
      child:ListView(padding:const EdgeInsets.all(22),children:[
        const Text('شارك تخصصك وخبرتك وسيُراجع المدير طلبك.',
          style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
        const SizedBox(height:15),
        DropdownButtonFormField<String>(
          initialValue:role,
          items:const [
            DropdownMenuItem(value:'teacher',child:Text('معلم')),
            DropdownMenuItem(value:'trainer',child:Text('مدرب')),
          ],onChanged:(v)=>setState(()=>role=v??'teacher')),
        const SizedBox(height:12),
        TextField(controller:description,maxLines:5,
          decoration:const InputDecoration(labelText:'الخبرة والتخصص')),
        const SizedBox(height:15),
        FilledButton(onPressed:sending?null:() async {
          setState(()=>sending=true);
          try {
            await PortalService.instance.requestEducator(description.text,role);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content:Text('تم إرسال الطلب للمراجعة')));
              Navigator.pop(context);
            }
          } catch (_) {
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content:Text('تحقق من البيانات، أو من وجود طلب معلق')));
          } finally {if (mounted)setState(()=>sending=false);}
        },child:const Text('إرسال للمراجعة')),
      ])))),
  );
}
