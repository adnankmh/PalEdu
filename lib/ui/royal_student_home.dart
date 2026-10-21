import 'package:flutter/material.dart';
import '../data/models.dart';
import '../state/student_state.dart';
import 'design.dart';
import 'royal_motion.dart';
import 'paledu_brand.dart';

/// Dashboard inspired by approved PalEdu emerald/gold references.
/// All numbers are computed from actual locally persisted learner progress.
class RoyalStudentHome extends StatelessWidget {
  const RoyalStudentHome({super.key,required this.student,required this.lessons,
    required this.onSubjects,required this.onGames,required this.onReview,
    required this.onAchievements,required this.onMistakes,
    required this.onOfficialSources,required this.onLesson});
  final StudentState student;
  final List<Lesson> lessons;
  final VoidCallback onSubjects,onGames,onReview,onOfficialSources,onAchievements,onMistakes;
  final void Function(Lesson) onLesson;

  @override
  Widget build(BuildContext context) {
    final count=lessons.where((lesson)=>student.done(lesson.id)).length;
    final progress=lessons.isEmpty?0.0:count/lessons.length;
    final next=lessons.cast<Lesson?>().firstWhere(
      (lesson)=>lesson!=null && !student.done(lesson.id),
      orElse:()=>lessons.isEmpty?null:lessons.first);
    final subjects=<String,List<Lesson>>{};
    for(final lesson in lessons) {
      subjects.putIfAbsent(lesson.subject,()=>[]).add(lesson);
    }
    return ListView(
      key:const Key('royal-student-home'),
      padding:const EdgeInsets.fromLTRB(18,18,18,32),
      children:[
        Row(children:[
          CircleAvatar(radius:25,backgroundColor:PColors.mint,
            child:const PalEduBrandLogo(size:44)),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Text('مرحباً، '+student.name, maxLines:1,
                overflow:TextOverflow.ellipsis,
                style:const TextStyle(fontWeight:FontWeight.w900,fontSize:22)),
              const SizedBox(height:3),
              Text(LessonCatalog.gradeName(student.grade)+' • '+student.track,
                style:TextStyle(fontSize:12.5,
                  color:Theme.of(context).colorScheme.onSurfaceVariant)),
            ])),
          Container(
            padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),
            decoration:BoxDecoration(color:PColors.mint,
              borderRadius:BorderRadius.circular(25)),
            child:Row(mainAxisSize:MainAxisSize.min,children:[
              const Icon(Icons.stars_rounded,size:17,color:PColors.orange),
              const SizedBox(width:5),
              Text(student.xp.toString(),style:const TextStyle(
                fontWeight:FontWeight.w900,color:PColors.midnight)),
            ])),
        ]),
        const SizedBox(height:22),
        _ContinueCard(lesson:next,progress:progress,
          motion:student.animationsEnabled,
          finished:count,total:lessons.length,onPressed: next==null
            ? onSubjects : ()=>onLesson(next)),
        const SizedBox(height:22),
        const RoyalSectionHeading(title:'رحلتك التعليمية',
          subtitle:'كل الأدوات التي تحتاجها في مكان واحد'),
        const SizedBox(height:10),
        LayoutBuilder(builder:(context,box) {
          final width=(box.maxWidth-24)/4;
          return Wrap(spacing:8,runSpacing:5,children:[
            SizedBox(width:width,child:RoyalQuickAction(
              icon:Icons.menu_book_rounded,label:'موادي',
              color:PColors.royal,onTap:onSubjects)),
            SizedBox(width:width,child:RoyalQuickAction(
              icon:Icons.library_books_rounded,label:'كتب الوزارة',
              color:PColors.blue,onTap:onOfficialSources)),
            SizedBox(width:width,child:RoyalQuickAction(
              icon:Icons.psychology_rounded,label:'مراجعتي',
              color:PColors.orange,onTap:onReview)),
            SizedBox(width:width,child:RoyalQuickAction(
              icon:Icons.extension_rounded,label:'الألعاب',
              color:const Color(0xFF8763B8),onTap:onGames)),
            SizedBox(width:width,child:RoyalQuickAction(
              icon:Icons.emoji_events_rounded,label:'إنجازاتي',
              color:PColors.orange,onTap:onAchievements)),
            SizedBox(width:width,child:RoyalQuickAction(
              icon:Icons.psychology_alt_rounded,label:'دفتر أخطائي',
              color:PColors.teal,onTap:onMistakes)),
          ]);
        }),
        const SizedBox(height:18),
        RoyalSectionHeading(title:'المباحث الدراسية',
          subtitle:'اضغط على المادة لاستكمال الدروس',
          action:'عرض الكل',onAction:onSubjects),
        const SizedBox(height:13),
        LayoutBuilder(builder:(context,box){
          final two=box.maxWidth>=355;
          final width=two?(box.maxWidth-11)/2:box.maxWidth;
          return Wrap(spacing:11,runSpacing:11,children:[
            for(final entry in subjects.entries)
              SizedBox(width:width,child:_SubjectSummary(
                name:entry.key,lessons:entry.value,student:student,
                onTap:onSubjects)),
          ]);
        }),
        const SizedBox(height:22),
        Panel(child:InkWell(
          borderRadius:BorderRadius.circular(20),
          onTap:onOfficialSources,
          child:Row(children:[
            Container(height:48,width:48,decoration:BoxDecoration(
              color:const Color(0xFFFFF4D9),
              borderRadius:BorderRadius.circular(15)),
              child:const Icon(Icons.workspace_premium_rounded,
                color:PColors.orange,size:27)),
            const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                const Text('المناهج والكتب الفلسطينية الرسمية',
                  style:TextStyle(fontWeight:FontWeight.w900,fontSize:15)),
                const SizedBox(height:3),
                Text('افتح مصادر وزارة التربية والتعليم',
                  style:TextStyle(fontSize:12,
                    color:Theme.of(context).colorScheme.onSurfaceVariant)),
              ])),
            const Icon(Icons.open_in_new_rounded,color:PColors.orange),
          ]))),
        const SizedBox(height:18),
        Text('ملاحظة: الدروس الحالية أمثلة تجريبية وليست كتب الوزارة.',
          textAlign:TextAlign.center,
          style:TextStyle(fontSize:11.5,
            color:Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.lesson,required this.progress,
    required this.motion,
    required this.finished,required this.total,required this.onPressed});
  final Lesson? lesson;
  final double progress;
  final bool motion;
  final int finished,total;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context)=>Container(
    decoration:BoxDecoration(
      gradient:const LinearGradient(
        colors:[PColors.midnight,PColors.royal,Color(0xFF0C7959)],
        begin:Alignment.topRight,end:Alignment.bottomLeft),
      borderRadius:BorderRadius.circular(28),
      boxShadow:[BoxShadow(color:PColors.midnight.withValues(alpha:.15),
        blurRadius:17,offset:const Offset(0,8))]),
    padding:const EdgeInsets.all(22),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:7),
          decoration:BoxDecoration(
            color:Colors.white.withValues(alpha:.12),
            borderRadius:BorderRadius.circular(14)),
          child:const Text('أكمل من حيث توقفت',
            style:TextStyle(color:PColors.gold,fontWeight:FontWeight.w900))),
        const Spacer(),
        RoyalMotionGraphic(
          asset:'assets/animations/welcome_book.json',
          fallback:Icons.auto_stories_rounded,
          enabled:motion,label:'كتاب المعرفة',size:58),
      ]),
      const SizedBox(height:18),
      Text(lesson?.subject??'ابدأ رحلتك التعليمية',
        style:const TextStyle(color:Color(0xFFE5F4E9),fontSize:13.5)),
      const SizedBox(height:6),
      Text(lesson?.title??'استكشف المواد المناسبة لصفّك',
        maxLines:2,overflow:TextOverflow.ellipsis,
        style:const TextStyle(color:Colors.white,
          fontSize:23,fontWeight:FontWeight.w900,height:1.3)),
      const SizedBox(height:22),
      Row(children:[
        Expanded(child:ClipRRect(
          borderRadius:BorderRadius.circular(8),
          child:TweenAnimationBuilder<double>(
            tween:Tween(begin:0,end:progress),
            duration:const Duration(milliseconds:650),
            builder:(context,value,_)=>LinearProgressIndicator(
              value:value,minHeight:9,color:PColors.gold,
              backgroundColor:Colors.white.withValues(alpha:.21))))),
        const SizedBox(width:10),
        Text((progress*100).round().toString()+'%',
          style:const TextStyle(fontWeight:FontWeight.w900,color:Colors.white)),
      ]),
      const SizedBox(height:8),
      Text('أنجزت '+finished.toString()+' من '+total.toString()+' درس',
        style:const TextStyle(color:Color(0xFFD7EBE0),fontSize:12)),
      const SizedBox(height:17),
      FilledButton.icon(
        style:FilledButton.styleFrom(
          backgroundColor:PColors.gold,foregroundColor:PColors.midnight),
        onPressed:onPressed,
        icon:const Icon(Icons.arrow_back_rounded),
        label:const Text('متابعة التعلّم')),
    ]),
  );
}

