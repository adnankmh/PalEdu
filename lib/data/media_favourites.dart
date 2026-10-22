import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Only stores approved resource UUIDs, scoped to the signed-in learner.
/// No signed download URLs, filenames, book text or private user IDs in data.
class MediaFavourites {
  MediaFavourites(this.prefs,{required String userId})
      : key=prefix+sha256.convert(utf8.encode(userId)).toString().substring(0,24) {
    if(userId.isEmpty)throw ArgumentError('Signed-in user required');
  }
  final SharedPreferences prefs;
  final String key;
  static const prefix='paledu_media_favourites_v1_';
  static const maximum=250;
  static final RegExp uuid=RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  Set<String> getAll() {
    final raw=prefs.getString(key);
    if(raw==null)return <String>{};
    try {
      final v=jsonDecode(raw);
      if(v is! List)return <String>{};
      return v.whereType<String>().where((x)=>uuid.hasMatch(x))
        .take(maximum).toSet();
    } catch (_){ return <String>{}; }
  }

  Future<bool> toggle(String resourceId) async {
    if(!uuid.hasMatch(resourceId))throw ArgumentError('Invalid resource ID');
    final ids=getAll();
    final willSave=!ids.contains(resourceId);
    if(willSave){
      if(ids.length>=maximum)throw StateError('Favourites limit reached');
      ids.add(resourceId);
    } else {
      ids.remove(resourceId);
    }
    if(ids.isEmpty){
      await prefs.remove(key);
    } else {
      final ordered=ids.toList()..sort();
      await prefs.setString(key,jsonEncode(ordered));
    }
    return willSave;
  }

  Future<void> clear() async=>prefs.remove(key);
}
