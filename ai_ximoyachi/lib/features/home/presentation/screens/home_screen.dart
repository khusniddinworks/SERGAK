import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../fraud_monitor/presentation/screens/fraud_monitor_screen.dart';
import '../../../safe_url/presentation/screens/safe_url_screen.dart';
import '../../../permission_analyzer/presentation/screens/permission_screen.dart';
import '../../smart_scan/presentation/screens/smart_scan_screen.dart';
import '../../qr_scanner/presentation/screens/qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _statsCh = MethodChannel('com.aiximoyachi/system_stats');
  static const _fraudCh = MethodChannel('com.aiximoyachi/fraud_monitor');

  bool _fraudEnabled   = true;
  double _ramUsage     = 0.64;
  double _cpuUsage     = 0.12;
  int _dangerousCount  = 0;
  int _threatsBlocked  = 0;

  Timer? _timer;

  String tr(String key) => AppTranslations.get(key, AppState().language);

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _fetchStats();
    _initFraudMonitor();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchStats());
  }

  Future<void> _initFraudMonitor() async {
    try {
      final granted = await _fraudCh.invokeMethod<bool>('checkPermissions') ?? false;
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
      _dangerousCount = prefs.getInt('dangerous_count') ?? 0;
      _threatsBlocked = prefs.getInt('threats_blocked_count') ?? 0;
    });
  }

  Future<void> _fetchStats() async {
    try {
      final result = await _statsCh.invokeMapMethod<String, double>('getSystemStats');
      if (result != null && mounted) {
        setState(() {
          _ramUsage = result['ramUsage'] ?? 0.64;
          _cpuUsage = result['cpuUsage'] ?? 0.12;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFraudMonitor(bool value) async {
    try {
      if (value) {
        final granted = await _fraudCh.invokeMethod<bool>('startFraudMonitor') ?? false;
        if (mounted) setState(() => _fraudEnabled = granted);
      } else {
        await _fraudCh.invokeMethod('stopFraudMonitor');
        if (mounted) setState(() => _fraudEnabled = false);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundCard,
            elevation: 0,
            title: const Text(
              'SERGAK',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification03,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSecurityScoreCard(),
                const SizedBox(height: 20),
                _buildSmartScanButton(),
                const SizedBox(height: 24),
                const Text(
                  'Tezkor harakatlar',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickActionsGrid(),
                const SizedBox(height: 24),
                _buildSystemStatusCard(),
                const SizedBox(height: 24),
                _buildRecentThreatsSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityScoreCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xavfsizlik Skori',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnPrimary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      // Tween count-up animation for score
                      TweenAnimationBuilder<int>(
                        duration: const Duration(seconds: 2),
                        tween: IntTween(begin: 0, end: 87),
                        builder: (context, value, child) {
                          return Text(
                            '$value',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textOnPrimary,
                              height: 1.0,
                            ),
                          );
                        },
                      ),
                      Text(
                        ' / 100',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnPrimary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.textOnPrimary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedShield01,
                    color: AppColors.textOnPrimary,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.87,
              backgroundColor: AppColors.textOnPrimary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textOnPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'XAVFSIZ',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Text(
                'Bugun himoyalangan: 100%',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textOnPrimary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartScanButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SmartScanScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedQrScanner,
              color: AppColors.textOnPrimary,
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'SMART SCAN BOSHLASH',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.25,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildActionCard(
          title: 'SMS Shield',
          subtitle: _fraudEnabled ? 'FAOL' : 'O\'CHIRILGAN',
          icon: HugeIcons.strokeRoundedMessageLock01,
          iconBg: AppColors.primaryLight,
          iconColor: AppColors.primary,
          trailing: SizedBox(
            height: 28,
            width: 44,
            child: FittedBox(
              fit: BoxTheme.scale ?? BoxFit.fill,
              child: Switch(
                value: _fraudEnabled,
                onChanged: _toggleFraudMonitor,
              ),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FraudMonitorScreen()),
            );
          },
        ),
        _buildActionCard(
          title: 'URL Skanerlash',
          subtitle: 'Havola tekshirish',
          icon: HugeIcons.strokeRoundedLink01,
          iconBg: AppColors.primaryLight,
          iconColor: AppColors.primary,
          trailing: const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.textSecondary, size: 20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafeUrlScreen()),
            );
          },
        ),
        _buildActionCard(
          title: 'Ilovalar',
          subtitle: '$_dangerousCount ta xavfli ruxsat',
          icon: HugeIcons.strokeRoundedGridView,
          iconBg: AppColors.warningLight,
          iconColor: AppColors.warning,
          trailing: const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.textSecondary, size: 20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PermissionScreen()),
            );
          },
        ),
        _buildActionCard(
          title: 'QR Scanner',
          subtitle: 'Xavfsiz QR Skan',
          icon: HugeIcons.strokeRoundedQrCode,
          iconBg: AppColors.primaryLight,
          iconColor: AppColors.primary,
          trailing: const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.textSecondary, size: 20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrScannerScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: HugeIcon(icon: icon, color: iconColor, size: 22),
                  ),
                ),
                trailing,
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tizim holati',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('RAM', '${(_ramUsage * 100).toInt()}%', AppColors.primary),
              Container(width: 1, height: 32, color: AppColors.border),
              _buildStatItem('CPU', '${(_cpuUsage * 100).toInt()}%', AppColors.warning),
              Container(width: 1, height: 32, color: AppColors.border),
              _buildStatItem('Himoya', _fraudEnabled ? 'FAOL' : 'O\'CHIQ', AppColors.safe),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentThreatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'So\'nggi tahdidlar',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Barchasi →',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.safe,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tizim xavfsiz holda ishlamoqda',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hech qanday aktiv tahdid aniqlanmadi',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedShield01,
                color: AppColors.safe,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class BoxTheme {
  static const scale = null;
}
