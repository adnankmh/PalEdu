import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/learning_report.dart';
import '../data/learning_report_csv.dart';
import '../data/learning_report_snapshot.dart';
import '../data/models.dart';
import '../state/student_state.dart';
import 'design.dart';

/// On-device student report, scoped to the supplied grade/track catalogue.
class RoyalLearningReportScreen extends StatefulWidget {
  const RoyalLearningReportScreen({
    super.key,
    required this.student,
    required this.lessons,
    required this.onLesson,
  });

  final StudentState student;
  final List<Lesson> lessons;
  final ValueChanged<Lesson> onLesson;

  @override
  State<RoyalLearningReportScreen> createState() =>
      _RoyalLearningReportScreenState();
}

class _RoyalLearningReportScreenState
    extends State<RoyalLearningReportScreen> {
  String? subject;

  String accuracy(LearningReport report) =>
      report.accuracyPercent == null
          ? '—'
          : '${report.accuracyPercent!.toStringAsFixed(1)}%';

  Map<String, Lesson> scopedLessons(String? selectedSubject) => {
    for (final lesson in widget.lessons)
      if (selectedSubject == null || lesson.subject == selectedSubject)
        lesson.id.trim(): lesson,
  };

  LearningReportSnapshot reportFor(Map<String, Lesson> lessons) =>
      buildLearningReportSnapshot(
        widget.student.learningAttempts.where(
          (attempt) => lessons.containsKey(attempt.lessonId.trim()),
        ),
      );

  Future<void> copyReport(
    LearningReportSnapshot snapshot,
    String? activeSubject,
  ) async {
    final csv = exportLearningReportCsv(snapshot);
    final grade = widget.student.grade;
    final track = widget.student.track;
    final selectedSubject = activeSubject;
    final profileName = widget.student.name;
    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نسخ التقرير؟'),
        content: const Text(
          'يتضمن التقرير نتائج مجمّعة ومعرّفات الدروس فقط. '
          'قد تتمكن التطبيقات الأخرى من قراءة الحافظة. شاركه باختيارك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نسخ'),
          ),
        ],
      ),
    );
    if (consent != true || !mounted) return;
    // A report must not be copied after its data or profile has changed
    // while the confirmation dialog was open.
    if (grade != widget.student.grade ||
        track != widget.student.track ||
        profileName != widget.student.name ||
        selectedSubject != effectiveSubject ||
        csv != exportLearningReportCsv(
          reportFor(scopedLessons(effectiveSubject)),
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تغيّر التقرير، أعد طلب النسخ')),
      );
      return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: csv));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ التقرير بصيغة CSV')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر نسخ التقرير')),
      );
    }
  }

  String? get effectiveSubject =>
      widget.lessons.any((lesson) => lesson.subject == subject)
          ? subject
          : null;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.student,
    builder: (context, _) {
      final subjects = widget.lessons.map((l) => l.subject).toSet().toList()
        ..sort();
      final activeSubject = effectiveSubject;
      final lessons = scopedLessons(activeSubject);
      final snapshot = reportFor(lessons);
      final completedCount = lessons.keys.where(widget.student.done).length;
      final pending = lessons.entries
          .where((entry) => !widget.student.done(entry.key))
          .map((entry) => entry.value)
          .toList();
      final overall = snapshot.overall;
      final revision = snapshot.revisionLessons(
        limit: 5,
        maximumAccuracyPercent: 80,
      );
      return Scaffold(
        appBar: AppBar(title: const Text('تقرير تعلمي')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.insights_rounded,
                            color: PColors.teal, size: 32),
                        const SizedBox(height: 8),
                        Text('تقدّمي الدراسي',
                          style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        const Text(
                          'نتائج الاختبارات المكتملة لهذا الصف والمسار، '
                          'من آخر 200 محاولة محفوظة على هذا الجهاز.',
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('كل المواد'),
                              selected: activeSubject == null,
                              onSelected: (_) => setState(() => subject = null),
                            ),
                            for (final item in subjects)
                              ChoiceChip(
                                label: Text(item),
                                selected: activeSubject == item,
                                onSelected: (_) =>
                                    setState(() => subject = item),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (overall.attempts == 0)
                    const Panel(
                      child: Column(
                        children: [
                          Icon(Icons.school_outlined, size: 42),
                          SizedBox(height: 12),
                          Text('لا توجد محاولات مكتملة بعد'),
                          SizedBox(height: 6),
                          Text('أكمل اختبار درس لتظهر نتائجك هنا.',
                            textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  else ...[
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('نسبة الإجابات الصحيحة: ${accuracy(overall)}',
                            key: const Key('report-accuracy'),
                            style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: overall.accuracyPercent! / 100,
                            minHeight: 9,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 14),
                          Text('المحاولات: ${overall.attempts}'),
                          Text('الدروس المتدرّب عليها: ${overall.lessonsPracticed}'),
                          Text('الإجابات الصحيحة: ${overall.correctAnswers}'
                              ' / ${overall.totalQuestions}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const RoyalSectionHeading(
                      title: 'أولويات المراجعة',
                      subtitle: '80% أو أقل في الاختبارات السابقة',
                    ),
                    const SizedBox(height: 8),
                    if (revision.isEmpty)
                      const Panel(child: Text('لا توجد أولويات مراجعة حالياً.')),
                    for (final id in revision)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            key: ValueKey('revision-$id'),
                            leading: const Icon(Icons.refresh_rounded),
                            title: Text(lessons[id]!.title),
                            subtitle: Text(accuracy(snapshot.byLesson[id]!)),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () => widget.onLesson(lessons[id]!),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const RoyalSectionHeading(title: 'تفاصيل الدروس'),
                    const SizedBox(height: 8),
                    for (final entry in snapshot.byLesson.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            title: Text(lessons[entry.key]!.title),
                            subtitle: Text(
                              '${lessons[entry.key]!.subject} • '
                              '${entry.value.attempts} محاولة • '
                              '${entry.value.correctAnswers}/'
                              '${entry.value.totalQuestions}',
                            ),
                            trailing: Text(accuracy(entry.value)),
                            onTap: () => widget.onLesson(lessons[entry.key]!),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('report-copy-csv'),
                      onPressed: () => copyReport(snapshot, activeSubject),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('نسخ تقرير CSV'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const RoyalSectionHeading(
                    title: 'خطة الدراسة',
                    subtitle: 'إكمال الدروس يختلف عن إتقان الاختبارات',
                  ),
                  const SizedBox(height: 8),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الدروس المكتملة: $completedCount / ${lessons.length}',
                          key: const Key('study-coverage')),
                        const SizedBox(height: 10),
                        if (lessons.isNotEmpty)
                          LinearProgressIndicator(
                            value: completedCount / lessons.length,
                            minHeight: 9,
                          ),
                        const SizedBox(height: 10),
                        Text('الدروس المتبقية: ${pending.length}'),
                        if (lessons.isEmpty)
                          const Text('لا توجد دروس متاحة لهذا الاختيار.')
                        else if (pending.isEmpty)
                          const Text('أكملت جميع الدروس المتاحة لهذا الاختيار.')
                        else ...[
                          const SizedBox(height: 12),
                          Text('الدرس التالي المقترح: ${pending.first.title}'),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            key: const Key('study-next-lesson'),
                            onPressed: () => widget.onLesson(pending.first),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('متابعة الدراسة'),
                          ),
                        ],
                        if (activeSubject == null && subjects.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('التقدم حسب المادة',
                            style: Theme.of(context).textTheme.titleMedium),
                          for (final item in subjects)
                            Builder(builder: (context) {
                              final subjectLessons = scopedLessons(item);
                              final ids = subjectLessons.keys;
                              final done = ids.where(widget.student.done).length;
                              final mastery = reportFor(subjectLessons).overall;
                              return ListTile(
                                key: ValueKey('study-subject-$item'),
                                contentPadding: EdgeInsets.zero,
                                title: Text(item),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LinearProgressIndicator(
                                      value: ids.isEmpty ? 0 : done / ids.length,
                                      semanticsLabel: 'إكمال الدروس',
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      mastery.attempts == 0
                                          ? 'لم تُجرَ اختبارات بعد'
                                          : 'الإتقان: ${accuracy(mastery)}',
                                      key: ValueKey('study-mastery-$item'),
                                    ),
                                  ],
                                ),
                                trailing: Text('$done / ${ids.length}'),
                                onTap: () => setState(() => subject = item),
                              );
                            }),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'هذا التقرير محلي وليس كشف درجات رسمياً. '
                    'لا تُرسل النتائج تلقائياً إلى المعلم أو أي خادم.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
