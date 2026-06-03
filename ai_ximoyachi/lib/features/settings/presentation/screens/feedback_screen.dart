import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  // DIQQAT: Telegram bot tokeningizni va o'zingizning Chat ID yoki Admin ID ngizni yozing
  final String _botToken = "8919785570:AAGtLi0Y-8xBv1jyOXSS98Fg3JleAQEHWWw"; 
  final String _adminChatId = "8332161047";

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Qurilma nomini aniqlash
      String deviceName = "Noma'lum qurilma";
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      }

      // Telegramga yuboriladigan xabar formati
      final telegramMessage = "📝 *Yangi Fikr / Shikoyat*\n\n"
          "📱 *Qurilma:* $deviceName\n"
          "💬 *Xabar:* $message";

      final url = Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chat_id": _adminChatId,
          "text": telegramMessage,
          "parse_mode": "Markdown",
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xabaringiz muvaffaqiyatli yuborildi! Katta rahmat!'), backgroundColor: Colors.green),
          );
          _messageController.clear();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xatolik yuz berdi. Bot sozlamalarini tekshiring!'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Internetga ulanishda xatolik!'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          'Fikr va Mulohazalar',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.support_agent_rounded, size: 64, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Bizga xabar qoldiring',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "Ilova bo'yicha taklif, shikoyat yoki topilgan xatoliklarni yozib yuboring. Xabaringiz to'g'ridan-to'g'ri dasturchiga yetib boradi.",
              style: GoogleFonts.outfit(fontSize: 15, color: isDark ? Colors.white70 : Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _messageController,
              maxLines: 6,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Xabaringizni bu yerga yozing...',
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('YUBORISH', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
