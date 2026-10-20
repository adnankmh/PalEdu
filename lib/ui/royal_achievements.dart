import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/study_insights.dart';
import '../state/student_state.dart';
import 'design.dart';
import 'royal_motion.dart';

/// Earned local badges. No fictional streaks or arbitrary leaderboard ranks.
class RoyalAchievementsScreen extends StatelessWidget {
  const RoyalAchievementsScreen({
    super.key,required this.student,required this.lessons,
    required this.onPractice,required this.onSubjects,
  });
  final StudentState student;
  final List<Lesson> lessons;
  final VoidCallback onPractice,onSubjects;

  @override
  Widget build(BuildContext context){
    final stats=StudyInsights(student:student,lessons:lessons);
    final textColor=Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar:AppBar(title:const Text('إنجازاتي التعليمية')),
      body:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:900),
        child:ListView(
          key:const Key('paledu-achievement-center'),
          padding:const EdgeInsets.fromLTRB(18,15,18,32),
          children:[
            Container(
              padding:const EdgeInsets.all(22),
              decoration:BoxDecoration(
                gradient:const LinearGradient(
                  colors:[PColors.midnight,PColors.royal,Color(0xFF0D8060)]),
                borderRadius:BorderRadius.circular(27)),
              child:Row(children:[
                Expanded(child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,children:[
                    const Text('كل خطوة تصنع فرقاً',
                      style:TextStyle(color:Colors.white,fontSize:22,
                        fontWeight:FontWeight.w900)),
                    const SizedBox(height:8),
                    Text(stats.earnedBadges.toString()+' من '+
                      stats.badges.length.toString()+' شارات',
                      style:const TextStyle(color:Color(0xFFE2F4EA),
                        fontWeight:FontWeight.w800)),
                    const SizedBox(height:13),
                    ClipRRect(borderRadius:BorderRadius.circular(10),
                      child:LinearProgressIndicator(
                        value:stats.earnedBadges/stats.badges.length,
                        color:PColors.gold,minHeight:8,
                        backgroundColor:Colors.white24)),
                  ])),
                const SizedBox(width:10),
                RoyalMotionGraphic(
                  asset:'assets/animations/achievement_stars.json',
                  label:'احتفال بالإنجاز',fallback:Icons.emoji_events_rounded,
                  enabled:student.animationsEnabled&&stats.earnedBadges>0,
                  size:94),
              ])),
            const SizedBox(height:20),
            LayoutBuilder(builder:(ctx,box){
              final width=box.maxWidth>=370
                ?(box.maxWidth-20)/3 :box.maxWidth;
              return Wrap(spacing:10,runSpacing:10,children:[
                _metric('الدروس المكتملة',
                  stats.completed.toString()+'/'+stats.total.toString(),
                  Icons.menu_book_rounded,width),
                _metric('أيام المواظبة',stats.streakDays.toString(),
                  Icons.local_fire_department_rounded,width),
                _metric('مراجعات مستحقة',stats.dueReviews.toString(),
                  Icons.event_repeat_rounded,width),
              ]);
            }),
            const SizedBox(height:21),
            const RoyalSectionHeading(title:'هدفي اليومي',
              subtitle:'اختباران تدريبيان في اليوم — العدد من نشاطك الفعلي'),
            const SizedBox(height:12),
            Panel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Row(children:[
                  const Icon(Icons.track_changes_rounded,
                    color:PColors.teal,size:27),
                  const SizedBox(width:10),
                  Expanded(child:Text(stats.todayAttempts.toString()+
                    ' / '+StudyInsights.dailyGoal.toString()+' محاولات',
                    style:const TextStyle(fontWeight:FontWeight.w900))),
                  if(stats.goalProgress>=1)
                    const Icon(Icons.verified_rounded,color:PColors.royal),
                ]),
                const SizedBox(height:12),
                ClipRRect(borderRadius:BorderRadius.circular(10),
                  child:LinearProgressIndicator(
                    value:stats.goalProgress,minHeight:12,
                    backgroundColor:PColors.mint,color:PColors.teal)),
                const SizedBox(height:12),
                FilledButton.icon(onPressed:onPractice,
                  icon:const Icon(Icons.play_arrow_rounded),
                  label:Text(stats.dueReviews>0
                    ?'ابدأ مراجعاتك المستحقة':'ابدأ التدرّب الآن')),
              ])),
            const SizedBox(height:22),
            const RoyalSectionHeading(title:'نشاط الأيام السبعة',
              subtitle:'كل عمود يمثل عدد اختبارات الدروس المنجزة'),
            const SizedBox(height:12),
            Panel(child:Column(children:[
              SizedBox(height:110,child:Row(
                crossAxisAlignment:CrossAxisAlignment.end,
                children:[
                  for(final day in stats.lastSevenDays)
                    Expanded(child:Padding(
                      padding:const EdgeInsets.symmetric(horizontal:4),
                      child:Column(mainAxisAlignment:MainAxisAlignment.end,
                        children:[
                          Text(day.attempts.toString(),
                            style:const TextStyle(fontSize:11,
                              fontWeight:FontWeight.w800)),
                          const SizedBox(height:5),
                          FractionallySizedBox(
                            widthFactor:.72,
                            child:Container(
                              height:10+day.attempts.clamp(0,8)*7.0,
                              decoration:BoxDecoration(
                                color:day.attempts==0
                                  ?PColors.mint:PColors.teal,
                                borderRadius:BorderRadius.circular(9)))),
                          const SizedBox(height:6),
                          Text(day.date.substring(8),
                            style:TextStyle(fontSize:11,color:textColor)),
                        ]))),
                ])),
              const SizedBox(height:10),
              Text('إجمالي اختبارات الأسبوع: '+
                stats.weeklyAttempts.toString(),
                style:TextStyle(color:textColor,fontSize:12)),
            ])),
            const SizedBox(height:22),
            const RoyalSectionHeading(title:'شارات التعلّم',
              subtitle:'تُفتح تلقائياً عند تحقيق شروطها'),
            const SizedBox(height:12),
            LayoutBuilder(builder:(ctx,box){
              final n=box.maxWidth>=690?3:box.maxWidth>=350?2:1;
              final width=(box.maxWidth-10*(n-1))/n;
              return Wrap(spacing:10,runSpacing:10,children:[
                for(final badge in stats.badges)
                  SizedBox(width:width,child:_badgeCard(badge,context)),
              ]);
            }),
            const SizedBox(height:19),
            OutlinedButton.icon(onPressed:onSubjects,
              icon:const Icon(Icons.menu_book_rounded),
              label:const Text('استكشف المواد الدراسية')),
            const SizedBox(height:15),
            Text('هذه شارات تشجيعية مبنية على النشاط المحلي، وليست شهادات رسمية. '
              'يبدأ سجل الممارسة منذ تحديث التطبيق ولا نفترض نشاطاً أقدم.',
              textAlign:TextAlign.center,
              style:TextStyle(fontSize:11.5,color:textColor)),
          ],
        ))),
    );
  }

  Widget _metric(String label,String value,IconData icon,double width)=>
    SizedBox(width:width,child:Panel(child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        Icon(icon,color:PColors.teal,size:27),
        const SizedBox(height:10),
        Text(value,style:const TextStyle(
          fontWeight:FontWeight.w900,fontSize:22)),
        const SizedBox(height:4),
        Text(label,style:const TextStyle(fontSize:12)),
      ])));

  Widget _badgeCard(LearningBadge badge,BuildContext context){
    final color=badge.earned?PColors.royal:
      Theme.of(context).colorScheme.onSurfaceVariant;
    final icons=<String,IconData>{
      'first':Icons.wb_sunny_rounded,
      'explorer':Icons.explore_rounded,
      'focus':Icons.psychology_rounded,
      'streak3':Icons.local_fire_department_rounded,
      'streak7':Icons.star_rounded,
      'mastery':Icons.workspace_premium_rounded,
      'variety':Icons.auto_awesome_rounded,
      'review5':Icons.history_edu_rounded,
    };
    return Card(child:Padding(padding:const EdgeInsets.all(15),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Container(
            width:48,height:48,
            decoration:BoxDecoration(
              color:badge.earned?PColors.mint:
                Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius:BorderRadius.circular(15)),
            child:Icon(icons[badge.id]??Icons.emoji_events_outlined,
              size:26,color:color)),
          const Spacer(),
          Icon(badge.earned?Icons.check_circle_rounded:Icons.lock_outline_rounded,
            color:color,size:19),
        ]),
        const SizedBox(height:12),
        Text(badge.title,maxLines:1,overflow:TextOverflow.ellipsis,
          style:const TextStyle(fontWeight:FontWeight.w900,fontSize:15)),
        const SizedBox(height:6),
        Text(badge.description,maxLines:2,overflow:TextOverflow.ellipsis,
          style:TextStyle(fontSize:12,
            color:Theme.of(context).colorScheme.onSurfaceVariant)),
      ])));
  }
}
