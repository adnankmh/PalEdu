import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'design.dart';

/// Streams direct HTTPS MP4/HLS lessons within PalEdu.
class InternalVideoPlayer extends StatefulWidget {
  const InternalVideoPlayer({super.key,required this.title,required this.url});
  final String title,url;
  @override
  State<InternalVideoPlayer> createState()=>_InternalVideoPlayerState();
}
class _InternalVideoPlayerState extends State<InternalVideoPlayer> {
  VideoPlayerController? player;
  String? error;
  bool ready=false;
  double speed=1;
  @override
  void initState(){super.initState();init();}
  Future<void> init() async {
    final uri=Uri.tryParse(widget.url);
    if(uri==null||uri.scheme!='https'){
      if(mounted)setState(()=>error='رابط الفيديو غير صالح.');return;
    }
    final path=uri.path.toLowerCase();
    if(!path.endsWith('.mp4')&&!path.endsWith('.m3u8')){
      if(mounted)setState(()=>error=
        'هذا الرابط ليس ملف فيديو مباشرًا. '
        'يدعم المشغل الداخلي روابط MP4 وHLS حالياً.');
      return;
    }
    try{
      final c=VideoPlayerController.networkUrl(uri);
      player=c;
      await c.initialize();
      c.addListener(onChanged);
      if(mounted)setState(()=>ready=true);
    }catch(_){
      if(mounted)setState(()=>error=
        'تعذر تشغيل الفيديو. تحقق من الرابط أو الاتصال.');
    }
  }
  void onChanged(){if(mounted)setState((){});}
  @override
  void dispose(){
    player?.removeListener(onChanged);
    player?.dispose();super.dispose();
  }
  String time(Duration d){
    final minutes=d.inMinutes.toString().padLeft(2,'0');
    final seconds=(d.inSeconds%60).toString().padLeft(2,'0');
    return minutes+':'+seconds;
  }
  @override
  Widget build(BuildContext context){
    final c=player;
    final duration=c?.value.duration??Duration.zero;
    final position=c?.value.position??Duration.zero;
    return Scaffold(
      appBar:AppBar(title:Text(widget.title,
        maxLines:1,overflow:TextOverflow.ellipsis)),
      body:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:950),
        child:ListView(padding:const EdgeInsets.all(18),children:[
          const RoyalSectionHeading(title:'مشاهدة داخل PalEdu'),
          const SizedBox(height:15),
          ClipRRect(borderRadius:BorderRadius.circular(22),
            child:AspectRatio(aspectRatio:ready&&c!=null&&
                c.value.aspectRatio>0?c.value.aspectRatio:16/9,
              child:Container(color:PColors.midnight,
                child:error!=null?Center(
                  child:Padding(padding:const EdgeInsets.all(20),
                    child:Text(error!,textAlign:TextAlign.center,
                      style:const TextStyle(color:Colors.white)))):
                !ready||c==null
                  ?const Center(child:CircularProgressIndicator())
                  :Stack(children:[
                    Center(child:AspectRatio(
                      aspectRatio:c.value.aspectRatio,child:VideoPlayer(c))),
                    if(c.value.isBuffering)
                      const Center(child:CircularProgressIndicator()),
                  ])))),
          if(ready&&c!=null)...[
            const SizedBox(height:16),
            Slider(
              value:position.inMilliseconds.toDouble()
                .clamp(0,duration.inMilliseconds.toDouble().clamp(1,double.infinity)),
              max:duration.inMilliseconds.toDouble().clamp(1,double.infinity),
              onChanged:(v)=>c.seekTo(Duration(milliseconds:v.round()))),
            Row(children:[
              IconButton(tooltip:'رجوع 10 ثوان',
                onPressed:()=>c.seekTo(position-const Duration(seconds:10)),
                icon:const Icon(Icons.replay_10)),
              IconButton(tooltip:c.value.isPlaying?'إيقاف مؤقت':'تشغيل',
                onPressed:()=>c.value.isPlaying?c.pause():c.play(),
                icon:Icon(c.value.isPlaying
                  ?Icons.pause_circle_filled:Icons.play_circle_fill,size:42)),
              IconButton(tooltip:'تقدم 10 ثوان',
                onPressed:()=>c.seekTo(position+const Duration(seconds:10)),
                icon:const Icon(Icons.forward_10)),
              const Spacer(),
              Text(time(position)+' / '+time(duration),
                style:const TextStyle(fontSize:12)),
              PopupMenuButton<double>(
                tooltip:'سرعة التشغيل',
                initialValue:speed,
                onSelected:(value)async{
                  await c.setPlaybackSpeed(value);
                  if(mounted)setState(()=>speed=value);
                },
                itemBuilder:(_)=>[.75,1.0,1.25,1.5,2.0]
                  .map((v)=>PopupMenuItem(value:v,
                    child:Text(v.toString()+'×'))).toList(),
                icon:const Icon(Icons.speed)),
            ]),
          ],
          const SizedBox(height:18),
          const Panel(child:Text(
            'يعمل هذا المشغل داخل التطبيق ولا يفتح المتصفح. '
            'تتطلب مشاهدة الفيديوهات المباشرة اتصالاً بالشبكة.')),
        ]))),
    );
  }
}
