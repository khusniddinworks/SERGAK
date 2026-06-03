import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../permission_analyzer/presentation/screens/permission_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _statsCh  = MethodChannel('com.aiximoyachi/system_stats');
  static const _appsCh   = MethodChannel('com.aiximoyachi/app_analyzer');
  static const _fraudCh  = MethodChannel('com.aiximoyachi/fraud_monitor');

  bool   _isScanning     = false;
  double _scanProgress   = 0.0;

  bool   _fraudEnabled   = true;
  double _ramUsage       = 0.0;
  double _cpuUsage       = 0.0;
  int    _blockedCount   = 0;
  int    _dangerousCount = 0;

  Timer? _timer;

  String tr(String key) => AppTranslations.get(key, AppState().language);

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _fetchStats();
    _initFraudMonitor();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchStats());
  }

  Future<void> _initFraudMonitor() async {
    try {
      // Ruxsatlarni so'rash va servisni ishga tushirish
      final granted = await _fraudCh.invokeMethod<bool>('startFraudMonitor') ?? false;
      if (mounted) setState(() => _fraudEnabled = granted);
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _blockedCount   = prefs.getInt('blocked_count')   ?? 0;
      _dangerousCount = prefs.getInt('dangerous_count') ?? 0;
    });
  }

  Future<void> _fetchStats() async {
    try {
      final result = await _statsCh.invokeMapMethod<String, double>('getSystemStats');
      if (result != null && mounted) {
        setState(() {
          _ramUsage = result['ramUsage'] ?? 0.0;
          _cpuUsage = result['cpuUsage'] ?? 0.0;
        });
      }
    } catch (_) {}
  }

  Future<void> _runSmartScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
    });

    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _scanProgress = i / 10);
    }

    try {
      final List<dynamic>? apps = await _appsCh.invokeListMethod('getInstalledApps');
      final prefs = await SharedPreferences.getInstance();
      final trusted = (prefs.getStringList('trusted_apps') ?? []).toSet();
      
      int dangerous = 0;
      if (apps != null) {
        final filteredApps = apps
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((app) => !trusted.contains(app['packageName']))
            .toList();
        dangerous = filteredApps.length;
      }

      await prefs.setInt('dangerous_count', dangerous);

      setState(() {
        _dangerousCount = dangerous;
        _isScanning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr('scan_complete')}. $dangerous ${tr('apps_found')}.'),
            backgroundColor: dangerous > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isScanning = false);
    }
    _fetchStats();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _header(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _statusCard(),
                      const SizedBox(height: 24),
                      _stats(),
                      const SizedBox(height: 24),
                      _monitor(),
                      const SizedBox(height: 24),
                      _fraudCard(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40, left: 20, right: 20),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Column(
        children: [
          const Icon(Icons.shield_rounded, color: Colors.white, size: 60),
          const SizedBox(height: 12),

          Text('SERGAK',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(tr('device_protected'),
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _statusCard() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('safe'),
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(tr('device_protected'),
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.white)),
                ]),
                const Icon(Icons.verified_user_rounded, color: Colors.white, size: 48),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isScanning ? null : _runSmartScan,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.white.withOpacity(0.5),
                  minimumSize: const Size(double.infinity, 50)),
              child: _isScanning 
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, value: _scanProgress, color: AppColors.primary))
                : Text(tr('smart_scan')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stats() {
    return Row(
      children: [
        Expanded(child: _stat(_blockedCount.toString(), tr('blocked'), Icons.verified, Colors.green)),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PermissionScreen()),
            ),
            borderRadius: BorderRadius.circular(20),
            child: _stat(_dangerousCount.toString(), tr('dangerous'), Icons.warning, Colors.orange),
          ),
        ),
      ],
    );
  }

  Widget _stat(String v, String l, IconData i, Color c) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12.withOpacity(isDark ? 0.05 : 0.1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(i, color: c),
        Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(l, style: const TextStyle(color: Colors.grey)),
      ]),
    );
  }

  Widget _monitor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        _progress('RAM', _ramUsage),
        const SizedBox(height: 10),
        _progress('CPU', _cpuUsage),
      ]),
    );
  }

  Widget _progress(String l, double v) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(l), Text('${(v * 100).toInt()}%')]),
      const SizedBox(height: 4),
      LinearProgressIndicator(
          value: v, backgroundColor: Colors.black12, color: AppColors.primary),
    ]);
  }

  Future<void> _toggleFraud(bool v) async {
    try {
      if (v) {
        final granted = await _fraudCh.invokeMethod<bool>('startFraudMonitor') ?? false;
        setState(() => _fraudEnabled = granted);
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('permission_required')),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: tr('settings'),
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        await _fraudCh.invokeMethod('stopFraudMonitor');
        setState(() => _fraudEnabled = false);
      }
    } catch (_) {
      setState(() => _fraudEnabled = v);
    }
  }

  Widget _fraudCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(
          _fraudEnabled ? Icons.shield_rounded : Icons.shield_outlined,
          color: _fraudEnabled ? AppColors.primary : Colors.grey,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('fraud_monitor'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              _fraudEnabled ? '🟢 Faol' : '🔴 O\'chirilgan',
              style: TextStyle(
                  fontSize: 12,
                  color: _fraudEnabled ? AppColors.primary : Colors.red),
            ),
          ],
        )),
        Switch(
            value: _fraudEnabled,
            onChanged: _toggleFraud,
            activeColor: AppColors.primary),
      ]),
    );
  }
}
