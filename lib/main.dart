import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/models.dart';
import 'state/student_state.dart';
import 'ui/design.dart';
import 'ui/royal_motion.dart';
import 'ui/paledu_brand.dart';
import 'ui/royal_student_home.dart';
import 'ui/royal_achievements.dart';
import 'ui/royal_mistake_notebook.dart';
import 'ui/royal_subject_library.dart';
import 'ui/royal_lesson_reader.dart';
import 'portal/portal_service.dart';
import 'portal/portal_gateway.dart';
import 'portal/official_sources.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final json = await rootBundle.loadString('assets/curriculum/sample_lessons.json');
  if (PortalConfig.enabled) {
    await Supabase.initialize(url:PortalConfig.url,anonKey:PortalConfig.key);
  }
  runApp(PalEduApp(student: StudentState(prefs), catalog: LessonCatalog.parse(json)));
}

class PalEduApp extends StatelessWidget {
  const PalEduApp({super.key, required this.student, required this.catalog});
  final StudentState student;
  final LessonCatalog catalog;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: student,
    builder: (context, _) => MaterialApp(
      title: 'تعلّم فلسطين',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'PS'),
      theme: palTheme(false), darkTheme: palTheme(true),
      themeMode: student.darkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(student.scale)),
          child: child ?? const SizedBox.shrink(),
        )),
      home: PortalGateway(student:student,catalog:catalog,
        preview: () => student.configured
          ? HomeShell(student:student,catalog:catalog)
          : SetupScreen(student:student)),
    ),
  );
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.student, this.edit = false});
  final StudentState student;
  final bool edit;
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}
class _SetupScreenState extends State<SetupScreen> {
  late final TextEditingController name;
  late int grade;
  late String track;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.student.name == 'يا بطل'
        ? '' : widget.student.name);
    grade = widget.student.grade;
    track = widget.student.track;
  }
  @override
  void dispose() { name.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final branches = LessonCatalog.tracksFor(grade);
    if (!branches.contains(track)) track = branches.first;
    return Scaffold(
      appBar: widget.edit ? AppBar(title: const Text('الإعدادات الدراسية')) : null,
      body: safe(ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 24),
        Align(alignment: Alignment.centerRight, child: Container(
          height: 80, width: 80,
          decoration: BoxDecoration(color: PColors.midnight,
            borderRadius: BorderRadius.circular(24)),
          child:const PalEduBrandLogo(size:80,darkTile:true))),
        const SizedBox(height: 24),
        Text('مستقبلك يبدأ هنا', style: Theme.of(context).textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text('تعلّم فلسطين، رحلة تفاعلية من الأول إلى التوجيهي.',
          style: TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('الاسم (اختياري)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: name, maxLength: 40,
              decoration: const InputDecoration(hintText: 'بماذا نناديك؟',
                counterText: '')),
            const SizedBox(height: 14),
            const Text('الصف الدراسي', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              key: ValueKey('grade-$grade'),
              initialValue: grade, isExpanded: true,
              items: List.generate(12, (i) => DropdownMenuItem(
                value: i+1, child: Text(LessonCatalog.gradeName(i+1)))),
              onChanged: (value) => setState(() {
                grade = value ?? 1;
                track = LessonCatalog.tracksFor(grade).first;
              })),
            if (branches.length > 1) ...[
              const SizedBox(height: 14),
              const Text('المسار / الفرع'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey('track-$grade'),
                initialValue: track, isExpanded: true,
                items: branches.map((b) =>
                  DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (value) => setState(() => track=value ?? branches.first)),
            ],
          ])),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: () async {
          await widget.student.configure(name.text, grade, track);
          if (context.mounted && widget.edit) Navigator.pop(context);
        }, icon: const Icon(Icons.arrow_back_rounded),
          label: Text(widget.edit ? 'حفظ' : 'ابدأ رحلتي')),
        const SizedBox(height: 15),
        const Text('لا نطلب بريدك أو رقم هاتفك • التقدم محفوظ على هذا الجهاز',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
      ])),
    );
  }
}

Widget safe(Widget child) => Center(child: ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 900), child: child));

