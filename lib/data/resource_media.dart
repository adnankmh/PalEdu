/// Files and streams supported by the *internal* PalEdu viewers.
/// Do not silently send unsupported pages to an external browser.
enum ResourceFormat { pdf, image, video }

class ResourceMedia {
  static const extensions=<String,List<String>>{
    'book':['pdf'],
    'handout':['pdf','png','jpg','jpeg'],
    'lesson':['pdf','png','jpg','jpeg'],
    'video':['mp4'],
  };
  static const allowedExternal=<String,List<String>>{
    'book':['pdf'],
    'handout':['pdf','png','jpg','jpeg'],
    'lesson':['pdf','png','jpg','jpeg'],
    'video':['mp4','m3u8'],
  };

  static String? extension(String source) {
    final path=(Uri.tryParse(source)?.path??source).toLowerCase();
    final filename=path.split('/').last;
    final dot=filename.lastIndexOf('.');
    if(dot<1)return null;
    return filename.substring(dot+1);
  }

  static ResourceFormat? format(String source) {
    switch(extension(source)){
      case 'pdf':return ResourceFormat.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':return ResourceFormat.image;
      case 'mp4':
      case 'm3u8':return ResourceFormat.video;
      default:return null;
    }
  }

  static bool acceptsFile(String kind,String filename)=>
    extensions[kind]?.contains(extension(filename))??false;

  static bool acceptsExternal(String kind,String source) {
    final url=Uri.tryParse(source.trim());
    if(url==null||url.scheme!='https'||url.host.isEmpty||
       url.userInfo.isNotEmpty)return false;
    return allowedExternal[kind]?.contains(extension(source))??false;
  }

  /// Stored asset path is the source of truth when present; the
  /// time-limited signed URL must never be stored in device preferences.
  static ResourceFormat? forResource(Map<String,dynamic> item) {
    final path=item['asset_path']?.toString();
    if(path!=null&&path.isNotEmpty)return format(path);
    final external=item['external_url']?.toString();
    if(external!=null&&external.isNotEmpty)return format(external);
    return null;
  }

  static String description(String kind)=>switch(kind){
    'book'=>'كتاب PDF',
    'handout'=>'ملزمة أو ورقة عمل PDF / صورة',
    'lesson'=>'شرح PDF / صورة',
    'video'=>'فيديو MP4 أو بث HLS مباشر',
    _=>'محتوى تعليمي',
  };
}
