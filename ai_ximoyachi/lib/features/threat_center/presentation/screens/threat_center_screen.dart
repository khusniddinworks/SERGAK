import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';

class ThreatCenterScreen extends StatefulWidget {
  const ThreatCenterScreen({super.key});

  @override
  State<ThreatCenterScreen> createState() => _ThreatCenterScreenState();
}

class _ThreatCenterScreenState extends State<ThreatCenterScreen> with TickerProviderStateMixin {
  late AnimationController _scanController;
  bool _isScanning = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isScanning = false;
          _progress = 1.0;
        });
        _showResult();
      }
    });
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _progress = 0.0;
    });
    _scanController.forward(from: 0.0);
  }

  void _showResult() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.accent),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.accent),
              SizedBox(width: 10),
              Text('Natija', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'Tizim to\'liq skanerlandi. Hech qanday zararli APK yoki fayl aniqlanmadi.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('TUSHUNARLI', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
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
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildScannerUI(),
                  const Spacer(),
                  _buildScanInfo(),
                  const SizedBox(height: 40),
                  _buildScanButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        const Text('Threat Center', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildScannerUI() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Orqa fondagi neon aylana
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 2),
          ),
        ),
        
        // Skanerlash animatsiyasi
        AnimatedBuilder(
          animation: _scanController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _scanController.value * 2 * 3.1415,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withOpacity(_isScanning ? 0.5 : 0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Markazdagi ikonka
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cardBackground,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            _isScanning ? Icons.radar_rounded : Icons.verified_user_rounded,
            color: AppColors.primary,
            size: 60,
          ),
        ),
      ],
    );
  }

  Widget _buildScanInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_isScanning ? 'Skanerlanmoqda...' : 'Tayyor', style: const TextStyle(color: Colors.white, fontSize: 16)),
              Text('${(_scanController.value * 100).toInt()}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _isScanning ? _scanController.value : _progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton(
        onPressed: _isScanning ? null : _startScan,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Text('TO\'LIQ SKANERLASH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
      ),
    );
  }
}