void openLesson(BuildContext context, Lesson l, StudentState s) =>
  Navigator.push(context, MaterialPageRoute<void>(
    builder: (_) => LessonScreen(lesson: l, student: s)));

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.student, required this.catalog});
  final StudentState student;
  final LessonCatalog catalog;
  @override
  State<HomeShell> createState() => _HomeShellState();
}
class _HomeShellState extends State<HomeShell> {
  int tab=0;
  @override
  Widget build(BuildContext context) {
    final s=widget.student;
    final lessons=widget.catalog.forStudent(s.grade, s.track);
    return Scaffold(
      body: SafeArea(child: safe(IndexedStack(index: tab, children: [
        RoyalStudentHome(
          student:s,lessons:lessons,
          onSubjects:()=>setState(()=>tab=1),
          onGames:()=>setState(()=>tab=2),
          onMistakes:()=>Navigator.push(context,
            MaterialPageRoute<void>(builder:(_)=>RoyalMistakeNotebook(
              student:s,lessons:lessons))),
          onAchievements:()=>Navigator.push(context,
            MaterialPageRoute<void>(builder:(_)=>RoyalAchievementsScreen(
              student:s,lessons:lessons,
              onPractice:(){
                Navigator.pop(context);
                if(s.dueCount(lessons.map((l)=>l.id))>0){
                  Navigator.push(context,MaterialPageRoute<void>(
                    builder:(_)=>ReviewScreen(lessons:lessons,student:s)));
                }else {
                  setState(()=>tab=1);
                }
              },
              onSubjects:(){
                Navigator.pop(context);
                setState(()=>tab=1);
              },
            ))),
          onReview:()=>Navigator.push(context,MaterialPageRoute<void>(
            builder:(_)=>ReviewScreen(lessons:lessons,student:s))),
          onOfficialSources:()=>Navigator.push(context,MaterialPageRoute<void>(
            builder:(_)=>const OfficialSourcesScreen())),
          onLesson:(l)=>openLesson(context,l,s)),
        RoyalSubjectLibrary(
          student:s,lessons:lessons,
          onOfficialSources:()=>Navigator.push(context,MaterialPageRoute<void>(
            builder:(_)=>const OfficialSourcesScreen())),
          onLesson:(l)=>openLesson(context,l,s)),
        games(lessons),
        profile(s),
      ]))),
      bottomNavigationBar: NavigationBar(selectedIndex: tab,
        onDestinationSelected: (n) => setState(() => tab=n),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded), label: 'المواد'),
          NavigationDestination(icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports_rounded), label: 'الألعاب'),
          NavigationDestination(icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded), label: 'حسابي'),
        ]),
    );
  }

  Widget games(List<Lesson> lessons) => ListView(
    padding: const EdgeInsets.all(19), children: [
      const Text('مختبر الألعاب', style: TextStyle(
        fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('بطاقات ذاكرة وألعاب مطابقة في كل درس'),
      const SizedBox(height:11),
      Card(child:ListTile(
        leading:const Icon(Icons.psychology_alt_rounded,color:PColors.orange),
        title:const Text('دفتر أخطائي',
          style:TextStyle(fontWeight:FontWeight.w900)),
        subtitle:const Text('تدرّب على أسئلتك الخاطئة من اختبارات الدروس'),
        trailing:const Icon(Icons.chevron_left_rounded),
        onTap:()=>Navigator.push(context,MaterialPageRoute<void>(
          builder:(_)=>RoyalMistakeNotebook(
            student:widget.student,lessons:lessons))))),
      const SizedBox(height: 17),
      for (final lesson in lessons) ...[
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.title, style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(spacing: 9, runSpacing: 9, children: [
              ActionChip(label: const Text('بطاقات المراجعة'),
                avatar: const Icon(Icons.style_rounded, size: 18),
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute<void>(builder: (_) =>
                    FlashPage(lesson: lesson)))),
              ActionChip(label: const Text('لعبة المطابقة'),
                avatar: const Icon(Icons.extension_rounded, size: 18),
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute<void>(builder: (_) =>
                    MatchPage(lesson: lesson)))),
            ]),
          ])),
        const SizedBox(height: 11),
      ],
    ]);

  Widget profile(StudentState s) => ListView(
    padding: const EdgeInsets.all(19), children: [
      const Text('حسابي', style: TextStyle(
        fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 18),
      Panel(child: Column(children: [
        const CircleAvatar(radius: 32, backgroundColor: PColors.mint,
          child: Icon(Icons.person_rounded, size: 36, color: PColors.midnight)),
        const SizedBox(height: 9),
        Text(s.name, style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900)),
        Text(LessonCatalog.gradeName(s.grade) + ' • ' + s.track),
        const SizedBox(height: 9),
        OutlinedButton.icon(onPressed: () => Navigator.push(context,
          MaterialPageRoute<void>(builder: (_) =>
            SetupScreen(student: s, edit: true))),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('تعديل صفّي')),
      ])),
      const SizedBox(height: 13),
      Card(child:ListTile(
        leading:const Icon(Icons.psychology_alt_rounded,color:PColors.orange),
        title:const Text('دفتر أخطائي',
          style:TextStyle(fontWeight:FontWeight.w900)),
        subtitle:const Text('راجع أخطاء الاختبارات حتى تتقنها'),
        trailing:const Icon(Icons.chevron_left_rounded),
        onTap:()=>Navigator.push(context,MaterialPageRoute<void>(
          builder:(_)=>RoyalMistakeNotebook(
            student:s,lessons:widget.catalog.forStudent(s.grade,s.track)))))),
      const SizedBox(height: 13),
      Card(child:ListTile(
        leading:const Icon(Icons.emoji_events_rounded,color:PColors.orange),
        title:const Text('لوحة إنجازاتي',
          style:TextStyle(fontWeight:FontWeight.w900)),
        subtitle:const Text('شاراتي • هدفي اليومي • متابعة الأسبوع'),
        trailing:const Icon(Icons.chevron_left_rounded),
        onTap:()=>Navigator.push(context,MaterialPageRoute<void>(
          builder:(_)=>RoyalAchievementsScreen(
            student:s,
            lessons:widget.catalog.forStudent(s.grade,s.track),
            onPractice:(){
              Navigator.pop(context);
              final lessons=widget.catalog.forStudent(s.grade,s.track);
              if(s.dueCount(lessons.map((l)=>l.id))>0) {
                Navigator.push(context,MaterialPageRoute<void>(
                  builder:(_)=>ReviewScreen(lessons:lessons,student:s)));
              } else {
                setState(()=>tab=1);
              }
            },
            onSubjects:(){
              Navigator.pop(context);
              setState(()=>tab=1);
            },
          ))))),
      const SizedBox(height: 13),
      Panel(child: Column(children: [
        SwitchListTile(value: s.darkMode,
          onChanged: (v) => s.appearance(dark: v),
          title: const Text('الوضع الليلي'),
          secondary: const Icon(Icons.dark_mode_outlined)),
        const Divider(),
        SwitchListTile(
          value:s.animationsEnabled,
          title:const Text('الحركات التعليمية'),
          subtitle:const Text('حركات خفيفة مع احترام إعدادات تقليل الحركة'),
          secondary:const Icon(Icons.animation_rounded),
          onChanged:(value)=>s.appearance(motion:value)),
        const Divider(),
        const Text('حجم الخط'),
        Slider(value: s.scale, min: .9, max: 1.3, divisions: 4,
          onChanged: (v) => s.appearance(textScale: v)),
      ])),
      const SizedBox(height: 13),
      Panel(child: Text('النقاط: ' + s.xp.toString() +
        ' • الدروس المحفوظة: ' + s.favourites.length.toString())),
      const SizedBox(height: 12),
      OutlinedButton.icon(icon: const Icon(Icons.delete_outline_rounded),
        label: const Text('حذف جميع بياناتي من الهاتف'),
        onPressed: () async {
          final ok=await showDialog<bool>(context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('مسح البيانات؟'),
              content: const Text('سيُحذف التقدّم والمفضلة والإعدادات المحلية.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('حذف')),
              ]));
          if (ok == true) await s.erase();
        }),
      const SizedBox(height: 12),
      const Text('هذا النموذج لا يتضمن حسابات أو إعلانات أو تتبعاً',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
    ]);
}

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key,required this.lesson,required this.student});
  final Lesson lesson;
  final StudentState student;
  @override
  Widget build(BuildContext context)=>RoyalLessonReader(
    lesson:lesson,student:student,
    onQuiz:()=>Navigator.push(context,MaterialPageRoute<void>(
      builder:(_)=>QuizPage(lesson:lesson,student:student))),
    onFlashcards:()=>Navigator.push(context,MaterialPageRoute<void>(
      builder:(_)=>FlashPage(lesson:lesson))),
    onMatch:()=>Navigator.push(context,MaterialPageRoute<void>(
      builder:(_)=>MatchPage(lesson:lesson))));
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.lesson, required this.student});
  final Lesson lesson;
  final StudentState student;
  @override
  State<QuizPage> createState() => _QuizPageState();
}
class _QuizPageState extends State<QuizPage> {
  int index=0;
  int? selected;
  int score=0;
  bool finished=false;
  final Map<int,bool> answers={};
  @override
  Widget build(BuildContext context) {
    final all=widget.lesson.questions;
    final q=all[index];
    return Scaffold(appBar: AppBar(title: const Text('تحدّي المعرفة')),
      body: safe(ListView(padding: const EdgeInsets.all(20), children: [
        if (finished) ...[
          const SizedBox(height: 50),
          Center(child:RoyalMotionGraphic(
            asset:'assets/animations/achievement_stars.json',
            fallback:Icons.emoji_events_rounded,
            enabled:widget.student.animationsEnabled&&
              score*100>=all.length*70,
            label:'نتيجة الاختبار',
            size:140)),
          const SizedBox(height: 18),
          const Center(child: Text('أحسنت! أنهيت التحدّي',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900))),
          const SizedBox(height: 13),
          Center(child: Text('إجابات صحيحة: $score من ' + all.length.toString())),
          const SizedBox(height: 25),
          FilledButton(onPressed: () => Navigator.pop(context),
            child: const Text('العودة إلى الدرس')),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => setState(() {
            index=0; selected=null; score=0; finished=false;
            answers.clear();
          }), child: const Text('أعد التحدي')),
        ] else ...[
          Text('السؤال ' + (index+1).toString() +
            ' من ' + all.length.toString()),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: (index+1)/all.length, minHeight: 10),
          const SizedBox(height: 25),
          Panel(child: Text(q.prompt, style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w900))),
          const SizedBox(height: 15),
          for (int i=0;i<q.options.length;i++) ...[
            Card(child: InkWell(
              onTap: selected != null ? null : () => setState(() {
                selected=i;
                answers[index]=i==q.correct;
                if (i == q.correct) score++;
              }),
              child: Padding(padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Expanded(child: Text(q.options[i],
                    style: const TextStyle(fontSize: 17))),
                  if (selected != null && i==q.correct)
                    const Icon(Icons.check_circle, color: Colors.green),
                  if (selected==i && i!=q.correct)
                    const Icon(Icons.cancel, color: Colors.red),
                ])))),
            const SizedBox(height: 8),
          ],
          if (selected != null) ...[
            const SizedBox(height: 12),
            Panel(child: Text(q.explanation)),
            const SizedBox(height: 13),
            FilledButton(onPressed: () async {
              if (index+1 == all.length) {
                await widget.student.finish(widget.lesson.id, score, all.length);
                await widget.student.recordQuizAnswers(widget.lesson,answers);
                if (mounted) setState(() => finished=true);
              } else {
                setState(() { index++; selected=null; });
              }
            }, child: Text(index+1 == all.length ?
              'عرض النتيجة' : 'السؤال التالي')),
          ],
        ],
      ])),
    );
  }
}

