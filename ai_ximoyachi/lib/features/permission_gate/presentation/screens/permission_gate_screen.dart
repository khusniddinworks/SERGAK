import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';

class PermissionGateScreen extends StatefulWidget {
  final VoidCallback onAllGranted;
  const PermissionGateScreen({super.key, required this.onAllGranted});

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen> {
  bool _isRequesting = false;

  Future<void> _requestPermissions() async {
    setState(() => _isRequesting = true);
    
    // 1. Oddiy ruxsatnomalar
    await [
      Permission.sms,
      Permission.phone,
      Permission.notification,
    ].request();

    // 2. Maxsus ruxsatnomalar (Alohida so'raladi, chunki ular Settings'ga o'tkazishi mumkin)
    if (await Permission.storage.isDenied) await Permission.storage.request();
    if (await Permission.manageExternalStorage.isDenied) await Permission.manageExternalStorage.request();
    if (await Permission.scheduleExactAlarm.isDenied) await Permission.scheduleExactAlarm.request();

    final smsGranted = await Permission.sms.isGranted;
    final phoneGranted = await Permission.phone.isGranted;
    
    if (smsGranted && phoneGranted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permissions_granted', true);
      widget.onAllGranted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xavfsizlik uchun SMS va Telefon ruxsatlari shart!')),
      );
    }
    setState(() => _isRequesting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const HugeIcon(icon: HugeIcons.strokeRoundedShield01, size: 80, color: AppColors.primary),
            const SizedBox(height: 32),
            const Text(
              'Xavfsizlik Ruxsatlari', 
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24, 
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SERGAK tizimi sizni himoya qilishi va fayllarni shifrlashi uchun quyidagi ruxsatnomalar zarur:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            _buildPermissionItem(HugeIcons.strokeRoundedMessageLock01, 'SMS va Qo\'ng\'iroqlar himoyasi'),
            _buildPermissionItem(HugeIcons.strokeRoundedSquareLock02, 'Maxfiy fayllar seyfi (Xotira)'),
            _buildPermissionItem(HugeIcons.strokeRoundedNotification03, 'Xavfli ilovalardan ogohlantirish'),
            _buildPermissionItem(HugeIcons.strokeRoundedClock01, 'Aniq vaqtda ogohlantirish (Taymer)'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isRequesting ? null : _requestPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isRequesting 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text(
                      'RUXSAT BERISH', 
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(List<List<dynamic>> icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: AppColors.primary, size: 24), 
          const SizedBox(width: 16), 
          Expanded(
            child: Text(
              text, 
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
