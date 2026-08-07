import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';

class FraudMonitorScreen extends StatefulWidget {
  const FraudMonitorScreen({super.key});

  @override
  State<FraudMonitorScreen> createState() => _FraudMonitorScreenState();
}

class _FraudMonitorScreenState extends State<FraudMonitorScreen> {
  static const platform = MethodChannel('com.aiximoyachi/fraud_monitor');
  bool _isMonitoringEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final bool hasPermissions = await platform.invokeMethod('checkPermissions');
      if (mounted) {
        setState(() {
          _isMonitoringEnabled = hasPermissions;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleMonitoring(bool enable) async {
    if (!enable) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppColors.backgroundCard,
          title: const Text(
            'O\'chirishni tasdiqlang',
            style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          content: const Text(
            'SMS himoyasini o\'chirsangiz, firibgarlik harakatlari haqida ogohlantirish berilmaydi.',
            style: TextStyle(fontFamily: 'Outfit', color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bekor qilish', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('O\'chirish', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      if (enable) {
        final bool result = await platform.invokeMethod('startFraudMonitor');
        if (mounted) setState(() => _isMonitoringEnabled = result);
      } else {
        await platform.invokeMethod('stopFraudMonitor');
        if (mounted) setState(() => _isMonitoringEnabled = false);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SMS Shield',
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            const Text(
              'Qanday ishlaydi?',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildHowItWorksCard(),
            const SizedBox(height: 24),
            const Text(
              'Kuzatiladigan kalit so\'zlar',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildKeywordsWrap(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final active = _isMonitoringEnabled;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: active ? AppColors.primaryGradient : null,
        color: active ? null : AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: active ? null : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: (active ? AppColors.primary : Colors.black).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SMS Himoya Servisi',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.textOnPrimary.withOpacity(0.8) : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    active ? 'FAOL' : 'O\'CHIRILGAN',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: active ? AppColors.textOnPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: active,
                onChanged: _toggleMonitoring,
                activeColor: AppColors.textOnPrimary,
                activeTrackColor: AppColors.textOnPrimary.withOpacity(0.3),
                inactiveThumbColor: AppColors.textSecondary,
                inactiveTrackColor: AppColors.border,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: active ? AppColors.textOnPrimary.withOpacity(0.2) : AppColors.border, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Skanerlangan', '47 SMS', active),
              _buildMiniStat('Aniqlangan', '0 fraud', active),
              _buildMiniStat('Holat', active ? 'Kuzatuvda' : 'Nofaol', active),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, bool active) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: active ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.textOnPrimary.withOpacity(0.8) : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildStepItem('1', 'SMS keladi', 'Barcha kiruvchi SMS xabarlar fon rejimida tekshiriladi'),
          const Divider(height: 24),
          _buildStepItem('2', 'Matn tahlil qilinadi', 'Firibgarlik belgilari va OTP kodlar izlanadi'),
          const Divider(height: 24),
          _buildStepItem('3', 'Qo\'ng\'iroq tekshiruvi', 'Siz telefonda kim bilandir gaplashayotganingiz aniqlanadi'),
          const Divider(height: 24),
          _buildStepItem('4', 'Proaktiv Ogohlantirish', 'Agar fraud sezilsa, darhol ekranda maxsus ogohlantirish ko\'rsatiladi'),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
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
      ],
    );
  }

  Widget _buildKeywordsWrap() {
    final keywords = ['kod', 'parol', 'OTP', 'bank', 'click', 'payme', 'uzcard', 'humo', 'tasdiqlash', 'pin'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: keywords.map((word) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.backgroundInput,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            word,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }
}
