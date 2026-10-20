import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/ui/design.dart';
import 'package:paledu/ui/royal_portal_components.dart';

void main(){
  testWidgets('responsive metric cards show values on narrow phones',(tester) async {
    tester.view.physicalSize=const Size(320,640);
    tester.view.devicePixelRatio=1;
    addTearDown((){
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(theme:palTheme(false),
      home:const Scaffold(body:SingleChildScrollView(
        child:RoyalMetricsGrid(metrics:[
          RoyalMetricTile(label:'المواد',value:'0',icon:Icons.menu_book),
          RoyalMetricTile(label:'المراجعة',value:'2',icon:Icons.pending),
        ])))));
    expect(find.text('المواد'),findsOneWidget);
    expect(find.text('2'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
  testWidgets('approval actions are distinct and actionable',(tester) async {
    var accepted=false,rejected=false;
    await tester.pumpWidget(MaterialApp(theme:palTheme(false),
      home:Scaffold(body:SingleChildScrollView(
        child:RoyalApprovalCard(title:'درس جديد',description:'بيانات المادة',
          onApprove:()=>accepted=true,onReject:()=>rejected=true)))));
    await tester.tap(find.text('مراجعة واعتماد'));
    expect(accepted,isTrue);
    await tester.tap(find.text('رفض الطلب'));
    expect(rejected,isTrue);
  });
  testWidgets('status labels reflect actual backend state',(tester) async {
    await tester.pumpWidget(MaterialApp(theme:palTheme(false),
      home:const Scaffold(body:RoyalStatusPill(status:'pending'))));
    expect(find.text('بانتظار المراجعة'),findsOneWidget);
  });
}