class FlashPage extends StatefulWidget {
  const FlashPage({super.key, required this.lesson});
  final Lesson lesson;
  @override
  State<FlashPage> createState() => _FlashPageState();
}
class _FlashPageState extends State<FlashPage> {
  int index=0; bool revealed=false;
  @override
  Widget build(BuildContext context) {
    final q=widget.lesson.questions[index];
    return Scaffold(appBar: AppBar(title: const Text('بطاقات الذاكرة')),
      body: safe(ListView(padding: const EdgeInsets.all(20), children: [
        Text('البطاقة ' + (index+1).toString() +
          ' من ' + widget.lesson.questions.length.toString()),
        const SizedBox(height: 17),
        SizedBox(height: 260, child: Card(
          child: InkWell(onTap: () => setState(() => revealed=!revealed),
            child: Center(child: Padding(padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Column(key: ValueKey('$index-$revealed'),
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(revealed ? Icons.lightbulb : Icons.help_outline,
                      size: 39, color: PColors.teal),
                    const SizedBox(height: 14),
                    Text(revealed ? q.options[q.correct] : q.prompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w900)),
                    if (revealed) ...[
                      const SizedBox(height: 10),
                      Text(q.explanation, textAlign: TextAlign.center),
                    ],
                  ]),
              )))))),
        const SizedBox(height: 14),
        Text(revealed ? 'اضغط لإخفاء الحل' : 'اضغط على البطاقة لاكتشاف الحل',
          textAlign: TextAlign.center),
        const SizedBox(height: 21),
        FilledButton(onPressed: () => setState(() {
          index=(index+1)%widget.lesson.questions.length; revealed=false;
        }), child: const Text('البطاقة التالية')),
      ])),
    );
  }
}

