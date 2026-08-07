import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/state/app_state.dart';
import '../../../payment/presentation/screens/premium_screen.dart';
import '../../../../core/theme/app_colors.dart';

class DeepfakeScanScreen extends StatefulWidget {
  final String audioPath;

  const DeepfakeScanScreen({super.key, required this.audioPath});

  @override
  State<DeepfakeScanScreen> createState() => _DeepfakeScanScreenState();
}

class _DeepfakeScanScreenState extends State<DeepfakeScanScreen> with TickerProviderStateMixin {
  bool _isFinished = false;
  bool _isFake = false;
  int _fakePercentage = 0;
  
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _simulateScan();
  }

  void _simulateScan() {
    if (!AppState().isPremium) {
      // If not premium, stop the scan and show the Premium Screen
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PremiumScreen()),
          );
        }
      });
      return;
    }

    // Simulyatsiya: 4 soniyadan so'ng natija tayyor bo'ladi
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isFinished = true;
          _pulseController.stop();
          _waveController.stop();
          
          // Random simulyatsiya uchun: 50% ehtimollik bilan fake yoki real
          final random = Random();
          _isFake = random.nextBool();
          _fakePercentage = _isFake ? (85 + random.nextInt(14)) : (1 + random.nextInt(15));
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String get _lang => AppState().language;

  Color get _currentColor {
    if (!_isFinished) return AppColors.primary; // Scanning (Cyan)
    return _isFake ? AppColors.danger : AppColors.safe; // Red or Green
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Glow Effect
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentColor.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(color: _currentColor.withOpacity(0.3), blurRadius: 100, spreadRadius: 50),
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
                  _buildHeader(),
                  const SizedBox(height: 60),
                  _buildAudioWaves(),
                  const SizedBox(height: 60),
                  _buildStatusCard(),
                  const Spacer(),
                  if (_isFinished) _buildBottomActions(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        HugeIcon(
          icon: _isFinished 
            ? (_isFake ? HugeIcons.strokeRoundedShieldAlert : HugeIcons.strokeRoundedShieldCheck)
            : HugeIcons.strokeRoundedVoice,
          size: 48,
          color: _currentColor,
        ),
        const SizedBox(height: 16),
        Text(
          'SERGAK AI AUDIO',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioWaves() {
    return SizedBox(
      height: 120,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(20, (index) {
              // Wave height math
              final randomHeight = _isFinished 
                ? (_isFake ? 20.0 + Random().nextInt(10) : 10.0 + Random().nextInt(5))
                : 20.0 + (sin((_waveController.value * 2 * pi) + index) * 40).abs();
                
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 6,
                height: randomHeight,
                decoration: BoxDecoration(
                  color: _currentColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _currentColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: !_isFinished
          ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _currentColor.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(color: _currentColor),
                  const SizedBox(height: 24),
                  Text(
                    AppTranslations.get('analyzing_audio', _lang),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _currentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _currentColor.withOpacity(0.5), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    '$_fakePercentage%',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: _currentColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppTranslations.get(_isFake ? 'deepfake_detected' : 'safe_audio', _lang),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppTranslations.get(_isFake ? 'deepfake_desc' : 'safe_desc', _lang),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBottomActions() {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.backgroundCard,
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Text(
        AppTranslations.get('home', _lang),
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
