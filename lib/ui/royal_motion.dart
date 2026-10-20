import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'design.dart';

/// Original PalEdu motion assets: no third-party animation URLs or tracking.
/// Avoid continuous loops, and honor system/user reduced-motion preferences.
class RoyalMotionGraphic extends StatelessWidget {
  const RoyalMotionGraphic({
    super.key,required this.asset,required this.fallback,
    this.size=90,this.enabled=true,this.label='رسم تعليمي متحرك',
  });
  final String asset,label;
  final IconData fallback;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final reduced=MediaQuery.maybeOf(context)?.disableAnimations??false;
    final still=!enabled||reduced;
    return Semantics(
      label:label,image:true,
      child:ExcludeSemantics(child:SizedBox(
        width:size,height:size,
        child:still
          ?Center(child:Icon(fallback,
            size:size*.6,color:PColors.gold))
          :Lottie.asset(
            asset,fit:BoxFit.contain,repeat:false,
            frameRate:FrameRate.composition,
            errorBuilder:(context,error,stackTrace)=>Center(
              child:Icon(fallback,size:size*.6,color:PColors.gold)),
          ),
      )),
    );
  }
}

/// Vector-only emblem, no external icon fonts/assets needed.
class RoyalBrandCrest extends StatelessWidget {
  const RoyalBrandCrest({super.key,this.size=72});
  final double size;
  @override
  Widget build(BuildContext context)=>Semantics(
    label:'شعار تعلّم فلسطين',image:true,
    child:ExcludeSemantics(
      child:SizedBox(width:size,height:size,child:CustomPaint(
        painter:const _CrestPainter())),
    ),
  );
}

class _CrestPainter extends CustomPainter {
  const _CrestPainter();
  @override
  void paint(Canvas canvas,Size size) {
    canvas.save();
    canvas.scale(size.width/100,size.height/100);
    final disc=Paint()..color=PColors.midnight;
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(1,1,98,98),const Radius.circular(26)),disc);
    final gold=Paint()..color=PColors.gold;
    canvas.drawCircle(const Offset(80,23),4,gold);
    canvas.drawCircle(const Offset(73,14),2,gold);
    final pageLeft=Path()
      ..moveTo(16,29)..quadraticBezierTo(32,22,48,33)
      ..lineTo(48,76)..quadraticBezierTo(33,67,16,75)..close();
    final pageRight=Path()
      ..moveTo(52,33)..quadraticBezierTo(68,22,84,29)
      ..lineTo(84,75)..quadraticBezierTo(67,67,52,76)..close();
    canvas.drawPath(pageLeft,Paint()..color=const Color(0xFFF7FBF6));
    canvas.drawPath(pageRight,Paint()..color=const Color(0xFFD9F4E6));
    canvas.drawLine(const Offset(50,33),const Offset(50,78),
      Paint()..color=PColors.gold..strokeWidth=3..strokeCap=StrokeCap.round);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;
}
