import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class UrlScanScreen extends StatefulWidget {
  final String url;

  const UrlScanScreen({super.key, required this.url});

  @override
  State<UrlScanScreen> createState() => _UrlScanScreenState();
}

class _UrlScanScreenState extends State<UrlScanScreen> with TickerProviderStateMixin {
  double _progress = 0.0;
  int _secondsLeft = 35;
  String _statusMessage = 'Havfsizlikni tekshirish boshlanmoqda...';
  bool _isFinished = false;
  bool _isSafe = true;
  int _riskScore = 0;
  String _category = 'Noma\'lum';
  String _countryCode = '';
  String _domainAge = '';
  bool _isPhishing = false;
  bool _isMalware = false;
  Timer? _timer;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startScanning();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startScanning() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
          _progress = (35 - _secondsLeft) / 35;
          
          if (_secondsLeft > 25) {
            _statusMessage = 'URL tahlil qilinmoqda...';
          } else if (_secondsLeft > 15) {
            _statusMessage = 'IPQualityScore orqali xavf tahlili...';
          } else if (_secondsLeft > 5) {
            _statusMessage = 'Fishing va Malware tekshiruvi...';
          } else {
            _statusMessage = 'Natijalar tayyorlanmoqda...';
          }
        } else {
          _timer?.cancel();
          _finishScan();
        }
      });
    });

    _performActualScan();
  }

  Future<void> _performActualScan() async {
    const apiKey = 'HRDlBBQfz6gdUn4yu8QlA1UzIyF2Yaxt';
    final encodedUrl = Uri.encodeComponent(widget.url);
    final apiUrl = 'https://www.ipqualityscore.com/api/json/url/$apiKey/$encodedUrl';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _riskScore = data['risk_score'] ?? 0;
            _category = data['category'] ?? 'Noma\'lum';
            _countryCode = data['country_code'] ?? '';
            _domainAge = data['domain_age']?['human'] ?? '';
            _isPhishing = data['phishing'] ?? false;
            _isMalware = data['malware'] ?? false;
            
            // Xavfni aniqlash
            if (_riskScore >= 75 || _isPhishing || _isMalware || (data['unsafe'] ?? false)) {
              _isSafe = false;
            } else {
              _isSafe = true;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('IPQS Scan error: $e');
    }
  }

  void _finishScan() {
    setState(() {
      _isFinished = true;
      _pulseController.stop();
      if (_isSafe) {
        _statusMessage = 'XAVFSIZ';
      } else {
        _statusMessage = 'XAVFLI: $_riskScore% risk aniqlandi';
      }
    });

    if (_isSafe) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _launchSafeUrl();
      });
    }
  }

  Future<void> _launchUrlBypassingSergak(String url) async {
    try {
      const platform = MethodChannel('com.aiximoyachi/browser');
      await platform.invokeMethod('openUrl', {'url': url});
    } catch (e) {
      debugPrint('Launch error: $e');
      // Fallback
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _launchSafeUrl() async {
    await _launchUrlBypassingSergak(widget.url);
    if (mounted) Navigator.pop(context);
  }

  Color get _currentColor {
    if (!_isFinished) return const Color(0xFF00F0FF); // Cyan for scanning
    return _isSafe ? const Color(0xFF00FF66) : const Color(0xFFFF3366); // Neon Green or Red
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C10),
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
                  const SizedBox(height: 50),
                  _buildScannerRadar(),
                  const SizedBox(height: 40),
                  _buildStatusText(),
                  const SizedBox(height: 40),
                  _buildGlassInfoCard(),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isFinished 
            ? (_isSafe ? Icons.gpp_good_rounded : Icons.gpp_bad_rounded)
            : Icons.security_rounded,
          size: 32,
          color: _currentColor,
        ),
        const SizedBox(width: 12),
        Text(
          'SERGAK XAVFSIZLIK',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildScannerRadar() {
    return SizedBox(
      height: 240,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse Animation
          if (!_isFinished)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(3, (index) {
                    final delay = index * 0.3;
                    double value = _pulseController.value - delay;
                    if (value < 0) value += 1.0;
                    return Transform.scale(
                      scale: 1.0 + (value * 1.5),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _currentColor.withOpacity((1.0 - value).clamp(0.0, 1.0) * 0.5),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          // Inner Glowing Circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF151822),
              boxShadow: [
                BoxShadow(
                  color: _currentColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(
                color: _currentColor.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isFinished ? '100%' : '${(_progress * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isFinished ? 'TUGADI' : 'SCAN...',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _currentColor,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Circular Progress Indicator
          if (!_isFinished)
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 4,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(_currentColor),
                strokeCap: StrokeCap.round,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _statusMessage,
        key: ValueKey<String>(_statusMessage),
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildGlassInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.link_rounded, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'MANZIL:',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white54,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              if (_isFinished) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.category_rounded, 'Kategoriya', _category),
                _buildDetailRow(Icons.public_rounded, 'Server', _countryCode.isNotEmpty ? _countryCode : 'Noma\'lum'),
                if (_domainAge.isNotEmpty) _buildDetailRow(Icons.hourglass_empty_rounded, 'Yoshi', _domainAge),
                _buildDetailRow(Icons.phishing_rounded, 'Fishing', _isPhishing ? 'Mavjud' : 'Xavfsiz', isAlert: _isPhishing),
                _buildDetailRow(Icons.bug_report_rounded, 'Malware', _isMalware ? 'Mavjud' : 'Xavfsiz', isAlert: _isMalware),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isAlert = false}) {
    final valueColor = isAlert ? const Color(0xFFFF3366) : (value == 'Xavfsiz' ? const Color(0xFF00FF66) : Colors.white);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white38),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      children: [
        if (_isSafe)
          _buildActionButton(
            label: 'SAYTGA O\'TISH',
            color: const Color(0xFF00FF66),
            icon: Icons.open_in_browser_rounded,
            onPressed: _launchSafeUrl,
          )
        else
          Column(
            children: [
              _buildActionButton(
                label: 'SAHIFANI YOPISH',
                color: const Color(0xFFFF3366),
                icon: Icons.warning_amber_rounded,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await _launchUrlBypassingSergak(widget.url);
                  if (mounted) Navigator.pop(context);
                },
                child: Text(
                  'Baribir kirish (Tavsiya etilmaydi)',
                  style: GoogleFonts.outfit(
                    color: Colors.grey,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white54,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          child: Text(
            'ORQAGA QAYTISH',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: const Color(0xFF0B0C10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
