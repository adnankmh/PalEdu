import 'package:flutter/material.dart';
import '../data/models.dart';
import '../state/student_state.dart';
import 'design.dart';

typedef WrongQuestion=({Lesson lesson,int index});

List<WrongQuestion> pendingWrongQuestions(
    StudentState student,Iterable<Lesson> lessons) {
  return [
    for(final lesson in lessons)
      for(var i=0;i<lesson.questions.length;i++)
        if(student.mistakes.contains(lesson,i))
          (lesson:lesson,index:i),
  ];
}

/// A calm personal remedial space based on missed lesson quiz questions.
class RoyalMistakeNotebook extends StatelessWidget {
  const RoyalMistakeNotebook({
    super.key,required this.student,required this.lessons});
  final StudentState student;
  final List<Lesson> lessons;

  @override
  Widget build(BuildContext context)=>AnimatedBuilder(
    animation:student,
    builder:(context,_) {
      final pending=pendingWrongQuestions(student,lessons);
      return Scaffold(
        appBar:AppBar(title:const Text('دفتر أخطائي')),
        body:Center(child:ConstrainedBox(
          constraints:const BoxConstraints(maxWidth:850),
          child:ListView(
            key:const Key('mistake-notebook'),
            padding:const EdgeInsets.fromLTRB(18,16,18,35),
            children:[
              Container(
                padding:const EdgeInsets.all(22),
                decoration:BoxDecoration(
                  gradient:const LinearGradient(colors:[
                    PColors.midnight,PColors.royal,Color(0xFF087E67)]),
                  borderRadius:BorderRadius.circular(26)),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  const Icon(Icons.psychology_alt_outlined,
                    color:PColors.gold,size:38),
                  const SizedBox(height:12),
                  const Text('تعلّم من محاولاتك',
                    style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,
                      fontSize:23)),
                  const SizedBox(height:7),
                  Text('أسئلة تحتاج مراجعة: '+pending.length.toString(),
                    style:const TextStyle(color:Color(0xFFE2F4EC),
                      fontSize:14)),
                  const SizedBox(height:14),
                  FilledButton.icon(
                    onPressed:pending.isEmpty?null:()=>
                      Navigator.push(context,MaterialPageRoute<void>(
                        builder:(_)=>MistakeDrillScreen(
                          student:student,questions:pending))),
                    style:FilledButton.styleFrom(backgroundColor:PColors.gold,
                      foregroundColor:PColors.midnight),
                    icon:const Icon(Icons.play_arrow_rounded),
                    label:const Text('ابدأ تصحيح أخطائي')),
                ])),
              const SizedBox(height:18),
              if(pending.isEmpty)
                const Panel(child:Column(children:[
                  Icon(Icons.verified_rounded,color:PColors.teal,size:44),
                  SizedBox(height:9),
                  Text('لا توجد أسئلة خاطئة تحتاج المراجعة.',
                    textAlign:TextAlign.center,
                    style:TextStyle(fontWeight:FontWeight.w800)),
                  SizedBox(height:7),
                  Text('بعد إنهاء اختبار درس، ستظهر هنا الأسئلة التي تحتاج تدريباً.'),
                ]))
              else ...[
                const RoyalSectionHeading(title:'أسئلة للمراجعة',
                  subtitle:'اختر درساً أو ابدأ التدريب على جميع الأخطاء'),
                const SizedBox(height:10),
                for(final lesson in lessons)
                  if(pending.any((e)=>e.lesson.id==lesson.id))
                    Padding(
                      padding:const EdgeInsets.only(bottom:10),
                      child:Card(child:ListTile(
                        contentPadding:const EdgeInsets.all(14),
                        leading:const CircleAvatar(
                          backgroundColor:PColors.mint,
                          child:Icon(Icons.auto_stories_rounded,
                            color:PColors.royal)),
                        title:Text(lesson.title,
                          style:const TextStyle(fontWeight:FontWeight.w900)),
                        subtitle:Text(lesson.subject+' • '+
                          pending.where((e)=>e.lesson.id==lesson.id)
                            .length.toString()+' أسئلة'),
                        trailing:const Icon(Icons.chevron_left_rounded),
                        onTap:()=>Navigator.push(context,MaterialPageRoute<void>(
                          builder:(_)=>MistakeDrillScreen(
                            student:student,questions:pending
                              .where((e)=>e.lesson.id==lesson.id).toList()))),
                      ))),
              ],
              const SizedBox(height:17),
              Text('تُحفظ على هذا الجهاز بصمات الأسئلة فقط دون نص إجاباتك. '
                'لا تُحتسب تدريبات التصحيح نقاطاً أو اختبارات رسمية.',
                textAlign:TextAlign.center,
                style:TextStyle(fontSize:11.5,
                  color:Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ))),
      );
    },
  );
}

