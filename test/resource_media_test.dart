import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paledu/data/resource_media.dart';
import 'package:paledu/ui/internal_image_viewer.dart';

void main(){
  test('formats accepted for media kind',(){
    expect(ResourceMedia.acceptsFile('book','Math.pdf'),isTrue);
    expect(ResourceMedia.acceptsFile('book','trailer.mp4'),isFalse);
    expect(ResourceMedia.acceptsFile('video','training.mp4'),isTrue);
    expect(ResourceMedia.acceptsFile('video','exercise.pdf'),isFalse);
    expect(ResourceMedia.acceptsFile('handout','worksheet.PNG'),isTrue);
    expect(ResourceMedia.acceptsFile('lesson','diagram.jpeg'),isTrue);
    expect(ResourceMedia.acceptsFile('lesson','trailer.mp4'),isFalse);
  });
  test('direct HTTPS media sources only',(){
    expect(ResourceMedia.acceptsExternal('video',
      'https://example.org/lesson.mp4?token=short'),isTrue);
    expect(ResourceMedia.acceptsExternal('video',
      'https://example.org/stream/master.m3u8'),isTrue);
    expect(ResourceMedia.acceptsExternal('video',
      'https://www.youtube.com/watch?v=abc'),isFalse);
    expect(ResourceMedia.acceptsExternal('book',
      'http://example.org/a.pdf'),isFalse);
    expect(ResourceMedia.acceptsExternal('handout',
      'https://example.org/handout.pdf'),isTrue);
    expect(ResourceMedia.acceptsExternal('handout',
      'https://example.org/download'),isFalse);
    expect(ResourceMedia.acceptsExternal('book',
      'https://user:secret@example.org/a.pdf'),isFalse);
  });
  test('route viewer by source extension',(){
    expect(ResourceMedia.forResource({
      'kind':'handout','asset_path':'user/photo.JPG',
      'external_url':null}),ResourceFormat.image);
    expect(ResourceMedia.forResource({
      'kind':'video','asset_path':'user/lesson.mp4',
      'external_url':null}),ResourceFormat.video);
    expect(ResourceMedia.forResource({
      'kind':'book','asset_path':null,
      'external_url':'https://moe.edu.ps/sample.pdf'}),ResourceFormat.pdf);
    expect(ResourceMedia.forResource({
      'kind':'book','asset_path':null,
      'external_url':'https://example.com/page'}),isNull);
  });
  testWidgets('image viewer rejects HTTP without browser',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home:
      InternalImageViewer(title:'ملزمة',url:'http://example.com/test.png')));
    expect(find.text('ملزمة'),findsOneWidget);
    expect(find.text('رابط الصورة غير صالح أو غير آمن.'),findsOneWidget);
  });
}
