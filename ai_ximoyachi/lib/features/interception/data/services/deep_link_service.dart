import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../presentation/screens/apk_warning_screen.dart';
import '../../presentation/screens/url_scan_screen.dart';
import '../../presentation/screens/deepfake_scan_screen.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<List<SharedMediaFile>>? _intentSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;

  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Share Intent (Fayl qabul qilish)
    _intentSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
      }
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value);
      }
      ReceiveSharingIntent.instance.reset(); // Clear intent
    });
  }

  void _handleDeepLink(Uri uri) {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      // Agar context hali tayyor bo'lmasa, 500ms kutib qayta urinamiz (Cold start xavfsizligi)
      Future.delayed(const Duration(milliseconds: 500), () => _handleDeepLink(uri));
      return;
    }

    debugPrint('Incoming Deep Link: $uri');
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      _navigateToUrlScan(context, uri.toString());
    } else if (uri.path.endsWith('.apk') || uri.toString().contains('package-archive')) {
      _navigateToApkWarning(context, uri.toString());
    }
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      Future.delayed(const Duration(milliseconds: 500), () => _handleSharedFiles(files));
      return;
    }

    for (var file in files) {
      // Audio fayl ekanligini tekshiramiz
      if (file.path.endsWith('.m4a') || file.path.endsWith('.ogg') || file.path.endsWith('.mp3') || file.path.endsWith('.wav')) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DeepfakeScanScreen(audioPath: file.path)),
        );
        break; // Bitta audio uchun skanerni ochamiz
      }
    }
  }

  void _navigateToUrlScan(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UrlScanScreen(url: url)),
    );
  }

  void _navigateToApkWarning(BuildContext context, String filePath) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ApkWarningScreen(filePath: filePath)),
    );
  }

  void dispose() {
    _linkSubscription?.cancel();
    _intentSubscription?.cancel();
  }
}
