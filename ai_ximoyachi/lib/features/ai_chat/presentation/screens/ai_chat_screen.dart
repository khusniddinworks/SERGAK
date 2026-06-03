import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../payment/presentation/screens/premium_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'message': 'Salom! Men SERGAK sun\'iy intellekt yordamchisiman. Sizga qanday yordam bera olaman?'},
  ];

  String tr(String key) => AppTranslations.get(key, AppState().language);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        if (!AppState().isPremium) {
          return _buildPremiumLocked(context);
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final isAi = _messages[index]['role'] == 'ai';
                    return _buildMessage(isAi, _messages[index]['message']!);
                  },
                ),
              ),
              _buildInput(),
            ],
          ),
        );
      }
    );
  }

  Widget _buildPremiumLocked(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0C10) : Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.workspace_premium_rounded, size: 80, color: Colors.amber),
              const SizedBox(height: 24),
              Text(
                'Premium Xizmat',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                'AI Yordamchi faqat Premium tarifda ishlaydi.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('PREMIUM FAOLLASHTIRISH', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(children: [
        Image.asset('assets/images/logo_icon.png.png', height: 40),
        const SizedBox(height: 8),
        Text('SERGAK', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(tr('ai_assistant'), style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70)),
      ]),
    );
  }

  Widget _buildMessage(bool isAi, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAi ? (isDark ? const Color(0xFF1E1E1E) : Colors.white) : AppColors.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAi ? 0 : 20),
            bottomRight: Radius.circular(isAi ? 20 : 0),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Text(
          text,
          style: TextStyle(color: isAi ? (isDark ? Colors.white : AppColors.textPrimary) : Colors.white),
        ),
      ),
    );
  }

  Widget _buildInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: tr('type_message'),
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  setState(() {
                    _messages.add({'role': 'user', 'message': _controller.text});
                    _controller.clear();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
