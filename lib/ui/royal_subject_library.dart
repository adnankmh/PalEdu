import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/lesson_search.dart';
import '../state/student_state.dart';
import 'design.dart';

/// Curriculum browser: expandable subjects, lessons, verified-source shortcut.
/// No fabricated ministry textbooks, school terms or progress percentages.
class RoyalSubjectLibrary extends StatefulWidget {
  const RoyalSubjectLibrary({super.key,required this.lessons,
    required this.student,required this.onLesson,
    required this.onOfficialSources});
  final List<Lesson> lessons;
  final StudentState student;
  final void Function(Lesson) onLesson;
  final VoidCallback onOfficialSources;
  @override
  State<RoyalSubjectLibrary> createState()=>_RoyalSubjectLibraryState();
}

class _RoyalSubjectLibraryState extends State<RoyalSubjectLibrary> {
  final search=TextEditingController();
  String searchText='';
  String? expanded;
  bool onlyIncomplete=false;
  @override
  void dispose(){search.dispose();super.dispose();}
  @override
  Widget build(BuildContext context) {
    final grouped=<String,List<Lesson>>{};
    for(final lesson in widget.lessons) {
      final contains=matchesLessonSearch(lesson, searchText);
      if(contains && (!onlyIncomplete || !widget.student.done(lesson.id))) {
        grouped.putIfAbsent(lesson.subject,()=>[]).add(lesson);
      }
    }
    return ListView(
      key:const Key('royal-subject-library'),
      padding:const EdgeInsets.fromLTRB(18,20,18,32),
      children:[
        Text('المقررات والوحدات الدراسية',
          style:Theme.of(context).textTheme.headlineSmall?.copyWith(
            color:Theme.of(context).brightness==Brightness.light
              ? PColors.midnight : null,
            fontWeight:FontWeight.w900)),
        const SizedBox(height:5),
        Text(LessonCatalog.gradeName(widget.student.grade)+
          ' • '+widget.student.track,
          style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height:18),
        TextField(controller:search,
          onChanged:(v)=>setState(()=>searchText=v.trim()),
          decoration:const InputDecoration(
            hintText:'ابحث عن مادة أو درس أو وحدة',
            prefixIcon:Icon(Icons.search_rounded))),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:Text('المواد المتاحة',
            style:const TextStyle(fontSize:13,fontWeight:FontWeight.w800))),
          FilterChip(
            label:const Text('غير المكتمل'),
            selected:onlyIncomplete,
            onSelected:(b)=>setState(()=>onlyIncomplete=b),
            avatar:const Icon(Icons.fact_check_outlined,size:18)),
        ]),
        const SizedBox(height:12),
        for(final item in grouped.entries) ...[
          _ExpandableSubject(
            name:item.key,lessons:item.value,student:widget.student,
            open:expanded==item.key,
            onExpand:()=>setState(()=>expanded=expanded==item.key
              ? null:item.key),
            onLesson:widget.onLesson),
          const SizedBox(height:11),
        ],
        if(grouped.isEmpty) ...[
          const Panel(child:Column(children:[
            Icon(Icons.search_off_rounded,size:36,color:PColors.teal),
            SizedBox(height:9),
            Text('لا توجد دروس مطابقة حالياً.',
              textAlign:TextAlign.center),
          ])),
          const SizedBox(height:12),
        ],
        const SizedBox(height:12),
        Card(child:InkWell(
          onTap:widget.onOfficialSources,
          borderRadius:BorderRadius.circular(21),
          child:Padding(padding:const EdgeInsets.all(17),
            child:Row(children:[
              Container(padding:const EdgeInsets.all(12),
                decoration:BoxDecoration(color:const Color(0xFFFFF2D3),
                  borderRadius:BorderRadius.circular(15)),
                child:const Icon(Icons.menu_book_rounded,
                  color:PColors.orange)),
              const SizedBox(width:13),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
                children:[
                  const Text('كتب المنهاج الفلسطيني الرسمي',
                    style:TextStyle(fontWeight:FontWeight.w900,fontSize:15)),
                  const SizedBox(height:4),
                  Text('عرض المصادر مباشرة من موقع الوزارة',
                    style:TextStyle(fontSize:12,
                      color:Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
              const Icon(Icons.open_in_new_rounded,color:PColors.orange),
            ])))),
        const SizedBox(height:14),
        const Text('الدروس داخل التطبيق تجريبية حالياً؛ أسماء الوحدات والفصول الرسمية ستُعرض بعد استيراد المنهاج المعتمد.',
          style:TextStyle(fontSize:11.5),textAlign:TextAlign.center),
      ],
    );
  }
}

