import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../payment/presentation/screens/premium_screen.dart';
import 'feedback_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  static const _fraudChannel = MethodChannel('com.aiximoyachi/fraud_monitor');
  Map<Permission, bool> _permStatus = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    final sms = await Permission.sms.status;
    final phone = await Permission.phone.status;
    final notification = await Permission.notification.status;
    final manageExternalStorage = await Permission.manageExternalStorage.status;
    final systemAlertWindow = await Permission.systemAlertWindow.status;
    
    if (mounted) {
      setState(() {
        _permStatus[Permission.sms] = sms.isGranted;
        _permStatus[Permission.phone] = phone.isGranted;
        _permStatus[Permission.notification] = notification.isGranted;
        _permStatus[Permission.manageExternalStorage] = manageExternalStorage.isGranted;
        _permStatus[Permission.systemAlertWindow] = systemAlertWindow.isGranted;
      });
    }
  }

  Future<void> _togglePermission(Permission p) async {
    if (await p.isGranted) {
      // Androidda ruxsat berilgan bo'lsa, uni faqat telefon sozlamalaridan o'chirish mumkin
      await openAppSettings();
    } else {
      await p.request();
    }
    _checkAllPermissions();
  }

  String tr(String key) => AppTranslations.get(key, AppState().language);

  Future<void> _toggleFraudMonitor(bool value) async {
    final appState = AppState();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('settings'), style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      
                      _buildSectionTitle(Icons.language, tr('language')),
                      _buildCard([
                        _buildLangOption('O\'zbek tili', 'uz', appState),
                        _buildLangOption('Русский язык', 'ru', appState),
                        _buildLangOption('English', 'en', appState),
                      ]),
                      
                      const SizedBox(height: 24),
                      _buildSectionTitle(Icons.brightness_4, tr('dark_mode')),
                      _buildCard([
                        _buildSwitch(tr('dark_mode'), appState.themeMode == ThemeMode.dark, (v) => appState.toggleTheme(v)),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle(Icons.lock_person_rounded, 'Tizim Ruxsatnomalari'),
                      _buildCard([
                        _buildPermTile('SMS Monitoring', Permission.sms),
                        _buildPermTile('Telefon holati', Permission.phone),
                        _buildPermTile('Bildirishnomalar', Permission.notification),
                        _buildPermTile('Barcha fayllarga kirish', Permission.manageExternalStorage),
                        _buildPermTile('Ekran ustida ko\'rinish', Permission.systemAlertWindow),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle(Icons.star_rounded, 'Premium va To\'lov'),
                      _buildPremiumCard(),

                      const SizedBox(height: 24),
                      _buildSectionTitle(Icons.security, tr('security')),
                      _buildCard([
                        _buildSwitch(tr('vibration'), appState.vibrationEnabled, (v) => appState.toggleVibration(v)),
                        _buildOption('Xizmatni to\'xtatish', () {}),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle(Icons.support_agent_rounded, 'Aloqa va Yordam'),
                      _buildCard([
                        _buildOption('Fikr va mulohazalar', () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen()));
                        }),
                      ]),
                      const SizedBox(height: 40),

                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40, left: 20, right: 20),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
      child: Column(children: [
        const Icon(Icons.shield_rounded, color: Colors.white, size: 50),
        const SizedBox(height: 10),

        Text('SERGAK', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(tr('device_protected'), style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70)),
      ]),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(children: [Icon(icon, color: AppColors.primary, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLangOption(String title, String code, AppState state) {
    final isSelected = state.language == code;
    return ListTile(
      title: Text(title), 
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.circle_outlined, size: 20),
      onTap: () => state.setLanguage(code),
    );
  }

  Widget _buildPermTile(String title, Permission p) {
    final isGranted = _permStatus[p] ?? false;
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Switch(
        value: isGranted,
        onChanged: (val) => _togglePermission(p),
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SERGAK PREMIUM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              Icon(Icons.workspace_premium_rounded, color: Colors.black87),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Barcha himoya vositalari va cheksiz seifdan foydalanish uchun aktivlashtiring.', style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Center(child: Text('Hozir faollashtirish')),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String title, VoidCallback onTap) {
    return ListTile(title: Text(title, style: const TextStyle(fontSize: 14)), trailing: const Icon(Icons.chevron_right, size: 20), onTap: onTap);
  }

  Widget _buildSwitch(String title, bool val, Function(bool) onChanged) {
    return ListTile(title: Text(title, style: const TextStyle(fontSize: 14)), trailing: Switch(value: val, onChanged: onChanged, activeColor: Colors.green));
  }
}
