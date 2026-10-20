import 'package:flutter/material.dart';
import 'design.dart';

/// Reusable role-specific layouts. Metric values must be sourced from real data.
class RoyalPortalBanner extends StatelessWidget {
  const RoyalPortalBanner({super.key,required this.icon,required this.title,
    required this.subtitle,this.actionLabel,this.onAction});
  final IconData icon;
  final String title,subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    width:double.infinity,
    padding:const EdgeInsets.all(23),
    decoration:BoxDecoration(
      gradient:const LinearGradient(
        begin:Alignment.topRight,end:Alignment.bottomLeft,
        colors:[PColors.midnight,PColors.royal,Color(0xFF117B5E)]),
      borderRadius:BorderRadius.circular(27)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(
        color:Colors.white.withValues(alpha:.12),
        borderRadius:BorderRadius.circular(15)),
        child:Icon(icon,color:PColors.gold,size:29)),
      const SizedBox(height:13),
      Text(title,style:const TextStyle(color:Colors.white,fontSize:24,
        height:1.3,fontWeight:FontWeight.w900)),
      const SizedBox(height:7),
      Text(subtitle,style:const TextStyle(
        fontSize:13.5,color:Color(0xFFE1F1E9))),
      if(actionLabel!=null&&onAction!=null) ...[
        const SizedBox(height:15),
        FilledButton.icon(
          onPressed:onAction,
          style:FilledButton.styleFrom(
            foregroundColor:PColors.midnight,backgroundColor:PColors.gold),
          icon:const Icon(Icons.add_rounded),
          label:Text(actionLabel!)),
      ],
    ]));
}

class RoyalMetricTile extends StatelessWidget {
  const RoyalMetricTile({super.key,required this.label,required this.value,
    required this.icon,this.color=PColors.teal});
  final String label,value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context)=>Card(
    child:Padding(padding:const EdgeInsets.all(15),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        Icon(icon,color:color,size:26),
        const SizedBox(height:9),
        Text(value,maxLines:1,overflow:TextOverflow.ellipsis,
          style:Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight:FontWeight.w900)),
        const SizedBox(height:3),
        Text(label,maxLines:2,style:TextStyle(fontSize:12,
          color:Theme.of(context).colorScheme.onSurfaceVariant)),
      ])));
}

/// LayoutBuilder avoids 2-column overflow on narrow phones.
class RoyalMetricsGrid extends StatelessWidget {
  const RoyalMetricsGrid({super.key,required this.metrics});
  final List<RoyalMetricTile> metrics;
  @override
  Widget build(BuildContext context)=>LayoutBuilder(
    builder:(context,box){
      final count=box.maxWidth>=740?4:box.maxWidth>=300?2:1;
      final width=(box.maxWidth-10*(count-1))/count;
      return Wrap(spacing:10,runSpacing:10,children:[
        for(final tile in metrics) SizedBox(width:width,child:tile),
      ]);
    });
}

class RoyalStatusPill extends StatelessWidget {
  const RoyalStatusPill({super.key,required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color=switch(status){
      'published'=>PColors.royal,
      'pending'=>PColors.orange,
      'rejected'=>const Color(0xFFC14954),
      'draft'=>PColors.blue,
      _=>Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final label=switch(status){
      'published'=>'منشور',
      'pending'=>'بانتظار المراجعة',
      'rejected'=>'مرفوض',
      'draft'=>'مسودة',
      _=>'غير معروف',
    };
    return Container(
      padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
      decoration:BoxDecoration(
        color:color.withValues(alpha:.10),
        borderRadius:BorderRadius.circular(30)),
      child:Text(label,style:TextStyle(
        fontSize:11,color:color,fontWeight:FontWeight.w800)));
  }
}

class RoyalEmptyState extends StatelessWidget {
  const RoyalEmptyState({super.key,required this.title,
    required this.message,this.actionLabel,this.onAction});
  final String title,message;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context)=>Panel(
    child:Padding(padding:const EdgeInsets.symmetric(vertical:22),
      child:Column(children:[
        const Icon(Icons.inbox_outlined,color:PColors.teal,size:45),
        const SizedBox(height:11),
        Text(title,textAlign:TextAlign.center,style:const TextStyle(
          fontSize:17,fontWeight:FontWeight.w900)),
        const SizedBox(height:5),
        Text(message,textAlign:TextAlign.center,
          style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),
        if(actionLabel!=null&&onAction!=null) ...[
          const SizedBox(height:13),
          FilledButton(onPressed:onAction,child:Text(actionLabel!)),
        ],
      ])));
}

class RoyalAuthorResourceCard extends StatelessWidget {
  const RoyalAuthorResourceCard({super.key,required this.title,
    required this.subject,required this.grade,required this.kind,
    required this.status});
  final String title,subject,grade,kind,status;
  @override
  Widget build(BuildContext context)=>Card(
    child:Padding(padding:const EdgeInsets.all(15),
      child:Row(children:[
        Container(width:47,height:47,
          decoration:BoxDecoration(color:PColors.mint,
            borderRadius:BorderRadius.circular(14)),
          child:Icon(kind=='video'?Icons.play_circle_outline_rounded:
            kind=='book'?Icons.menu_book_rounded:
            kind=='handout'?Icons.description_outlined:
            Icons.article_outlined,color:PColors.royal,size:27)),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Text(title,maxLines:2,overflow:TextOverflow.ellipsis,
              style:const TextStyle(fontSize:15,fontWeight:FontWeight.w900)),
            const SizedBox(height:4),
            Text('$subject • الصف $grade',maxLines:1,
              overflow:TextOverflow.ellipsis,
              style:TextStyle(fontSize:12,
                color:Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height:7),
            Align(alignment:Alignment.centerRight,
              child:RoyalStatusPill(status:status)),
          ])),
      ])));
}

class RoyalApprovalCard extends StatelessWidget {
  const RoyalApprovalCard({super.key,required this.title,
    required this.description,required this.onApprove,required this.onReject,
    this.metadata});
  final String title,description;
  final String? metadata;
  final VoidCallback onApprove,onReject;
  @override
  Widget build(BuildContext context)=>Card(
    child:Padding(padding:const EdgeInsets.all(17),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          const Icon(Icons.fact_check_outlined,color:PColors.teal),
          const SizedBox(width:9),
          Expanded(child:Text(title,
            style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16))),
        ]),
        if(metadata!=null&&metadata!.isNotEmpty) ...[
          const SizedBox(height:9),
          Text(metadata!,style:TextStyle(fontSize:12,
            color:Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
        const SizedBox(height:9),
        Text(description,maxLines:6,overflow:TextOverflow.ellipsis),
        const SizedBox(height:15),
        Wrap(spacing:9,runSpacing:8,children:[
          FilledButton.icon(onPressed:onApprove,
            icon:const Icon(Icons.check_circle_outline,size:18),
            label:const Text('مراجعة واعتماد')),
          OutlinedButton.icon(onPressed:onReject,
            icon:const Icon(Icons.block_outlined,size:18),
            label:const Text('رفض الطلب')),
        ]),
      ])));
}
