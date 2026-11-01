import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'video_service.dart';
import 'history_service.dart';
import 'history_screen.dart';

void main() {
  runApp(const VideoDownloaderApp());
}

class VideoDownloaderApp extends StatelessWidget {
  const VideoDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Downloader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DownloaderHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DownloaderHomeScreen extends StatefulWidget {
  const DownloaderHomeScreen({super.key});

  @override
  State<DownloaderHomeScreen> createState() => _DownloaderHomeScreenState();
}

class _DownloaderHomeScreenState extends State<DownloaderHomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _videoData;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _progressText = '';
  String? _customDownloadPath;

  void _analyzeLink() async {
    if (_urlController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _videoData = null;
    });

    try {
      var data = await VideoService.extractVideoInfo(_urlController.text);
      setState(() {
        _videoData = data;
        _isLoading = false;
      });
      _showQualityModal();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _showQualityModal() {
    if (_videoData == null) return;
    List qualities = _videoData!['qualities'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _videoData!['thumbnail'],
                      width: 70,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.video_file, size: 50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _videoData!['title'],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'اختر جودة التحميل:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...qualities.map((item) => ListTile(
                leading: const Icon(Icons.hd_rounded, color: Color(0xFF6750A4)),
                title: Text(item['quality']),
                subtitle: Text('الحجم التقريبي: ${item['size']}'),
                trailing: const Icon(Icons.download_rounded),
                onTap: () {
                  Navigator.pop(context);
                  _startActualDownload(item['url'], _videoData!['title']);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  void _startActualDownload(String downloadUrl, String title) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _progressText = 'جاري التحميل: 0%';
    });

    try {
      await VideoService.downloadVideo(downloadUrl, title, _customDownloadPath, (received, total) {
        setState(() {
          _downloadProgress = received / total;
          int percentage = (_downloadProgress * 100).toInt();
          _progressText = 'جاري التحميل: $percentage%';
        });
      });

      await HistoryService.addRecord(
        DownloadItem(
          title: title,
          thumbnail: _videoData?['thumbnail'] ?? '',
          path: _customDownloadPath ?? 'Default Downloads',
          date: DateTime.now().toString().substring(0, 16),
        ),
      );

      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم اكتمال التحميل وحفظه بنجاح! ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التحميل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Downloader'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_rounded, size: 80, color: Color(0xFFD0BCFF)),
            const SizedBox(height: 20),
            const Text(
              'حمّل فيديوهاتك المفضلة بسهولة',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'الصق رابط الفيديو من أي منصة أدناه للبدء',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'الصق الرابط هنا...',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () async {
                    ClipboardData? data = await Clipboard.getData('text/plain');
                    if (data != null && data.text != null) {
                      setState(() {
                        _urlController.text = data.text!;
                      });
                    }
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _customDownloadPath == null 
                        ? 'المسار: التنزيلات الافتراضية'
                        : 'المسار: ...${_customDownloadPath!.split('/').last}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    String? path = await VideoService.pickCustomDirectory();
                    if (path != null) {
                      setState(() {
                        _customDownloadPath = path;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تحديد مجلد الحفظ بنجاح! 📁')),
                      );
                    }
                  },
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('تغيير المجلد', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading || _isDownloading ? null : _analyzeLink,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isLoading ? 'جاري تحليل الرابط...' : 'تحليل وتحميل',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_isDownloading) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _progressText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _downloadProgress,
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6750A4)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
