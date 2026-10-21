import 'package:flutter/material.dart';
import 'design.dart';

/// Read an approved worksheet/photo *inside* PalEdu, not in a browser.
class InternalImageViewer extends StatelessWidget {
  const InternalImageViewer({super.key,required this.title,required this.url});
  final String title,url;

  @override
  Widget build(BuildContext context) {
    final uri=Uri.tryParse(url);
    final safe=uri!=null&&uri.scheme=='https'&&uri.host.isNotEmpty;
    return Scaffold(
      appBar:AppBar(title:Text(title,maxLines:1,
        overflow:TextOverflow.ellipsis)),
      body:!safe
        ?const Center(child:Text('رابط الصورة غير صالح أو غير آمن.'))
        :Column(children:[
          const Padding(padding:EdgeInsets.all(12),
            child:Row(children:[
              Icon(Icons.zoom_in_rounded,color:PColors.teal),
              SizedBox(width:8),
              Expanded(child:Text('استخدم إصبعين للتكبير والتصغير وتحريك الصورة.')),
            ])),
          Expanded(child:InteractiveViewer(
            minScale:0.65,maxScale:5,
            child:Center(child:Image.network(url,
              fit:BoxFit.contain,
              loadingBuilder:(context,child,progress)=>progress==null
                ?child:const Center(child:CircularProgressIndicator()),
              errorBuilder:(context,error,stack)=>
                const Center(child:Padding(
                  padding:EdgeInsets.all(22),
                  child:Text('تعذّر تحميل الصورة. تحقق من الإنترنت وصلاحية الملف.',
                    textAlign:TextAlign.center))),
            )))),
        ]),
    );
  }
}
