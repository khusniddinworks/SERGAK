import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final TextEditingController _keyController = TextEditingController();
  bool _isLoading = false;
  String _errorText = '';

  Future<void> _verifyKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorText = '';
    });

    final success = await AppState().verifyAndActivatePremium(key);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium muvaffaqiyatli faollashtirildi! 🎉'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _errorText = 'Noto\'g\'ri litsenziya kaliti yoki muddat o\'tgan!';
      });
    }
  }

  Future<void> _openTelegramBot(String plan) async {
    final deviceId = AppState().deviceId;
    final url = Uri.parse('https://t.me/sergakaibot?start=premium_${deviceId}_$plan');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceId = AppState().deviceId;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SERGAK PREMIUM',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.amber),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 64, color: Colors.amber),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Premium bilan to\'liq himoya',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              '• Cheksiz Deepfake ovoz tahlili\n• Ota-ona nazorati va bot sinxronizatsiyasi\n• Maxfiy seyf (AES-256 shifrlash)\n• AI Yordamchi va kunlik eslatmalar',
              style: GoogleFonts.outfit(fontSize: 15, color: Colors.white70, height: 1.5),
            ),
            
            if (AppState().trialDaysLeft > 0 && AppState().isPremium) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
                child: Text(
                  '🎉 Sizda 7 kunlik bepul Premium rejimi yoniq!\nQolgan vaqt: ${AppState().trialDaysLeft} kun',
                  style: GoogleFonts.outfit(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Device ID
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sizning qurilma ID (Device ID):', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
                      const SizedBox(height: 4),
                      Text(deviceId, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.amber),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: deviceId));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID nusxalandi!')));
                    },
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Packages
            Text('1. Paketni tanlang va bot orqali to\'lang:', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _buildPackageCard(
              title: '3 Oylik Obuna',
              price: '25,000 so\'m',
              onTap: () => _openTelegramBot('3month'),
            ),
            const SizedBox(height: 12),
            _buildPackageCard(
              title: '1 Yillik Obuna (Tavsiya)',
              price: '85,000 so\'m',
              isPopular: true,
              onTap: () => _openTelegramBot('1year'),
            ),
            const SizedBox(height: 32),

            // License Key Input
            Text('2. Litsenziya kalitini kiriting:', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Telegram bot bergan kalitni joylang...',
                hintStyle: const TextStyle(color: Colors.white38),
                errorText: _errorText.isNotEmpty ? _errorText : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Activate Button
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.black)
                : Text('FAOLLASHTIRISH', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard({required String title, required String price, bool isPopular = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPopular ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPopular ? Colors.amber : Colors.white24, width: isPopular ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                    child: Text('TAVSIYA', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(price, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.amber)),
              ],
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
