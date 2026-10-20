import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:paledu/ui/paledu_brand.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('approved Palestinian book-flame brand SVG is bundled and wordless',
      () async {
    final source=await rootBundle.loadString('assets/brand/paledu_symbol.svg');
    expect(source,contains('#CE172B'));
    expect(source,contains('#007A3D'));
    expect(source,contains('#061A16'));
    expect(source,contains('viewBox="0 0 400 400"'));
    expect(source.contains('<text'),isFalse);
  });

  testWidgets('approved logo renders as SVG in place of generic crest',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home:Scaffold(body:PalEduBrandLogo(size:88,darkTile:true))));
    expect(find.byType(PalEduBrandLogo),findsOneWidget);
    expect(find.byType(SvgPicture),findsOneWidget);
    await tester.pump();
    expect(tester.takeException(),isNull);
  });
}
