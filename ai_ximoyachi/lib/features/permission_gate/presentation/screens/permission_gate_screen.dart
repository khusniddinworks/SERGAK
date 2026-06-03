import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security_rounded, size: 100, color: AppColors.primary),
            const SizedBox(height: 32),
            Text('Xavfsizlik Ruxsatlari', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'SERGAK tizimi sizni himoya qilishi va fayllarni shifrlashi uchun quyidagi ruxsatnomalar zarur:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 48),
            _buildPermissionItem(Icons.sms, 'SMS va Qo\'ng\'iroqlar himoyasi'),
            _buildPermissionItem(Icons.lock_outline, 'Maxfiy fayllar seyfi (Xotira)'), // Tuzatildi ✅
            _buildPermissionItem(Icons.notifications_active, 'Xavfli ilovalardan ogohlantirish'),
            _buildPermissionItem(Icons.timer_outlined, 'Aniq vaqtda ogohlantirish (Taymer)'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isRequesting ? null : _requestPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                child: _isRequesting 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('RUXSAT BERISH', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 24), 
        const SizedBox(width: 16), 
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)))
      ]),
    );
  }
}
