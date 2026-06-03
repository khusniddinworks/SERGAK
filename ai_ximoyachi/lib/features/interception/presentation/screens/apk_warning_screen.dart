import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class ApkWarningScreen extends StatelessWidget {
  final String? filePath;
  const ApkWarningScreen({super.key, this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 100, color: Colors.red),
            const SizedBox(height: 32),
            Text('XAVF ANIQLANDI!', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red[100]!)),
              child: const Text(
                'Telegram yoki brauzerdan yuklangan ushbu APK fayl qurilmangiz uchun xavfli bo\'lishi mumkin. SERGAK uni o\'rnatishni tavsiya etmaydi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, height: 1.5),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('O\'RNATISHNI BEKOR QILISH', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                if (filePath != null) {
                  try {
                    const platform = MethodChannel('com.aiximoyachi/install_apk');
                    await platform.invokeMethod('installApk', {'uri': filePath});
                  } catch (e) {
                    debugPrint('Install error: $e');
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Baribir o\'rnatish (Tavsiya etilmaydi)', style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    );
  }
}