class MatchPage extends StatefulWidget {
  const MatchPage({super.key, required this.lesson});
  final Lesson lesson;
  @override
  State<MatchPage> createState() => _MatchPageState();
}
class _MatchPageState extends State<MatchPage> {
  int? picked;
  final Set<int> matched={};
  String message='اختر السؤال ثم الإجابة المطابقة';
  @override
  Widget build(BuildContext context) {
    final q=widget.lesson.questions;
    return Scaffold(appBar: AppBar(title: const Text('لعبة المطابقة')),
      body: safe(ListView(padding: const EdgeInsets.all(19), children: [
        const Text('صل السؤال بالجواب', style: TextStyle(
          fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        LinearProgressIndicator(value: matched.length/q.length, minHeight: 9),
        const SizedBox(height: 15),
        for (int i=0;i<q.length;i++) ...[
          Card(child: ListTile(
            selected: picked==i,
            title: Text(q[i].prompt),
            leading: Icon(matched.contains(i) ?
              Icons.check_circle : Icons.help_outline,
              color: matched.contains(i) ? PColors.teal : null),
            onTap: matched.contains(i) ? null : () => setState(() => picked=i))),
          const SizedBox(height: 7),
        ],
        const SizedBox(height: 13),
        const Text('الإجابات', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        for (int i=q.length-1;i>=0;i--) ...[
          Card(child: ListTile(title: Text(q[i].options[q[i].correct]),
            trailing: matched.contains(i)
              ? const Icon(Icons.verified, color: PColors.teal) : null,
            onTap: matched.contains(i) ? null : () => setState(() {
              if (picked==i) {
                matched.add(i); picked=null;
                message=matched.length==q.length ?
                  'أبدعت! أكملت المطابقة 🎉' : 'إجابة صحيحة!';
              } else { message='حاول مرة أخرى'; }
            }))),
          const SizedBox(height: 7),
        ],
        const SizedBox(height: 13),
        Panel(child: Text(message, textAlign: TextAlign.center)),
        if (matched.length==q.length) ...[
          const SizedBox(height: 12),
          FilledButton(onPressed: () => Navigator.pop(context),
            child: const Text('أنهيت اللعبة')),
        ],
      ])),
    );
  }
}


class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.lessons, required this.student});
  final List<Lesson> lessons;
  final StudentState student;