class _SubjectSummary extends StatelessWidget {
  const _SubjectSummary({required this.name,required this.lessons,
    required this.student,required this.onTap});
  final String name;
  final List<Lesson> lessons;
  final StudentState student;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context){
    final count=lessons.where((l)=>student.done(l.id)).length;
    final progress=lessons.isEmpty?0.0:count/lessons.length;
    final icon=name.contains('رياضيات')?Icons.functions_rounded:
      name.contains('فيزياء')?Icons.bolt_rounded:
      name.contains('كيمياء')?Icons.science_rounded:
      name.contains('عربية')?Icons.auto_stories_rounded:
      Icons.menu_book_rounded;
    final color=name.contains('رياضيات')?PColors.royal:
      name.contains('فيزياء')?PColors.blue:
      name.contains('كيمياء')?PColors.orange:
      const Color(0xFF7760AB);
    return Card(child:InkWell(
      borderRadius:BorderRadius.circular(23),
      onTap:onTap,
      child:Padding(padding:const EdgeInsets.all(16),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Container(padding:const EdgeInsets.all(9),
              decoration:BoxDecoration(color:color.withValues(alpha:.12),
                borderRadius:BorderRadius.circular(12)),
              child:Icon(icon,color:color,size:23)),
            const Spacer(),
            Text((progress*100).round().toString()+'%',
              style:TextStyle(color:color,fontWeight:FontWeight.w900)),
          ]),
          const SizedBox(height:13),
          Text(name,maxLines:1,overflow:TextOverflow.ellipsis,
            style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),
          const SizedBox(height:4),
          Text(lessons.length.toString()+' دروس متاحة',
            style:TextStyle(fontSize:12,
              color:Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height:13),
          ClipRRect(borderRadius:BorderRadius.circular(12),
            child:LinearProgressIndicator(value:progress,minHeight:7,
              color:color,backgroundColor:color.withValues(alpha:.10))),
        ]))));
  }
}
