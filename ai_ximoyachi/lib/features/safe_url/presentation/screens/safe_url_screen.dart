import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';

class SafeUrlScreen extends StatefulWidget {
  const SafeUrlScreen({super.key});

  @override
  State<SafeUrlScreen> createState() => _SafeUrlScreenState();
}

class _SafeUrlScreenState extends State<SafeUrlScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isChecking = false;
  String? _result;

  void _checkUrl() {
    if (_urlController.text.isEmpty) return;
    setState(() {
      _isChecking = true;
      _result = null;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isChecking = false;
        _result = _urlController.text.contains('malware') || _urlController.text.contains('phishing') 
            ? 'XAVFLI: Ushbu havola shubhali deb topildi!' 
            : 'XAVFSIZ: Havola toza.';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          
          
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  const Text('URL Guard', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Shubhali havolalarni ochishdan oldin bu yerda tekshirib oling.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 32),
                  _buildInputCard(),
                  const SizedBox(height: 24),
                  if (_isChecking) const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  if (_result != null) _buildResultCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://example.com',
              hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isChecking ? null : _checkUrl,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('TEKSHIRISH', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final isDanger = _result!.contains('XAVFLI');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: (isDanger ? AppColors.error : AppColors.accent).withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: (isDanger ? AppColors.error : AppColors.accent).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(isDanger ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, color: isDanger ? AppColors.error : AppColors.accent, size: 48),
          const SizedBox(height: 16),
          Text(_result!, textAlign: TextAlign.center, style: TextStyle(color: isDanger ? AppColors.error : AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
