import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../payment/presentation/screens/premium_screen.dart';
import '../../../privacy_center/presentation/screens/privacy_center_screen.dart';
import 'feedback_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        final isPremium = AppState().isPremium;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundCard,
            elevation: 0,
            title: const Text(
              'Sozlamalar',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLicenseCard(isPremium),
                
                _buildGroup('XAVFSIZLIK', [
                  _buildSettingsTile(
                    icon: HugeIcons.strokeRoundedShieldUser,
                    title: 'Privacy Center',
                    subtitle: 'Ruxsatnomalar va xavfsizlik audit',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyCenterScreen()),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: HugeIcons.strokeRoundedCpu,
                    title: 'Device ID',
                    subtitle: AppState().deviceId,
                  ),
                ]),
                
                _buildGroup('BILDIRISHNOMALAR', [
                  _buildSettingsTile(
                    icon: HugeIcons.strokeRoundedNotification03,
                    title: 'Fraud ogohlantirishlari',
                    subtitle: 'Xavf aniqlanganda ogohlantirishlar',
                    trailing: SizedBox(
                      height: 28,
                      width: 44,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: Switch(
                          value: _notifEnabled,
                          onChanged: (v) => setState(() => _notifEnabled = v),
                        ),
                      ),
                    ),
                  ),
                ]),
                
                _buildGroup('PREMIUM', [
                  _buildSettingsTile(
                    icon: HugeIcons.strokeRoundedCrown,
                    title: 'Litsenziya holati',
                    subtitle: isPremium ? 'Premium Faol' : 'Bepul Sinov Rejimi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PremiumScreen()),
                      );
                    },
                  ),
                ]),
                
                _buildGroup('HAQIDA', [
                  _buildSettingsTile(
                    icon: HugeIcons.strokeRoundedGlobe02,
                    title: 'Til (Language)',
                    subtitle: AppState().language == 'uz' ? 'O\'zbekcha' : (AppState().language == 'ru' ? 'Русский' : 'English'),
                    onTap: _showLanguagePicker,
                  ),
                  _buildSettingsTile(
                    icon: HugeIcons.strokeRoundedShield01,
                    title: 'Maxfiylik siyosati',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: HugeIcons.strokeRoundedMessage01,
                    title: 'Fikr-mulohaza yuborish',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                      );
                    },
                  ),
                  _buildSettingsTile(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    title: 'Versiya',
                    subtitle: '1.0.0',
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLicenseCard(bool isPremium) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isPremium ? AppColors.premiumGradient : AppColors.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? AppColors.premium : AppColors.primary).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCrown,
            color: isPremium ? AppColors.premiumGold : Colors.white,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Premium Faol' : 'Bepul Sinov Rejimi',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  isPremium ? 'Litsenziya faollashtirilgan' : '7-kunlik sinov davri',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (!isPremium)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                minimumSize: const Size(90, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('PRO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }

  Widget _buildGroup(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: tiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final tile = entry.value;
              return Column(
                children: [
                  tile,
                  if (idx < tiles.length - 1) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required List<List<dynamic>> icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.backgroundInput,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: HugeIcon(icon: icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: trailing ?? (onTap != null ? const HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.textDisabled, size: 18) : null),
      onTap: onTap,
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tilni tanlang',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('O\'zbekcha'),
              trailing: AppState().language == 'uz' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                AppState().setLanguage('uz');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Русский'),
              trailing: AppState().language == 'ru' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                AppState().setLanguage('ru');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: AppState().language == 'en' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                AppState().setLanguage('en');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
