import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../fraud_monitor/presentation/screens/fraud_monitor_screen.dart';
import '../../../safe_url/presentation/screens/safe_url_screen.dart';
import '../../../permission_analyzer/presentation/screens/permission_screen.dart';
import '../../../threat_center/presentation/screens/threat_center_screen.dart';
import '../../../vault/presentation/screens/vault_screen.dart';
import '../../../ai_chat/presentation/screens/ai_chat_screen.dart';
import '../../../interception/presentation/screens/deepfake_scan_screen.dart';
import '../../../smart_scan/presentation/screens/smart_scan_screen.dart';
import '../../../qr_scanner/presentation/screens/qr_scanner_screen.dart';
import '../../../privacy_center/presentation/screens/privacy_center_screen.dart';

class FeatureItem {
  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isPremium;
  final Widget destinationScreen;

  FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.isPremium = false,
    required this.destinationScreen,
  });
}

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final protectionFeatures = [
      FeatureItem(
        title: 'SMS Shield',
        subtitle: 'Fraud SMSlardan proaktiv himoya',
        icon: HugeIcons.strokeRoundedMessageLock01,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryLight,
        destinationScreen: const FraudMonitorScreen(),
      ),
      FeatureItem(
        title: 'URL Skanerlash',
        subtitle: 'Phishing va zararli havolalar tekshiruvi',
        icon: HugeIcons.strokeRoundedLink01,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryLight,
        destinationScreen: const SafeUrlScreen(),
      ),
      FeatureItem(
        title: 'Deepfake Ovoz',
        subtitle: 'AI bilan ovoz soxtaligini aniqlash',
        icon: HugeIcons.strokeRoundedVoice,
        iconColor: AppColors.premium,
        iconBgColor: AppColors.premiumLight,
        isPremium: true,
        destinationScreen: const DeepfakeScanScreen(audioPath: ''),
      ),
    ];

    final analysisFeatures = [
      FeatureItem(
        title: 'Ilovalar tahlili',
        subtitle: 'Xavfli ruxsatnomalarni tahlil qilish',
        icon: HugeIcons.strokeRoundedGridView,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryLight,
        destinationScreen: const PermissionScreen(),
      ),
      FeatureItem(
        title: 'Tahdidlar markazi',
        subtitle: 'Aniqlangan barcha tahdidlar tarixi',
        icon: HugeIcons.strokeRoundedAlert02,
        iconColor: AppColors.danger,
        iconBgColor: AppColors.dangerLight,
        destinationScreen: const ThreatCenterScreen(),
      ),
      FeatureItem(
        title: 'Smart Scan',
        subtitle: 'Yuklangan xavfli fayllarni skanerlash',
        icon: HugeIcons.strokeRoundedQrCode,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryLight,
        destinationScreen: const SmartScanScreen(),
      ),
      FeatureItem(
        title: 'QR Scanner',
        subtitle: 'Xavfsiz QR-kodlarni skanerlash',
        icon: HugeIcons.strokeRoundedQrCode,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryLight,
        destinationScreen: const QrScannerScreen(),
      ),
    ];

    final vaultAndAiFeatures = [
      FeatureItem(
        title: 'Xavfsiz saqlash (Vault)',
        subtitle: 'AES-256 shifrlangan fayllar ombori',
        icon: HugeIcons.strokeRoundedSquareLock02,
        iconColor: AppColors.premium,
        iconBgColor: AppColors.premiumLight,
        isPremium: true,
        destinationScreen: const VaultScreen(),
      ),
      FeatureItem(
        title: 'AI Yordamchi',
        subtitle: 'Oflayn kiberxavfsizlik maslahatgichi',
        icon: HugeIcons.strokeRoundedAiChat02,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryLight,
        destinationScreen: const AiChatScreen(),
      ),
      FeatureItem(
        title: 'Privacy Center',
        subtitle: 'Ruxsatnomalar boshqaruvi',
        icon: HugeIcons.strokeRoundedShieldUser,
        iconColor: AppColors.primary,
        iconBgColor: AppColors.primaryLight,
        destinationScreen: const PrivacyCenterScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
        title: const Text(
          'Barcha funksiyalar',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
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
            _buildCategoryTitle('Himoya vositalari'),
            ...protectionFeatures.map((f) => _buildFeatureCard(context, f)),
            const SizedBox(height: 16),
            _buildCategoryTitle('Tahlil vositalari'),
            ...analysisFeatures.map((f) => _buildFeatureCard(context, f)),
            const SizedBox(height: 16),
            _buildCategoryTitle('Saqlash, AI va Maxfiylik'),
            ...vaultAndAiFeatures.map((f) => _buildFeatureCard(context, f)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, FeatureItem feature) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => feature.destinationScreen),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: feature.iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: HugeIcon(icon: feature.icon, color: feature.iconColor, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feature.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (feature.isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.premium.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.premiumGold, width: 1),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.premiumGold,
                  ),
                ),
              )
            else
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textDisabled,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
