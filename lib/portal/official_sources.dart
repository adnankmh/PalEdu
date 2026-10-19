import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ui/design.dart';

/// Authoritative ministry links, not locally copied or rehosted books.
class OfficialSourcesScreen extends StatelessWidget {
  const OfficialSourcesScreen({super.key});
  Future<void> open(BuildContext context,String source) async {
    final uri=Uri.parse(source);
    final ok=await launchUrl(uri,mode:LaunchMode.externalApplication);
    if(!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('تعذر فتح مصدر الوزارة الآن')));
    }
  }
  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('المناهج الفلسطينية الرسمية')),
    body:Center(child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:850),
      child:ListView(padding:const EdgeInsets.all(20),children:[
        Container(padding:const EdgeInsets.all(24),
          decoration:BoxDecoration(
            gradient:const LinearGradient(
              colors:[PColors.midnight,PColors.royal]),
            borderRadius:BorderRadius.circular(27)),
          child:const Column(crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Icon(Icons.verified_rounded,color:PColors.gold,size:42),
              SizedBox(height:10),
              Text('من المصدر الرسمي مباشرة',
                style:TextStyle(color:Colors.white,
                  fontSize:25,fontWeight:FontWeight.w900)),
              SizedBox(height:9),
              Text('روابط موثقة لوزارة التربية والتعليم الفلسطينية',
                style:TextStyle(color:Colors.white)),
            ])),
        const SizedBox(height:20),
        Panel(child:ListTile(
          leading:const Icon(Icons.library_books_rounded,
            color:PColors.teal,size:35),
          title:const Text('الرزم التعليمية — الصف الأول حتى الثاني عشر',
            style:TextStyle(fontWeight:FontWeight.w900)),
          subtitle:const Text('جميع الصفوف والتخصصات المتوفرة لدى الوزارة'),
          trailing:const Icon(Icons.open_in_new_rounded),
          onTap:()=>open(context,'https://www.moe.edu.ps/gaza/subjects'))),
        const SizedBox(height:12),
        Panel(child:ListTile(
          leading:const Icon(Icons.menu_book_rounded,
            color:PColors.teal,size:35),
          title:const Text('كتب التوجيهي الرسمية',
            style:TextStyle(fontWeight:FontWeight.w900)),
          subtitle:const Text('روابط كتب الصف الثاني عشر حسب الفرع'),
          trailing:const Icon(Icons.open_in_new_rounded),
          onTap:()=>open(context,'https://www.moe.edu.ps/class12/books'))),
        const SizedBox(height:20),
        const Panel(child:Text(
          'تُفتح المصادر على موقع الوزارة. لا يقوم التطبيق حالياً بنسخ أو استضافة الكتب الرسمية، وسيُضاف قارئ داخلي بعد مراجعة الأذونات والنسخ الدراسية المعتمدة.')),
      ]))),
  );
}
