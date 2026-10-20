import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'design.dart';

/// Approved wordless Palestinian book-and-flame brand symbol.
class PalEduBrandLogo extends StatelessWidget {
  const PalEduBrandLogo({super.key,this.size=80,this.darkTile=false});
  final double size;
  final bool darkTile;

  @override
  Widget build(BuildContext context) => Semantics(
    image:true,label:'شعار تعلّم فلسطين',
    child:ExcludeSemantics(
      child:Container(
        width:size,height:size,
        padding:EdgeInsets.all(darkTile?size*.06:0),
        decoration:darkTile?BoxDecoration(
          color:PColors.midnight,
          borderRadius:BorderRadius.circular(size*.22)):null,
        child:SvgPicture.asset('assets/brand/paledu_symbol.svg',
          fit:BoxFit.contain,width:size,height:size,
          placeholderBuilder:(context)=>Icon(Icons.auto_stories_rounded,
            color:PColors.gold,size:size*.55)),
      )));
}
