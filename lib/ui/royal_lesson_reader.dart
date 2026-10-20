import 'package:flutter/material.dart';
import '../data/models.dart';
import '../state/student_state.dart';
import 'design.dart';

/// Royal reader with real text, quiz & game navigation, persistent notes.
/// No non-existent PDFs or videos are advertised as playable media.
class RoyalLessonReader extends StatefulWidget {
  const RoyalLessonReader({super.key,required this.lesson,required this.student,
    required this.onQuiz,required this.onFlashcards,required this.onMatch});
  final Lesson lesson;
  final StudentState student;
  final VoidCallback onQuiz,onFlashcards,onMatch;
  @override
  State<RoyalLessonReader> createState()=>_RoyalLessonReaderState();
}

class _RoyalLessonReaderState extends State<RoyalLessonReader> {
  int selected=0;
  Future<void> editNote() async {
    final text=TextEditingController(text:widget.student.noteFor(widget.lesson.id));
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,
      useSafeArea:true,showDragHandle:true,
      builder:(sheetContext)=>Padding(
        padding:EdgeInsets.fromLTRB(22,6,22,
          22+MediaQuery.viewInsetsOf(sheetContext).bottom),
        child:Column(mainAxisSize:MainAxisSize.min,
          crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            const Text('ملاحظاتي على الدرس',
              style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),
            const SizedBox(height:10),
            const Text('تُحفظ على هذا الجهاز فقط وتعمل دون اتصال بالإنترنت.'),
            const SizedBox(height:14),
            TextField(controller:text,maxLines:5,minLines:3,maxLength:2000,
              textInputAction:TextInputAction.newline,
              decoration:const InputDecoration(
                hintText:'اكتب سؤالاً أو فكرة تريد تذكّرها...')),
            const SizedBox(height:12),
            FilledButton.icon(icon:const Icon(Icons.save_rounded),
              onPressed:() async {
                await widget.student.saveLessonNote(widget.lesson.id,text.text);
                if(sheetContext.mounted)Navigator.pop(sheetContext);
              },
              label:const Text('حفظ الملاحظة')),
          ])));
    text.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final lesson=widget.lesson;
    return AnimatedBuilder(animation:widget.student,
      builder:(context,_)=>Scaffold(
        appBar:AppBar(
          title:Text(lesson.subject,maxLines:1,
            overflow:TextOverflow.ellipsis),
          actions:[
            IconButton(tooltip:'تصغير الخط',onPressed:()=>widget.student.appearance(
              textScale:(widget.student.scale-.1).clamp(.9,1.3)),
              icon:const Icon(Icons.text_decrease_rounded)),
            IconButton(tooltip:'تكبير الخط',onPressed:()=>widget.student.appearance(
              textScale:(widget.student.scale+.1).clamp(.9,1.3)),
              icon:const Icon(Icons.text_increase_rounded)),
            IconButton(tooltip:'حفظ الدرس',onPressed:()=>
              widget.student.toggleSaved(lesson.id),
              icon:Icon(widget.student.saved(lesson.id)
                ? Icons.bookmark_rounded:Icons.bookmark_border_rounded)),
          ]),
        body:Center(child:ConstrainedBox(
          constraints:const BoxConstraints(maxWidth:900),
          child:ListView(
            key:const Key('royal-lesson-reader'),
            padding:const EdgeInsets.fromLTRB(18,13,18,32),
            children:[
              Text('المادة: '+lesson.subject+
                ' • '+lesson.duration.toString()+' دقائق',
                style:TextStyle(fontSize:12.5,
                  color:Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height:12),
              Container(padding:const EdgeInsets.all(23),
                decoration:BoxDecoration(
                  gradient:const LinearGradient(
                    colors:[PColors.midnight,PColors.royal],
                    begin:Alignment.topRight,end:Alignment.bottomLeft),
                  borderRadius:BorderRadius.circular(26)),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,
                  children:[
                    const Text('✦ رحلة تعلّم تفاعلية',
                      style:TextStyle(color:PColors.gold,
                        fontWeight:FontWeight.w900)),
                    const SizedBox(height:12),
                    Text(lesson.title,style:const TextStyle(color:Colors.white,
                      fontSize:25,height:1.35,fontWeight:FontWeight.w900)),
                    const SizedBox(height:10),
                    Text(lesson.summary,style:const TextStyle(
                      color:Color(0xFFE2F3E8),height:1.6)),
                  ])),
              const SizedBox(height:17),
              SingleChildScrollView(scrollDirection:Axis.horizontal,
                child:Wrap(spacing:9,children:[
                  ChoiceChip(label:const Text('الشرح والكتاب'),
                    avatar:const Icon(Icons.menu_book_rounded,size:18),
                    selected:selected==0,
                    onSelected:(_)=>setState(()=>selected=0)),
                  ChoiceChip(label:const Text('اختبر نفسك'),
                    avatar:const Icon(Icons.fact_check_rounded,size:18),
                    selected:selected==1,
                    onSelected:(_)=>setState(()=>selected=1)),
                  ChoiceChip(label:const Text('المراجعة والألعاب'),
                    avatar:const Icon(Icons.extension_rounded,size:18),
                    selected:selected==2,
                    onSelected:(_)=>setState(()=>selected=2)),
                ])),
              const SizedBox(height:17),
              if(selected==0) ...[
                RoyalSectionHeading(title:'الشرح المبسط',
                  subtitle:'فقرات قصيرة للمراجعة والفهم'),
                const SizedBox(height:12),
                if(lesson.sections.isEmpty) const Panel(
                  child:Text('لم يُنشر شرح لهذا الدرس بعد.')),
                for(int i=0;i<lesson.sections.length;i++) ...[
                  Panel(child:Row(crossAxisAlignment:CrossAxisAlignment.start,
                    children:[
                      CircleAvatar(radius:18,backgroundColor:PColors.mint,
                        child:Text((i+1).toString(),style:const TextStyle(
                          color:PColors.midnight,fontWeight:FontWeight.w900))),
                      const SizedBox(width:13),
                      Expanded(child:Text(lesson.sections[i],
                        style:const TextStyle(fontSize:16.5,height:1.8))),
                    ])),
                  const SizedBox(height:11),
                ],
                const SizedBox(height:12),
                FilledButton.icon(onPressed:widget.onQuiz,
                  icon:const Icon(Icons.arrow_back_rounded),
                  label:const Text('انتقل إلى اختبار الدرس')),
              ] else if(selected==1) ...[
                RoyalSectionHeading(title:'اختبر فهمك',
                  subtitle:'تغذية راجعة ونتائج مرتبطة بإنجازك'),
                const SizedBox(height:14),
                Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
                  children:[
                    const Icon(Icons.quiz_outlined,size:37,color:PColors.teal),
                    const SizedBox(height:10),
                    Text('عدد الأسئلة: '+lesson.questions.length.toString(),
                      style:const TextStyle(fontSize:18,
                        fontWeight:FontWeight.w900)),
                    const SizedBox(height:8),
                    if(lesson.questions.isNotEmpty)
                      Text(lesson.questions.first.prompt,
                        style:const TextStyle(fontSize:16)),
                    const SizedBox(height:12),
                    FilledButton.icon(onPressed:widget.onQuiz,
                      icon:const Icon(Icons.play_arrow_rounded),
                      label:const Text('ابدأ الاختبار التفاعلي')),
                  ])),
              ] else ...[
                RoyalSectionHeading(title:'مراجعة ممتعة',
                  subtitle:'أنشطة قصيرة لترسيخ المعرفة'),
                const SizedBox(height:13),
                Panel(child:ListTile(
                  leading:const Icon(Icons.style_rounded,
                    color:PColors.teal,size:29),
                  title:const Text('بطاقات الذاكرة',style:TextStyle(
                    fontWeight:FontWeight.w900)),
                  subtitle:const Text('اكتشف الإجابات بطاقة تلو الأخرى'),
                  trailing:const Icon(Icons.chevron_left_rounded),
                  onTap:widget.onFlashcards)),
                const SizedBox(height:10),
                Panel(child:ListTile(
                  leading:const Icon(Icons.extension_rounded,
                    color:PColors.orange,size:29),
                  title:const Text('لعبة المطابقة',style:TextStyle(
                    fontWeight:FontWeight.w900)),
                  subtitle:const Text('اربط السؤال بإجابته الصحيحة'),
                  trailing:const Icon(Icons.chevron_left_rounded),
                  onTap:widget.onMatch)),
              ],
              const SizedBox(height:20),
              Panel(child:InkWell(
                borderRadius:BorderRadius.circular(20),
                onTap:editNote,
                child:Row(children:[
                  const Icon(Icons.edit_note_rounded,
                    size:31,color:PColors.teal),
                  const SizedBox(width:13),
                  Expanded(child:Column(
                    crossAxisAlignment:CrossAxisAlignment.start,children:[
                      const Text('ملاحظاتي',
                        style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),
                      const SizedBox(height:4),
                      Text(widget.student.noteFor(lesson.id).isEmpty
                        ? 'اضغط لكتابة ملاحظة خاصة بهذا الدرس'
                        :widget.student.noteFor(lesson.id),
                        maxLines:2,overflow:TextOverflow.ellipsis,
                        style:TextStyle(color:Theme.of(context)
                          .colorScheme.onSurfaceVariant,fontSize:13)),
                    ])),
                  const Icon(Icons.add_rounded,color:PColors.teal),
                ]))),
              const SizedBox(height:13),
              const Text('الشرح المعروض تجريبي. المواد والوسائط الرسمية تُضاف بعد المراجعة والاعتماد.',
                textAlign:TextAlign.center,
                style:TextStyle(fontSize:11.5)),
            ]))),
      ));
  }
}
