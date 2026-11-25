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

  Future<void> copyReport(LearningReportSnapshot snapshot) async {
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
    try {
      await Clipboard.setData(
        ClipboardData(text: exportLearningReportCsv(snapshot)),
      );
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.student,
    builder: (context, _) {
      final subjects = widget.lessons.map((l) => l.subject).toSet().toList()
        ..sort();
      final activeSubject = subjects.contains(subject) ? subject : null;
      final lessons = <String, Lesson>{
        for (final lesson in widget.lessons)
          if (activeSubject == null || lesson.subject == activeSubject)
            lesson.id.trim(): lesson,
      };
      final snapshot = buildLearningReportSnapshot(
        widget.student.learningAttempts.where(
          (attempt) => lessons.containsKey(attempt.lessonId.trim()),
        ),
      );
      final overall = snapshot.overall;
      final revision = snapshot.revisionLessons(
        limit: 5,
        maximumAccuracyPercent: 79.999,
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
                      subtitle: 'أقل من 80% في الاختبارات السابقة',
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
                      onPressed: () => copyReport(snapshot),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('نسخ تقرير CSV'),
                    ),
                  ],
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
