import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class UpdateService {
  // O'zingizning saytingiz URL'si. Bu Netlify, Render yoki GitHub raw link bo'lishi mumkin.
  static const String _versionUrl = "https://sergak-bot.netlify.app/version.json";
  
  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(_versionUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final remoteVersionStr = data['version'];
        final apkUrl = data['apk_url'];
        final releaseNotes = data['release_notes'] ?? '';
        
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersionStr = packageInfo.version;
        
        if (_isNewerVersion(currentVersionStr, remoteVersionStr)) {
          _promptUpdate(context, apkUrl, remoteVersionStr, releaseNotes);
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  bool _isNewerVersion(String current, String remote) {
    try {
      List<String> currParts = current.split('.');
      List<String> remParts = remote.split('.');
      for (int i = 0; i < 3; i++) {
        int c = int.parse(currParts[i]);
        int r = int.parse(remParts[i]);
        if (r > c) return true;
        if (r < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _promptUpdate(BuildContext context, String apkUrl, String version, String notes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text("Yangi versiya mavjud: $version"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ilovaning yangi versiyasini yuklab olishingiz mumkin."),
            const SizedBox(height: 10),
            Text(notes, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keyinroq"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadAndInstall(context, apkUrl);
            },
            child: const Text("Yuklab olish va O'rnatish"),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstall(BuildContext context, String apkUrl) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Yuklab olinmoqda... Iltimos kuting."),
          ],
        ),
      ),
    );

    try {
      var request = await http.Client().send(http.Request('GET', Uri.parse(apkUrl)));
      int totalBytes = request.contentLength ?? 0;
      
      List<int> bytes = [];
      request.stream.listen((List<int> chunk) {
        bytes.addAll(chunk);
      }, onDone: () async {
        Navigator.pop(context); // close loading dialog
        
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/app-update.apk');
        await file.writeAsBytes(bytes);
        
        // Android 11+ da install request chaqirish
        final result = await OpenFile.open(file.path);
        debugPrint("OpenFile result: ${result.message}");
      }, onError: (e) {
        Navigator.pop(context);
        debugPrint("Download error: $e");
      });
    } catch (e) {
      Navigator.pop(context);
      debugPrint("Download error: $e");
    }
  }
}
