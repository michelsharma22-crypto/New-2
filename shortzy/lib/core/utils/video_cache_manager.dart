import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheManager {
  static const key = 'videoCache';
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 50,
    ),
  );
  
  static Future<String> getVideoPath(String url) async {
    final file = await instance.getFileFromCache(url);
    if (file != null) return file.file.path;
    final newFile = await instance.downloadFile(url);
    return newFile.file.path;
  }
  
  static Future<void> preCacheVideo(String url) async {
    await instance.downloadFile(url);
  }
}
