import 'package:flutter/material.dart';
import '../data/models.dart';
import '../state/student_state.dart';
import 'design.dart';

/// Local-only progress by subject. No cloud access or invented grades.
class SubjectProgress {
  const SubjectProgress(this.subject,this.completed,this.total,this.strong);
  final String subject;
  final int completed,total,strong;
  double get ratio => total==0 ? 0 : completed/total;
  int get percent => (ratio*100).round();
}

List<SubjectProgress> calculateSubjectProgress(
    StudentState student,Iterable<Lesson> lessons) {
  final groups=<String,Set<String>>{};
  final completed=<String,Set<String>>{};
  final strong=<String,Set<String>>{};
  for(final lesson in lessons) {
    final name=lesson.subject.trim();
    if(name.isEmpty) continue;
    groups.putIfAbsent(name,()=> <String>{}).add(lesson.id);
    if(student.done(lesson.id)) {
      completed.putIfAbsent(name,()=> <String>{}).add(lesson.id);
    }
    if((student.reviews[lesson.id]?.lastScore??0)>=80) {
      strong.putIfAbsent(name,()=> <String>{}).add(lesson.id);
    }
  }
  final result=[
    for(final entry in groups.entries)
      SubjectProgress(entry.key,completed[entry.key]?.length??0,
        entry.value.length,strong[entry.key]?.length??0),
  ];
  result.sort((a,b)=>a.subject.compareTo(b.subject));
  return result;
}

class SubjectProgressReport extends StatelessWidget {
  const SubjectProgressReport({
    super.key,required this.student,required this.lessons,
  });
  final StudentState student;
  final List<Lesson> lessons;

  @override
  Widget build(BuildContext context) {
    final groups=calculateSubjectProgress(student,lessons);
    final total=groups.fold<int>(0,(sum,e)=>sum+e.total);
    final done=groups.fold<int>(0,(sum,e)=>sum+e.completed);
    return Scaffold(
      appBar:AppBar(title:const Text('تقرير تقدمي حسب المبحث')),
      body:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:900),
        child:ListView(
          key:const Key('subject-progress-report'),
          padding:const EdgeInsets.fromLTRB(18,16,18,32),
          children:[
            Container(
              padding:const EdgeInsets.all(22),
              decoration:BoxDecoration(
                gradient:const LinearGradient(
                  colors:[PColors.midnight,PColors.royal]),
                borderRadius:BorderRadius.circular(25)),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  const Text('رحلتي في المباحث',
                    style:TextStyle(color:Colors.white,fontSize:23,
                      fontWeight:FontWeight.w900)),
                  const SizedBox(height:8),
                  Text('أنجزت $done من $total دروس متاحة',
                    style:const TextStyle(color:Colors.white)),
                  const SizedBox(height:12),
                  LinearProgressIndicator(
                    value:total==0?0:done/total,
                    minHeight:10,color:PColors.gold,
                    backgroundColor:Colors.white24),
                ])),
            const SizedBox(height:18),
            if(groups.isEmpty)
              const Panel(child:Text('لا توجد دروس متاحة لعرض التقرير.')),
            for(final item in groups) ...[
              Panel(child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(item.subject,style:const TextStyle(
                    fontSize:18,fontWeight:FontWeight.w900)),
                  const SizedBox(height:9),
                  Text('المكتملة: ${item.completed} من ${item.total} • ${item.percent}٪'),
                  const SizedBox(height:10),
                  Semantics(
                    label:'تقدم ${item.subject}: ${item.percent} بالمئة',
                    child:LinearProgressIndicator(value:item.ratio,minHeight:9,
                      color:PColors.teal,backgroundColor:PColors.mint)),
                  const SizedBox(height:10),
                  Text('دروس بآخر نتيجة 80٪ فأكثر: ${item.strong}',
                    style:TextStyle(fontSize:12,
                      color:Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
              const SizedBox(height:11),
            ],
            const SizedBox(height:10),
            const Text(
              'التقرير محسوب من الدروس المتاحة وسجل هذا الجهاز فقط. '
              'النتيجة الأخيرة ليست معدلاً مدرسياً رسمياً، '
              'ولا تُرسل البيانات إلى خادم.',
              textAlign:TextAlign.center,
              style:TextStyle(fontSize:12)),
          ],
        ))),
    );
  }
}
