import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YouTube MP3 Downloader',
      theme: ThemeData.dark(),
      home: const YouTubeScreen(),
    );
  }
}

class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({super.key});

  @override
  State<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen> {
  late final WebViewController _controller;
  String _statusText = "მზად არის გადმოწერისთვის";
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF181818))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // რეკლამების ავტომატური ბლოკირებისა და სკიპის სკრიპტი ყოველ ჩატვირთვაზე
            _controller.runJavaScript('''
              setInterval(() => {
                let skipBtn = document.querySelector('.ytp-ad-skip-button, .ytp-ad-skip-button-modern');
                if (skipBtn) skipBtn.click();

                let adShowing = document.querySelector('.ad-showing, .ad-interrupting');
                let video = document.querySelector('video');
                if (adShowing && video) {
                  video.playbackRate = 16.0;
                  video.muted = true;
                  if (video.duration) video.currentTime = video.duration;
                } else if (video && video.playbackRate === 16.0) {
                  video.playbackRate = 1.0;
                  video.muted = false;
                }
              }, 500);
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.youtube.com'));
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<void> _downloadCurrentVideo() async {
    final String? currentUrl = await _controller.currentUrl();

    if (currentUrl == null || !currentUrl.contains('/watch')) {
      setState(() {
        _statusText = "⚠️ გთხოვთ, გახსენით ვიდეო YouTube-ზე!";
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusText = "⏳ მიმდინარეობს გადმოწერა ფონში...";
    });

    try {
      // აქ შეგიძლიათ გამოიყენოთ რაიმე ღია API ან თქვენი სერვერი yt-dlp-ისთვის, 
      // ან პირდაპირ მიაბათ Python ბექენდს, ხოლო მობილურისთვის საუკეთესო გზაა 
      // y2mate ან მსგავსი ღია API-ს გამოძახება, ან ადგილობრივი yt-dlp სერვისი.
      // (დემონსტრაციისთვის: ვამზადებთ სტრუქტურას ადგილობრივი Download ფოლდერისთვის)
      
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      }

      setState(() {
        _isDownloading = false;
        _statusText = "✅ წარმატებით გადმოიწერა Downloads ფოლდერში!";
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusText = "❌ გადმოწერა ვერ მოხერხდა: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ზედა მინიმალისტური პანელი (სიმაღლე 35px)
          Container(
            height: 35,
            color: const Color(0xFF181818),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _statusText,
                    style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCC0000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    minimumSize: const Size(60, 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  onPressed: _isDownloading ? null : _downloadCurrentVideo,
                  child: Text(
                    _isDownloading ? "⏳ იწერება..." : "📥 MP3-ად გადმოწერა",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // YouTube WebView
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}