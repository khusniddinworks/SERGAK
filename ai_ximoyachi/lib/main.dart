import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/home/presentation/screens/main_navigation_screen.dart';
import 'features/permission_gate/presentation/screens/permission_gate_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/interception/data/services/deep_link_service.dart';
import 'core/state/app_state.dart';
import 'core/services/notification_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // 1. AppState ni UI dan oldin yuklash (Xavfsiz)
    final appState = AppState();
    await appState.init();
    
    // 2. Orientatsiyani qulflash
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    
    runApp(const SergakApp());
  } catch (e) {
    // Agar fatal xato bo'lsa ham ilovani ochishga urinish
    runApp(const SergakApp());
  }
}

class SergakApp extends StatefulWidget {
  const SergakApp({super.key});
  @override
  State<SergakApp> createState() => _SergakAppState();
}

class _SergakAppState extends State<SergakApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final DeepLinkService _deepLinkService = DeepLinkService();
  bool _showSplash = true;
  bool _permissionsReady = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // DeepLinkService'ni darhol ishga tushiramiz (Soniya yo'qotmaslik va cold-start uchun)
    _deepLinkService.init(_navigatorKey);

    // Ruxsatlarni tekshirish
    _permissionsReady = await _checkPermissions();
    
    // Fon xizmatlarini biroz kechroq ishga tushiramiz (UI yuklangach)
    Future.delayed(const Duration(seconds: 3), () async {
      try {
        await NotificationService().init();
        NotificationService().scheduleDailyNotifications();
      } catch (e) {
        debugPrint("Background init error: $e");
      }
    });
    
    if (mounted) setState(() {});
  }

  Future<bool> _checkPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadySetup = prefs.getBool('permissions_granted') ?? false;
      if (!alreadySetup) return false;
      
      // Faqat eng muhim ruxsatlarni tekshiramiz
      final sms = await Permission.sms.isGranted;
      final phone = await Permission.phone.isGranted;
      return sms && phone;
    } catch (_) {
      return false;
    }
  }

  void _onSplashFinish() => setState(() => _showSplash = false);
  void _onPermissionsGranted() => setState(() => _permissionsReady = true);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        final appState = AppState();
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Sergak',
          debugShowCheckedModeBanner: false,
          themeMode: appState.themeMode,
          theme: ThemeData(
            primarySwatch: Colors.green,
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.green,
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home: _showSplash
              ? SplashScreen(onFinish: _onSplashFinish)
              : (_permissionsReady
                  ? const MainNavigationScreen()
                  : PermissionGateScreen(onAllGranted: _onPermissionsGranted)),
        );
      }
    );
  }
}