  @override
  Widget build(BuildContext context) {
    final scheduled = lessons.where((l) => student.reviewFor(l.id) != null)
        .toList()..sort((a, b) =>
            student.reviewFor(a.id)!.dueDate.compareTo(
              student.reviewFor(b.id)!.dueDate));
    final today = scheduled.where((l) => student.reviewDue(l.id)).toList();
    final future = scheduled.where((l) => !student.reviewDue(l.id)).toList();

    Widget item(Lesson lesson) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(child: ListTile(
        title: Text(lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('المراجعة القادمة: ' +
            student.reviewFor(lesson.id)!.dueDate),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: () => openLesson(context, lesson, student),
      )),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('مراجعتي الذكية')),
      body: safe(ListView(padding: const EdgeInsets.all(20), children: [
        const Text('راجع في الوقت المناسب', style: TextStyle(
          fontWeight: FontWeight.w900, fontSize: 24)),
        const SizedBox(height: 6),
        const Text('تُحدد المواعيد حسب نتائج التدريب وتُحفظ دون إنترنت.'),
        const SizedBox(height: 20),
        const Text('مستحق اليوم', style: TextStyle(
          fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (today.isEmpty)
          const Panel(child: Text('ممتاز! ليس لديك مراجعات مستحقة حالياً.')),
        ...today.map(item),
        const SizedBox(height: 20),
        const Text('مراجعات قادمة', style: TextStyle(
          fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        if (future.isEmpty)
          const Panel(child: Text('ستظهر المراجعات بعد إنهاء اختبارات الدروس.')),
        ...future.map(item),
      ])),
    );
  }
}
