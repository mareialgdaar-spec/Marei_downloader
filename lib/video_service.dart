import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:file_picker/file_picker.dart';

class VideoService {
  static final Dio _dio = Dio();

  static Future> extractVideoInfo(String url) async {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return await _fetchYouTubeInfo(url);
    } else if (url.contains('tiktok.com') || url.contains('instagram.com') || url.contains('facebook.com')) {
      return await _fetchSocialMediaInfoViaApi(url);
    } else {
      throw Exception('عذراً، هذا الرابط غير مدعوم حالياً.');
    }
  }

  static Future> _fetchYouTubeInfo(String url) async {
    var yt = YoutubeExplode();
    try {
      var video = await yt.videos.get(url);
      var manifest = await yt.videos.streamsClient.getManifest(video.id);
      var muxedStreams = manifest.muxed.sortByBitrate();
      
      List> qualities = [];
      for (var stream in muxedStreams) {
        qualities.add({
          'quality': stream.qualityLabel.toString(),
          'size': '${stream.size.totalMegaBytes.toStringAsFixed(1)} MB',
          'url': stream.url.toString(),
        });
      }

      yt.close();
      return {
        'title': video.title,
        'author': video.author,
        'thumbnail': video.thumbnails.highResUrl,
        'qualities': qualities,
      };
    } catch (e) {
      yt.close();
      throw Exception('فشل تحليل رابط اليوتيوب: $e');
    }
  }

  static Future> _fetchSocialMediaInfoViaApi(String url) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      'title': 'فيديو من وسائل التواصل الاجتماعي',
      'author': 'Creator Name',
      'thumbnail': 'https://via.placeholder.com/600x400.png?text=Video+Thumbnail',
      'qualities': [
        {'quality': 'HD (1080p)', 'size': '15.2 MB', 'url': 'https://example.com/video.mp4'},
        {'quality': 'SD (720p)', 'size': '8.4 MB', 'url': 'https://example.com/video.mp4'},
      ],
    };
  }

  static Future<String?> pickCustomDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      return selectedDirectory;
    } catch (e) {
      return null;
    }
  }

  static Future<void> downloadVideo(
    String videoUrl, 
    String fileName, 
    String? customPath, 
    Function(int, int) onProgress
  ) async {
    try {
      Directory? directory;

      if (customPath != null && customPath.isNotEmpty) {
        directory = Directory(customPath);
      } else {
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      }

      String sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\s]+'), '');
      String savePath = '${directory!.path}/$sanitizedFileName.mp4';

      await _dio.download(
        videoUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received, total);
          }
        },
      );
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل الملف: $e');
    }
  }
}
