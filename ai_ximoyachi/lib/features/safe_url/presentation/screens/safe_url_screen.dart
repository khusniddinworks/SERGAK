import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';

class ScanResult {
  final String url;
  final int riskScore;
  final bool isPhishing;
  final bool isMalware;
  final bool isDangerous;
  final String? domainAge;
  final String? countryCode;

  ScanResult({
    required this.url,
    required this.riskScore,
    required this.isPhishing,
    required this.isMalware,
    required this.isDangerous,
    this.domainAge,
    this.countryCode,
  });
}

class SafeUrlScreen extends StatefulWidget {
  const SafeUrlScreen({super.key});

  @override
  State<SafeUrlScreen> createState() => _SafeUrlScreenState();
}

class _SafeUrlScreenState extends State<SafeUrlScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  ScanResult? _result;

  final String _apiKey = 'HRDlBBQfz6gdUn4yu8QlA1UzIyF2Yaxt';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String url) {
    if (url.trim().isEmpty) return "URL manzilini kiriting";
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return "To'g'ri URL kiriting (https://...)";
    if (!['http', 'https'].contains(uri.scheme)) return "Faqat http/https qo'llab-quvvatlanadi";
    return null;
  }

  Future<void> _scanUrl() async {
    final rawUrl = _urlController.text.trim();
    final validationError = _validateUrl(rawUrl);

    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final encodedUrl = Uri.encodeComponent(rawUrl);
      final apiUrl = Uri.parse('https://www.ipqualityscore.com/api/json/url/$_apiKey/$encodedUrl');

      final response = await http.get(apiUrl).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final riskScore = (data['risk_score'] ?? 0) as int;
          final isPhishing = (data['phishing'] ?? false) as bool;
          final isMalware = (data['malware'] ?? false) as bool;
          final isDangerous = riskScore >= 75 || isPhishing || isMalware;

          setState(() {
            _result = ScanResult(
              url: rawUrl,
              riskScore: riskScore,
              isPhishing: isPhishing,
              isMalware: isMalware,
              isDangerous: isDangerous,
              domainAge: data['domain_age']?['human'],
              countryCode: data['country_code'],
            );
          });
        } else {
          setState(() => _error = data['message'] ?? 'Tekshirishda xatolik yuz berdi');
        }
      } else {
        setState(() => _error = 'Server bilan aloqa bog\'lanmadi');
      }
    } catch (e) {
      setState(() => _error = 'Tarmoq xatosi. Internet aloqasini tekshiring');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'URL Tekshiruvchi',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const HugeIcon(icon: HugeIcons.strokeRoundedLink01, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text(
              'URL manzilini kiriting',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Havola xavfsiz yoki phishing ekanligini aniqlang',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              style: const TextStyle(color: AppColors.textPrimary),
              onSubmitted: (_) => _scanUrl(),
              decoration: InputDecoration(
                hintText: 'https://...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: HugeIcon(icon: HugeIcons.strokeRoundedLink01, color: AppColors.textDisabled, size: 20),
                ),
                suffixIcon: _urlController.text.isNotEmpty
                    ? IconButton(
                        icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.textDisabled, size: 20),
                        onPressed: () => setState(() => _urlController.clear()),
                      )
                    : null,
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _scanUrl,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text('Tekshirilmoqda...'),
                      ],
                    )
                  : const Text('TEKSHIRISH'),
            ),
            const SizedBox(height: 24),
            if (_result != null) _buildResultCard(_result!),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ScanResult res) {
    final color = res.isDangerous ? AppColors.danger : AppColors.safe;
    final bg = res.isDangerous ? AppColors.dangerLight : AppColors.safeLight;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: res.isDangerous ? HugeIcons.strokeRoundedShield01 : HugeIcons.strokeRoundedShield01,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.isDangerous ? 'Bu havola xavfli bo\'lishi mumkin' : 'XAVFSIZ URL',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      res.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Risk skori:', style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppColors.textSecondary)),
              Text('${res.riskScore} / 100', style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: res.riskScore / 100,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          if (res.isPhishing) _buildDetailRow(HugeIcons.strokeRoundedShield01, 'Phishing tuzog\'i aniqlandi', AppColors.danger),
          if (res.isMalware) _buildDetailRow(HugeIcons.strokeRoundedBug01, 'Zararli virus/malware mavjud', AppColors.danger),
          if (!res.isDangerous) _buildDetailRow(HugeIcons.strokeRoundedShield01, 'Phishing yoki malware belgisi topilmadi', AppColors.safe),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(res.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedGlobe02, color: Colors.white, size: 20),
            label: const Text('Brauzerda ochish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(List<List<dynamic>> icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
