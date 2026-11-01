import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadItem {
  final String title;
  final String thumbnail;
  final String path;
  final String date;

  DownloadItem({
    required this.title,
    required this.thumbnail,
    required this.path,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'thumbnail': thumbnail,
        'path': path,
        'date': date,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
        title: json['title'],
        thumbnail: json['thumbnail'],
        path: json['path'],
        date: json['date'],
      );
}

class HistoryService {
  static const String _key = 'download_history';

  static Future<void> addRecord(DownloadItem item) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];
    history.insert(0, jsonEncode(item.toJson()));
    await prefs.setStringList(_key, history);
  }

  static Future<List<DownloadItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];
    return history.map((item) => DownloadItem.fromJson(jsonDecode(item))).toList();
  }
}