/// A correct self-test response removes the mistake; merely viewing the
/// solution does not. Wrong answers remain available for another attempt.
class MistakeDrillScreen extends StatefulWidget {
  const MistakeDrillScreen({
    super.key,required this.student,required this.questions});
  final StudentState student;
  final List<WrongQuestion> questions;
  @override
  State<MistakeDrillScreen> createState()=>_MistakeDrillScreenState();
}
class _MistakeDrillScreenState extends State<MistakeDrillScreen>{
  int position=0,corrected=0;
  int? selected;
  bool saving=false;
  Future<void> choose(int answer) async {
    if(selected!=null||saving||position>=widget.questions.length)return;
    setState((){
      selected=answer;
      saving=true;
    });
    final record=widget.questions[position];
    if(answer==record.lesson.questions[record.index].correct){
      try {
        await widget.student.resolveWrongAnswer(record.lesson,record.index);
        corrected++;
      }catch(_){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content:Text('تعذّر حفظ التقدّم، حاول لاحقاً.')));
      }
    }
    if(mounted)setState(()=>saving=false);
  }
  @override
  Widget build(BuildContext context){
    final total=widget.questions.length;
    final finished=position>=total;
    return Scaffold(
      appBar:AppBar(title:const Text('تدريب تصحيح الأخطاء')),
      body:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:760),
        child:ListView(padding:const EdgeInsets.all(18),children:[
          if(finished)...[
            const SizedBox(height:28),
            const Icon(Icons.verified_rounded,color:PColors.royal,size:78),
            const SizedBox(height:14),
            Text('صححت '+corrected.toString()+' من '+total.toString()+' أسئلة',
              textAlign:TextAlign.center,
              style:const TextStyle(fontWeight:FontWeight.w900,fontSize:22)),
            const SizedBox(height:8),
            const Text('الأسئلة التي لم تُجب عنها بشكل صحيح تبقى في دفترك.',
              textAlign:TextAlign.center),
            const SizedBox(height:20),
            FilledButton(
              onPressed:()=>Navigator.pop(context),
              child:const Text('العودة إلى دفتر أخطائي')),
          ]else...[
            Text('السؤال '+(position+1).toString()+' من '+total.toString(),
              style:const TextStyle(fontWeight:FontWeight.w800)),
            const SizedBox(height:8),
            LinearProgressIndicator(value:(position+1)/total,minHeight:9),
            const SizedBox(height:18),
            Text(widget.questions[position].lesson.subject,
              style:TextStyle(color:Theme.of(context)
                .colorScheme.onSurfaceVariant)),
            const SizedBox(height:8),
            Panel(child:Text(
              widget.questions[position].lesson.questions[
                widget.questions[position].index].prompt,
              style:const TextStyle(fontWeight:FontWeight.w900,fontSize:20))),
            const SizedBox(height:12),
            for(var i=0;i<widget.questions[position].lesson.questions[
                widget.questions[position].index].options.length;i++)...[
              Card(child:ListTile(
                onTap:selected==null?()=>choose(i):null,
                title:Text(widget.questions[position].lesson.questions[
                  widget.questions[position].index].options[i]),
                leading:Icon(selected==null?Icons.circle_outlined:
                  i==widget.questions[position].lesson.questions[
                    widget.questions[position].index].correct
                      ?Icons.check_circle_rounded:
                      selected==i?Icons.cancel_rounded:Icons.circle_outlined,
                  color:selected==null?PColors.teal:
                    i==widget.questions[position].lesson.questions[
                      widget.questions[position].index].correct
                        ?PColors.royal:
                        selected==i?Colors.red:PColors.muted),
              )),
              const SizedBox(height:6),
            ],
            if(selected!=null)...[
              const SizedBox(height:12),
              Panel(child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(selected==widget.questions[position].lesson.questions[
                      widget.questions[position].index].correct
                    ?'إجابة صحيحة — أحسنت!':'راجع الحل الصحيح',
                    style:const TextStyle(fontWeight:FontWeight.w900)),
                  const SizedBox(height:9),
                  Text(widget.questions[position].lesson.questions[
                    widget.questions[position].index].explanation),
                ])),
              const SizedBox(height:14),
              FilledButton.icon(
                onPressed:saving?null:()=>setState((){
                  position++;selected=null;
                }),
                icon:const Icon(Icons.arrow_back_rounded),
                label:Text(position+1==total?'عرض النتيجة':'السؤال التالي')),
            ],
          ],
        ]))),
    );
  }
}
