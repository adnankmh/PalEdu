import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'design.dart';

/// View streaming remote PDFs inside PalEdu, including private signed URLs.
/// The application does not redistribute or bundle ministry-owned books.
class InternalPdfReader extends StatefulWidget {
  const InternalPdfReader({super.key,required this.title,required this.url,
    required this.documentId});
  final String title,url,documentId;
  @override
  State<InternalPdfReader> createState()=>_InternalPdfReaderState();
}
class _InternalPdfReaderState extends State<InternalPdfReader> {
  final controller=PdfViewerController();
  int page=1,initial=1;
  bool ready=false,bookmarked=false;
  String get keyPage=>'paledu_pdf_page_'+widget.documentId;
  String get keySaved=>'paledu_pdf_bookmark_'+widget.documentId;
  @override
  void initState(){super.initState();restore();}
  Future<void> restore() async {
    final p=await SharedPreferences.getInstance();
    if(mounted)setState(() {
      initial=p.getInt(keyPage)??1;
      page=initial;bookmarked=p.getBool(keySaved)??false;ready=true;
    });
  }
  Future<void> savePage(int n) async {
    if(n<1)return;
    if(mounted)setState(()=>page=n);
    (await SharedPreferences.getInstance()).setInt(keyPage,n);
  }
  Future<void> toggle() async {
    final next=!bookmarked;
    await (await SharedPreferences.getInstance()).setBool(keySaved,next);
    if(mounted)setState(()=>bookmarked=next);
  }
  Future<void> jump() async {
    final input=TextEditingController(text:page.toString());
    final result=await showDialog<int>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('انتقل إلى صفحة'),
      content:TextField(controller:input,autofocus:true,
        keyboardType:TextInputType.number,
        decoration:const InputDecoration(labelText:'رقم الصفحة')),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),
          child:const Text('إلغاء')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,
          int.tryParse(input.text.trim())),child:const Text('انتقال')),
      ]));
    input.dispose();
    if(result==null||!controller.isReady||
      result<1||result>controller.pageCount)return;
    await controller.goToPage(pageNumber:result);
  }
  @override
  void dispose(){controller.dispose();super.dispose();}
  @override
  Widget build(BuildContext context){
    final uri=Uri.tryParse(widget.url);
    final valid=uri!=null&&uri.scheme=='https'&&uri.host.isNotEmpty;
    return Scaffold(
      appBar:AppBar(
        title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(widget.title,maxLines:1,overflow:TextOverflow.ellipsis,
            style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),
          Text('قارئ الكتب الداخلي',style:TextStyle(fontSize:11,
            color:Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
        actions:[
          IconButton(tooltip:'حفظ في مكتبتي',onPressed:toggle,
            icon:Icon(bookmarked?Icons.bookmark_rounded:
              Icons.bookmark_border_rounded)),
          IconButton(tooltip:'اذهب إلى صفحة',onPressed:jump,
            icon:const Icon(Icons.find_in_page_outlined)),
        ]),
      body:!ready?const Center(child:CircularProgressIndicator()):
        !valid?const Center(child:Text('رابط الملف غير صالح.')):
        PdfViewer.uri(uri,
          key:ValueKey(widget.documentId),
          controller:controller,
          initialPageNumber:initial,
          params:PdfViewerParams(
            onPageChanged:(number){
              if(number!=null&&number!=page)savePage(number);
            },
            backgroundColor:Theme.of(context).colorScheme.surfaceContainer,
          )),
      bottomNavigationBar:SafeArea(child:Padding(
        padding:const EdgeInsets.fromLTRB(14,5,14,8),
        child:Row(children:[
          IconButton(tooltip:'السابق',
            onPressed:!controller.isReady||page<=1?null:()=>
              controller.goToPage(pageNumber:page-1),
            icon:const Icon(Icons.chevron_right_rounded)),
          Expanded(child:Text(controller.isReady
            ?'صفحة '+page.toString()+' من '+controller.pageCount.toString()
            :'جارٍ التحميل',textAlign:TextAlign.center,
            style:const TextStyle(fontWeight:FontWeight.w800))),
          IconButton(tooltip:'التالي',
            onPressed:!controller.isReady||page>=controller.pageCount
              ?null:()=>controller.goToPage(pageNumber:page+1),
            icon:const Icon(Icons.chevron_left_rounded)),
        ]))),
    );
  }
}
