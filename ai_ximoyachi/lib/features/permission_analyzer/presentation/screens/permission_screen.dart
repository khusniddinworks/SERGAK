import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});
  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  static const _channel = MethodChannel('com.aiximoyachi/app_analyzer');

  List<Map<String, dynamic>> _apps = [];
  Set<String> _trustedPackages = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _trustedPackages = (prefs.getStringList('trusted_apps') ?? []).toSet();

      final result = await _channel.invokeListMethod('getInstalledApps');
      if (result != null && mounted) {
        setState(() {
          _apps = result
              .map((e) => Map<String, dynamic>.from(e as Map))
              .where((app) => !_trustedPackages.contains(app['packageName']))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Ilovalarni yuklashda xatolik: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _trustApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    _trustedPackages.add(packageName);
    await prefs.setStringList('trusted_apps', _trustedPackages.toList());
    _loadApps(); // Ro'yxatni yangilash
  }

  Future<void> _openSettings(String packageName) async {
    await _channel.invokeMethod('openAppSettings', {'packageName': packageName});
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'HIGH': return AppColors.error;
      case 'MEDIUM': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  String _riskLabel(String risk) {
    switch (risk) {
      case 'HIGH': return 'Xavfli';
      case 'MEDIUM': return 'O\'rtacha';
      default: return 'Xavfsiz';
    }
  }

  IconData _riskIcon(String risk) {
    switch (risk) {
      case 'HIGH': return Icons.dangerous_rounded;
      case 'MEDIUM': return Icons.warning_amber_rounded;
      default: return Icons.check_circle_rounded;
    }
  }

  // Ruxsat nomini chiroyli o'zbekchaga o'girish
  String _permLabel(String perm) {
    final map = {
      'CAMERA': '📷 Kamera',
      'READ_CONTACTS': '📇 Kontaktlar',
      'WRITE_CONTACTS': '📇 Kontaktlarni o\'zgartirish',
      'ACCESS_FINE_LOCATION': '📍 Aniq joylashuv',
      'ACCESS_COARSE_LOCATION': '📍 Taxminiy joylashuv',
      'RECORD_AUDIO': '🎙️ Mikrofon',
      'READ_PHONE_STATE': '📱 Telefon holati',
      'CALL_PHONE': '📞 Qo\'ng\'iroq qilish',
      'READ_CALL_LOG': '📋 Qo\'ng\'iroqlar tarixi',
      'READ_SMS': '💬 SMS o\'qish',
      'RECEIVE_SMS': '💬 SMS qabul qilish',
      'SEND_SMS': '💬 SMS yuborish',
      'READ_EXTERNAL_STORAGE': '📂 Xotirani o\'qish',
      'WRITE_EXTERNAL_STORAGE': '📂 Xotiraga yozish',
      'READ_MEDIA_IMAGES': '🖼️ Rasmlar',
      'READ_MEDIA_VIDEO': '🎬 Videolar',
      'READ_MEDIA_AUDIO': '🎵 Audilolar',
      'POST_NOTIFICATIONS': '🔔 Bildirishnomalar',
      'BODY_SENSORS': '❤️ Tana sensorlari',
      'ACTIVITY_RECOGNITION': '🏃 Harakat aniqlash',
    };
    return map[perm] ?? perm;
  }

  @override
  Widget build(BuildContext context) {
    // Xavf guruhlari
    final high = _apps.where((a) => a['riskLevel'] == 'HIGH').toList();
    final medium = _apps.where((a) => a['riskLevel'] == 'MEDIUM').toList();
    final low = _apps.where((a) => a['riskLevel'] == 'LOW').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text('Ruxsatlar Tahlili', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Ilovalar tahlil qilinmoqda...', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ))
          : _apps.isEmpty
              ? const Center(child: Text('Hech qanday shubhali ilova topilmadi ✅', style: TextStyle(fontSize: 16)))
              : RefreshIndicator(
                  onRefresh: _loadApps,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Xulosa karta
                      _buildSummaryCard(high.length, medium.length, low.length),
                      const SizedBox(height: 20),

                      if (high.isNotEmpty) ...[
                        _sectionTitle('🔴 Xavfli ilovalar', AppColors.error),
                        ...high.map((a) => _buildAppCard(a)),
                      ],
                      if (medium.isNotEmpty) ...[
                        _sectionTitle('🟡 O\'rtacha xavfli', AppColors.warning),
                        ...medium.map((a) => _buildAppCard(a)),
                      ],
                      if (low.isNotEmpty) ...[
                        _sectionTitle('🟢 Xavfsiz', AppColors.success),
                        ...low.map((a) => _buildAppCard(a)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(int high, int medium, int low) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(high.toString(), 'Xavfli', AppColors.error),
          Container(width: 1, height: 40, color: Colors.white30),
          _summaryItem(medium.toString(), 'O\'rtacha', AppColors.warning),
          Container(width: 1, height: 40, color: Colors.white30),
          _summaryItem(low.toString(), 'Xavfsiz', Colors.white),
        ],
      ),
    );
  }

  Widget _summaryItem(String count, String label, Color color) {
    return Column(children: [
      Text(count, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
    ]);
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    );
  }

  Widget _buildAppCard(Map<String, dynamic> app) {
    final risk = app['riskLevel'] as String;
    final perms = List<String>.from(app['permissions'] ?? []);
    final color = _riskColor(risk);
    final iconBytes = app['appIcon'] as Uint8List?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openSettings(app['packageName']),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Yuqori qism: nom va risk badge
                Row(children: [
                  iconBytes != null && iconBytes.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            iconBytes,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.android_rounded, color: color, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app['appName'], style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('${perms.length} ta xavfli ruxsat', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_riskIcon(risk), color: color, size: 14),
                      const SizedBox(width: 4),
                      Text(_riskLabel(risk), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),

                // Ruxsatlar ro'yxati
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: perms.map((p) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                    child: Text(_permLabel(p), style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                  )).toList(),
                ),
                const SizedBox(height: 12),

                // Tugmalar
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _trustApp(app['packageName']),
                        icon: const Icon(Icons.verified_user_outlined, size: 16),
                        label: const Text('Ishonaman', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: BorderSide(color: AppColors.success.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openSettings(app['packageName']),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('O\'chirish', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error.withOpacity(0.1),
                          foregroundColor: AppColors.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
