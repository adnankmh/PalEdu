import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/models.dart';
import 'state/student_state.dart';
import 'ui/design.dart';
import 'portal/portal_service.dart';
import 'portal/portal_gateway.dart';

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
          child: const Icon(Icons.auto_stories_rounded,
            color: PColors.gold, size: 44))),
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
        dashboard(lessons, s),
        library(lessons, s),
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

  Widget dashboard(List<Lesson> lessons, StudentState s) {
    final done=lessons.where((l) => s.done(l.id)).length;
    final progress=lessons.isEmpty ? 0.0 : done/lessons.length;
    return ListView(padding: const EdgeInsets.all(19), children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أهلاً، ' + s.name + ' 👋',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            Text(LessonCatalog.gradeName(s.grade) + ' • ' + s.track),
          ])),
        const CircleAvatar(radius: 25, backgroundColor: PColors.mint,
          child: Icon(Icons.school_rounded, color: PColors.midnight)),
      ]),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(27),
          gradient: const LinearGradient(
            colors: [PColors.royal, PColors.midnight, Color(0xFF007B81)],
            begin: Alignment.topRight, end: Alignment.bottomLeft)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('✦ رحلة التعلّم', style: TextStyle(
            color: PColors.gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 15),
          const Text('كل يوم، إنجاز جديد',
            style: TextStyle(color: Colors.white, fontSize: 27,
              fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('تعلّم بذكاء، العب واكتشف، وتقدّم دون إنترنت.',
            style: TextStyle(color: Color(0xFFE8F3FF), fontSize: 15)),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: () => setState(() => tab=1),
            style: FilledButton.styleFrom(
              foregroundColor: PColors.midnight, backgroundColor: Colors.white),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('استكشف دروسي')),
        ]),
      ),
      const SizedBox(height: 15),
      Row(children: [
        Expanded(child: Panel(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.stars_rounded, color: PColors.gold, size: 29),
            Text(s.xp.toString(), style: const TextStyle(
              fontSize: 25, fontWeight: FontWeight.w900)),
            const Text('نقاطي'),
          ]))),
        const SizedBox(width: 10),
        Expanded(child: Panel(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.verified_rounded, color: PColors.teal, size: 29),
            Text(done.toString(), style: const TextStyle(
              fontSize: 25, fontWeight: FontWeight.w900)),
            const Text('دروس مكتملة'),
          ]))),
      ]),
      const SizedBox(height: 23),
      Text('تقدّمي', style: Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 9),
      Panel(child: Column(children: [
        Row(children: [
          Expanded(child: Text('أنجزت $done من ' + lessons.length.toString())),
          Text((progress*100).round().toString() + '%'),
        ]),
        const SizedBox(height: 11),
        LinearProgressIndicator(value: progress, minHeight: 11,
          color: PColors.teal, backgroundColor: PColors.mint),
      ])),
      const SizedBox(height: 14),
      Panel(child: ListTile(
        leading: const Icon(Icons.psychology_alt_rounded, color: PColors.teal),
        title: const Text('مراجعتي الذكية',
          style: TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(s.dueCount(lessons.map((lesson) => lesson.id)) > 0
          ? 'لديك مراجعات تستحق اهتمامك اليوم'
          : 'راجع وفق جدول مبني على نتائجك'),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => ReviewScreen(lessons: lessons, student: s))),
      )),
      const SizedBox(height: 24),
      Text('استكشف اليوم', style: Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      ...lessons.take(3).map((l) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: lessonCard(l, s))),
      const Text('نماذج تعليمية تجريبية وليست كتب الوزارة الرسمية',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
    ]);
  }

  Widget lessonCard(Lesson l, StudentState s) => Card(
    child: InkWell(borderRadius: BorderRadius.circular(23),
      onTap: () => openLesson(context, l, s),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(height: 52, width: 52,
          decoration: BoxDecoration(color: PColors.mint,
            borderRadius: BorderRadius.circular(15)),
          child: Icon(l.subject.contains('رياضيات') ?
            Icons.calculate_rounded : Icons.menu_book_rounded,
            color: PColors.midnight)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.title, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900)),
            Text(l.subject + ' • ' + l.duration.toString() + ' دقائق'),
          ])),
        Icon(s.done(l.id) ? Icons.check_circle_rounded :
          Icons.chevron_left_rounded, color: s.done(l.id) ? PColors.teal : null),
      ]))),
  );

  Widget library(List<Lesson> lessons, StudentState s) {
    final groups=<String,List<Lesson>>{};
    for (final l in lessons) {
      groups.putIfAbsent(l.subject, () => []).add(l);
    }
    return ListView(padding: const EdgeInsets.all(19), children: [
      Text('مكتبتي الدراسية', style: Theme.of(context).textTheme.headlineSmall
        ?.copyWith(fontWeight: FontWeight.w900)),
      const Text('دروس منظّمة حسب المادة والصف الدراسي'),
      const SizedBox(height: 17),
      for (final entry in groups.entries) ...[
        Text(entry.key, style: const TextStyle(
          fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        ...entry.value.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: lessonCard(l, s))),
        const SizedBox(height: 14),
      ],
    ]);
  }

  Widget games(List<Lesson> lessons) => ListView(
    padding: const EdgeInsets.all(19), children: [
      const Text('مختبر الألعاب', style: TextStyle(
        fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('بطاقات ذاكرة وألعاب مطابقة في كل درس'),
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
      Panel(child: Column(children: [
        SwitchListTile(value: s.darkMode,
          onChanged: (v) => s.appearance(dark: v),
          title: const Text('الوضع الليلي'),
          secondary: const Icon(Icons.dark_mode_outlined)),
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
  const LessonScreen({super.key, required this.lesson, required this.student});
  final Lesson lesson;
  final StudentState student;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(lesson.subject), actions: [
      IconButton(onPressed: () => student.toggleSaved(lesson.id),
        tooltip: 'حفظ الدرس', icon: Icon(student.saved(lesson.id)
          ? Icons.bookmark_rounded : Icons.bookmark_border_rounded)),
    ]),
    body: safe(ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PColors.midnight, borderRadius: BorderRadius.circular(27)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('✦ درس تفاعلي', style: TextStyle(color: PColors.gold)),
          const SizedBox(height: 10),
          Text(lesson.title, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w900, fontSize: 26)),
          const SizedBox(height: 9),
          Text(lesson.summary,
            style: const TextStyle(color: Color(0xFFE7F4FF))),
        ])),
      const SizedBox(height: 20),
      for (int i=0;i<lesson.sections.length;i++) ...[
        Panel(child: Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: PColors.mint, radius: 17,
              child: Text((i+1).toString(),
                style: const TextStyle(color: PColors.midnight))),
            const SizedBox(width: 12),
            Expanded(child: Text(lesson.sections[i],
              style: const TextStyle(fontSize: 17, height: 1.6))),
          ])),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 15),
      FilledButton.icon(onPressed: () => Navigator.push(context,
        MaterialPageRoute<void>(builder: (_) =>
          QuizPage(lesson: lesson, student: student))),
        icon: const Icon(Icons.quiz_rounded),
        label: const Text('اختبر فهمك')),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: () => Navigator.push(context,
        MaterialPageRoute<void>(builder: (_) =>
          FlashPage(lesson: lesson))),
        icon: const Icon(Icons.style_rounded),
        label: const Text('بطاقات الذاكرة')),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: () => Navigator.push(context,
        MaterialPageRoute<void>(builder: (_) =>
          MatchPage(lesson: lesson))),
        icon: const Icon(Icons.extension_rounded),
        label: const Text('لعبة المطابقة')),
    ])),
  );
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
  @override
  Widget build(BuildContext context) {
    final all=widget.lesson.questions;
    final q=all[index];
    return Scaffold(appBar: AppBar(title: const Text('تحدّي المعرفة')),
      body: safe(ListView(padding: const EdgeInsets.all(20), children: [
        if (finished) ...[
          const SizedBox(height: 50),
          const Icon(Icons.emoji_events_rounded,
            size: 90, color: PColors.gold),
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