class _ExpandableSubject extends StatelessWidget {
  const _ExpandableSubject({required this.name,required this.lessons,
    required this.student,required this.open,required this.onExpand,
    required this.onLesson});
  final String name;
  final List<Lesson> lessons;
  final StudentState student;
  final bool open;
  final VoidCallback onExpand;
  final void Function(Lesson) onLesson;
  @override
  Widget build(BuildContext context) {
    final completed=lessons.where((l)=>student.done(l.id)).length;
    final percent=lessons.isEmpty?0.0:completed/lessons.length;
    final accent=name.contains('رياضيات')?PColors.royal:
      name.contains('فيزياء')?PColors.blue:
      name.contains('كيمياء')?PColors.orange:const Color(0xFF7962B0);
    return Card(
      child:Column(children:[
        InkWell(
          borderRadius:BorderRadius.circular(22),
          onTap:onExpand,
          child:Padding(padding:const EdgeInsets.all(17),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[
                Container(width:47,height:47,
                  decoration:BoxDecoration(color:accent.withValues(alpha:.10),
                    borderRadius:BorderRadius.circular(13)),
                  child:Icon(name.contains('رياضيات')?Icons.functions_rounded:
                    name.contains('فيزياء')?Icons.bolt_rounded:
                    name.contains('كيمياء')?Icons.science_rounded:
                    Icons.auto_stories_rounded,color:accent)),
                const SizedBox(width:13),
                Expanded(child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(name,style:const TextStyle(
                      fontWeight:FontWeight.w900,fontSize:17)),
                    const SizedBox(height:3),
                    Text(lessons.length.toString()+' دروس • '+
                      completed.toString()+' مكتملة',
                      style:TextStyle(fontSize:12,
                        color:Theme.of(context).colorScheme.onSurfaceVariant)),
                  ])),
                AnimatedRotation(
                  turns:open ? 0.5 : 0.0,
                  duration:const Duration(milliseconds:220),
                  child:Icon(Icons.keyboard_arrow_down_rounded,
                    color:accent,size:27)),
              ]),
              const SizedBox(height:13),
              Row(children:[
                Expanded(child:ClipRRect(
                  borderRadius:BorderRadius.circular(9),
                  child:LinearProgressIndicator(value:percent,minHeight:7,
                    color:accent,backgroundColor:accent.withValues(alpha:.10)))),
                const SizedBox(width:10),
                Text((percent*100).round().toString()+'%',
                  style:TextStyle(color:accent,fontWeight:FontWeight.w900)),
              ]),
            ]))),
        AnimatedCrossFade(
          duration:const Duration(milliseconds:240),
          crossFadeState:open?CrossFadeState.showSecond:CrossFadeState.showFirst,
          firstChild:const SizedBox(height:0,width:double.infinity),
          secondChild:Column(children:[
            const Divider(height:1),
            Padding(padding:const EdgeInsets.fromLTRB(14,12,14,8),
              child:Align(alignment:Alignment.centerRight,
                child:Text('الدروس المتاحة',
                  style:TextStyle(fontSize:13,fontWeight:FontWeight.w800,
                    color:Theme.of(context).colorScheme.onSurfaceVariant)))),
            ...lessons.map((l)=>ListTile(
              contentPadding:const EdgeInsets.symmetric(horizontal:17),
              leading:Icon(student.done(l.id)?Icons.check_circle_rounded:
                Icons.play_circle_outline_rounded,
                color:student.done(l.id)?PColors.royal:accent),
              title:Text(l.title,
                maxLines:2,overflow:TextOverflow.ellipsis,
                style:const TextStyle(fontWeight:FontWeight.w800)),
              subtitle:Text(l.duration.toString()+' دقائق • '+
                (student.done(l.id)?'مكتمل':'ابدأ الدرس')),
              trailing:const Icon(Icons.chevron_left_rounded),
              onTap:()=>onLesson(l),
            )),
            const SizedBox(height:7),
          ]),
        ),
      ]),
    );
  }
}
