import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final TextEditingController _keyController = TextEditingController();
  bool _isActivating = false;
  String? _keyError;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _activate() {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _keyError = 'Kalit kiriting');
      return;
    }

    setState(() {
      _isActivating = true;
      _keyError = null;
    });

    Future.delayed(const Duration(seconds: 1), () async {
      if (mounted) {
        final success = await AppState().verifyAndActivatePremium(key);
        setState(() => _isActivating = false);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Premium muvaffaqiyatli faollashtirildi!'),
                backgroundColor: AppColors.safe,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          setState(() => _keyError = 'Litsenziya kaliti noto\'g\'ri yoki muddati o\'tgan');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nimalar kiradi?',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureTile(HugeIcons.strokeRoundedLink01, 'Cheksiz URL Skanerlash', 'Kunlik 3 ta limit yo\'q'),
                  _buildFeatureTile(HugeIcons.strokeRoundedSquareLock02, 'Vault (AES-256)', 'Fayllarni shifrlab saqlash'),
                  _buildFeatureTile(HugeIcons.strokeRoundedVoice, 'Deepfake Ovoz Tahlili', 'Ovoz soxtaligini aniqlash'),
                  _buildFeatureTile(HugeIcons.strokeRoundedNotification03, 'Kundalik Maslahatlar', '08:00 va 15:00 da bildirishnoma'),
                  _buildFeatureTile(HugeIcons.strokeRoundedClock01, 'Tahdidlar tarixi', '1 yillik barcha voqealar'),
                  _buildFeatureTile(HugeIcons.strokeRoundedAiChat02, 'AI Chat (cheksiz)', 'Cheksiz savol-javob'),
                  const SizedBox(height: 24),
                  const Text(
                    'Litsenziya kaliti bor bo\'lsa:',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'XXXX-XXXX-XXXX-XXXX',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: HugeIcon(icon: HugeIcons.strokeRoundedKey01, color: AppColors.premium, size: 20),
                      ),
                      errorText: _keyError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.premium.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isActivating ? null : _activate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.premium,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isActivating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'AKTIVLASHTIRISH',
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Kalit sotib olish uchun: premium@sergak.uz',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 100, bottom: 36, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedCrown, size: 64, color: AppColors.premiumGold),
          const SizedBox(height: 16),
          const Text(
            'SERGAK Premium',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'To\'liq himoya — 49,000 so\'m / yil',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(List<List<dynamic>> icon, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.premiumLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: HugeIcon(icon: icon, color: AppColors.premium, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
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
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, color: AppColors.premiumGold, size: 22),
        ],
      ),
    );
  }
}
