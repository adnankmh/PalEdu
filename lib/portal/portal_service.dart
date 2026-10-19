import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class PortalConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  static bool get enabled => url.startsWith('https://') && key.isNotEmpty;
}

class PortalService {
  PortalService._();
  static final instance = PortalService._();
  SupabaseClient get db => Supabase.instance.client;
  User? get user => db.auth.currentUser;

  Future<Map<String, dynamic>> profile() async {
    if (user==null) throw StateError('Login required');
    final row=await db.from('paledu_profiles')
      .select('role,display_name,grade,branch').eq('user_id',user!.id).single();
    return Map<String,dynamic>.from(row);
  }
  Future<void> signIn(String email,String password) async {
    await db.auth.signInWithPassword(email:email.trim(),password:password);
  }
  Future<void> register(String email,String password,String name) async {
    await db.auth.signUp(email:email.trim(),password:password,
      data:{'display_name':name.trim()});
  }
  Future<void> requestEducator(String statement,String role) async {
    if (user==null) throw StateError('Login required');
    if (role!='teacher' && role!='trainer') throw ArgumentError('Invalid role');
    await db.from('paledu_role_requests').insert({
      'user_id':user!.id,'requested_role':role,'statement':statement.trim()});
  }
  Future<List<Map<String,dynamic>>> published(int grade) async {
    final rows=await db.from('paledu_resources')
      .select('resource_id,title,description,kind,subject,grade,branch,asset_path,external_url')
      .eq('status','published').eq('grade',grade)
      .order('published_at',ascending:false).limit(60);
    return rows.map((x)=>Map<String,dynamic>.from(x)).toList();
  }
  Future<List<Map<String,dynamic>>> mine() async {
    if (user==null) throw StateError('Login required');
    final rows=await db.from('paledu_resources')
      .select('resource_id,title,kind,status,grade,subject')
      .eq('created_by',user!.id).limit(100);
    return rows.map((x)=>Map<String,dynamic>.from(x)).toList();
  }
  Future<List<Map<String,dynamic>>> pending(String table) async {
    if (table!='paledu_resources' && table!='paledu_role_requests') {
      throw ArgumentError('Invalid table');
    }
    final rows=await db.from(table).select().eq('status','pending').limit(100);
    return rows.map((x)=>Map<String,dynamic>.from(x)).toList();
  }
  Future<void> reviewEducator(String id,bool yes) async =>
    db.rpc('paledu_review_educator',params:{'request_uid':id,'accepted':yes});
  Future<void> reviewResource(String id,bool yes) async =>
    db.rpc('paledu_review_resource',params:{'resource_uid':id,'accepted':yes});

  Future<void> submit({
    required String title,required String summary,required String subject,
    required String kind,required String branch,required int grade,
    required String rights,Uint8List? bytes,String? fileName,String? url,
  }) async {
    if (user==null) throw StateError('Login required');
    if (title.trim().length<4 || subject.trim().length<2 ||
      rights.trim().length<10 || grade<1 || grade>12) {
      throw ArgumentError('Title, subject and rights evidence required');
    }
    if (!['book','handout','video','lesson'].contains(kind)) {
      throw ArgumentError('Invalid kind');
    }
    String? path;
    if (bytes!=null) {
      if (bytes.isEmpty || bytes.length>50*1024*1024 || fileName==null) {
        throw ArgumentError('Invalid size');
      }
      final ext=fileName.split('.').last.toLowerCase();
      const types={'pdf':'application/pdf','mp4':'video/mp4',
        'png':'image/png','jpg':'image/jpeg','jpeg':'image/jpeg'};
      if (!types.containsKey(ext)) throw ArgumentError('Unsupported file');
      path=user!.id+'/'+DateTime.now().microsecondsSinceEpoch.toString()+'.'+ext;
      await db.storage.from('paledu-curriculum').uploadBinary(path,bytes,
        fileOptions:FileOptions(contentType:types[ext],upsert:false));
    }
    if (url!=null && url.trim().isNotEmpty && Uri.tryParse(url)?.scheme!='https') {
      throw ArgumentError('Use an HTTPS link');
    }
    if (path==null && (url==null || url.trim().isEmpty)) {
      throw ArgumentError('Choose a file or URL');
    }
    await db.from('paledu_resources').insert({
      'created_by':user!.id,'title':title.trim(),'description':summary.trim(),
      'kind':kind,'grade':grade,'branch':branch,'subject':subject.trim(),
      'rights_note':rights.trim(),'asset_path':path,
      'external_url':url?.trim().isEmpty==true ? null : url?.trim(),
      'status':'pending',
    });
  }
  Future<String> accessUrl(Map<String,dynamic> item) async {
    final external=item['external_url'] as String?;
    if (external!=null && Uri.tryParse(external)?.scheme=='https') return external;
    final path=item['asset_path'] as String?;
    if (path==null) throw StateError('No file');
    return db.storage.from('paledu-curriculum').createSignedUrl(path,120);
  }
}
