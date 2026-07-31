import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/state/app_state.dart';

class ApkWarningScreen extends StatelessWidget {
  final String? filePath;
  const ApkWarningScreen({super.key, this.filePath});

  String get _lang => AppState().language;

  String _getApkWarningTitle(String lang) {
    switch (lang) {
      case 'ru': return 'ОБНАРУЖЕНА УГРОЗА!';
      case 'en': return 'THREAT DETECTED!';
      default: return 'XAVF ANIQLANDI!';
    }
  }

  String _getApkWarningDesc(String lang) {
    switch (lang) {
      case 'ru': return 'Установка этого APK-файла, загруженного из Telegram или браузера, может быть опасной для вашего устройства. SERGAK не рекомендует его установку.';
      case 'en': return 'This APK file downloaded from Telegram or a browser might be dangerous for your device. SERGAK does not recommend installing it.';
      default: return 'Telegram yoki brauzerdan yuklangan ushbu APK fayl qurilmangiz uchun xavfli bo\'lishi mumkin. SERGAK uni o\'rnatishni tavsiya etmaydi.';
    }
  }

  String _getCancelButtonText(String lang) {
    switch (lang) {
      case 'ru': return 'ОТМЕНИТЬ УСТАНОВКУ';
      case 'en': return 'CANCEL INSTALLATION';
      default: return 'O\'RNATISHNI BEKOR QILISH';
    }
  }

  String _getInstallAnywayText(String lang) {
    switch (lang) {
      case 'ru': return 'Все равно установить (Не рекомендуется)';
      case 'en': return 'Install anyway (Not recommended)';
      default: return 'Baribir o\'rnatish (Tavsiya etilmaydi)';
    }
  }

  @override
  Widget build(BuildContext context) {
    const warningColor = Color(0xFFFF3366); // Neon Warning Red/Pink

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10), // Matching the app dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Glow Effect
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: warningColor.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: warningColor.withOpacity(0.3),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Column(
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        size: 56,
                        color: warningColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SERGAK APK HIMOYA',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  // Pulse ring / Warning symbol
                  SizedBox(
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: warningColor.withOpacity(0.2),
                              width: 8,
                            ),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: warningColor.withOpacity(0.5),
                              width: 4,
                            ),
                          ),
                          child: const Icon(
                            Icons.security_update_warning_rounded,
                            size: 40,
                            color: warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Warning Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: warningColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: warningColor.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getApkWarningTitle(_lang),
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: warningColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getApkWarningDesc(_lang),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Actions
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: warningColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: warningColor.withOpacity(0.4),
                    ),
                    child: Text(
                      _getCancelButtonText(_lang),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
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
                    child: Text(
                      _getInstallAnywayText(_lang),
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
