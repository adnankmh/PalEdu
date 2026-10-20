import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ministry_catalog.dart';

/// Device-local reading history for PUBLIC ministry links only.
/// Never store temporary private signed URLs or user authentication material.
class ReadingEntry {
  const ReadingEntry({
    required this.id,required this.title,required this.grade,
    required this.branch,required this.kind,required this.url,
    required this.lastPage,required this.favourite,required this.openedAt,
  });
  final String id,title,branch,kind,url;
  final int grade,lastPage,openedAt;
  final bool favourite;
  Map<String,dynamic> toJson()=>{
    'id':id,'title':title,'grade':grade,'branch':branch,
    'kind':kind,'url':url,'lastPage':lastPage,
    'favourite':favourite,'openedAt':openedAt,
  };
  factory ReadingEntry.fromJson(Map<String,dynamic> data)=>ReadingEntry(
    id:data['id'] as String,title:data['title'] as String,
    grade:data['grade'] as int,branch:data['branch'] as String,
    kind:data['kind'] as String,url:data['url'] as String,
    lastPage:data['lastPage'] as int,
    favourite:data['favourite'] as bool,
    openedAt:data['openedAt'] as int,
  );
  ReadingEntry copyWith({int? lastPage,bool? favourite,int? openedAt})=>
    ReadingEntry(id:id,title:title,grade:grade,branch:branch,kind:kind,
      url:url,lastPage:lastPage??this.lastPage,
      favourite:favourite??this.favourite,
      openedAt:openedAt??this.openedAt);
}

class ReadingShelf {
  ReadingShelf(this.prefs);
  final SharedPreferences prefs;
  static const key='paledu_public_ministry_reading_shelf_v1';
  static const limit=200;

  List<ReadingEntry> all() {
    final raw=prefs.getString(key);
    if(raw==null)return [];
    try{
      final parsed=jsonDecode(raw) as List;
      final result=<String,ReadingEntry>{};
      for(final item in parsed){
        final entry=ReadingEntry.fromJson(Map<String,dynamic>.from(item as Map));
        final url=Uri.tryParse(entry.url);
        if(url!=null&&MinistryIndex.official(url) &&
           entry.grade>=1&&entry.grade<=12&&entry.lastPage>=1) {
          result[entry.id]=entry;
        }
      }
      final entries=result.values.toList()
        ..sort((a,b)=>b.openedAt.compareTo(a.openedAt));
      return entries.take(limit).toList();
    }catch(_){return [];}
  }

  Future<void> recordOpen(MinistryDocument doc) async {
    if(!MinistryIndex.official(Uri.parse(doc.url)))return;
    final list=all();
    final before=first(doc.id,entries:list);
    final latest=ReadingEntry(
      id:doc.id,title:doc.title,grade:doc.grade,branch:doc.branch,
      kind:doc.kind,url:doc.url,
      lastPage:before?.lastPage??1,
      favourite:before?.favourite??false,
      openedAt:DateTime.now().millisecondsSinceEpoch,
    );
    await _write([latest,...list.where((e)=>e.id!=doc.id)]);
  }

  ReadingEntry? first(String id,{List<ReadingEntry>? entries}) {
    for(final item in entries??all()) {if(item.id==id)return item;}
    return null;
  }

  Future<void> setPage(String id,int page) async {
    if(page<1)return;
    final list=all();
    if(!list.any((e)=>e.id==id))return;
    await _write(list.map((e)=>e.id==id?e.copyWith(lastPage:page):e).toList());
  }

  Future<void> setFavourite(MinistryDocument doc,bool value) async {
    if(!MinistryIndex.official(Uri.parse(doc.url)))return;
    final list=all();
    final previous=first(doc.id,entries:list);
    if(previous==null) await recordOpen(doc);
    final refreshed=all();
    await _write(refreshed.map((e)=>e.id==doc.id
      ?e.copyWith(favourite:value):e).toList());
  }

  Future<void> clear() => prefs.remove(key).then((_) {});
  Future<void> _write(List<ReadingEntry> entries) async {
    entries.sort((a,b)=>b.openedAt.compareTo(a.openedAt));
    await prefs.setString(key,jsonEncode(
      entries.take(limit).map((e)=>e.toJson()).toList()));
  }
}
