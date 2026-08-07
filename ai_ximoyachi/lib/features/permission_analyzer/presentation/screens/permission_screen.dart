import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/theme/app_colors.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  static const _appsCh = MethodChannel('com.aiximoyachi/app_analyzer');
  bool _isLoading = true;
  List<Map<String, dynamic>> _apps = [];
  String _filter = 'Hammasi';

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic>? result = await _appsCh.invokeListMethod('getInstalledApps');
      if (result != null && mounted) {
        setState(() {
          _apps = result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filteredApps = _apps.where((app) {
      if (_filter == 'Xavfli') return app['riskLevel'] == 'HIGH';
      if (_filter == 'O\'rta') return app['riskLevel'] == 'MEDIUM';
      if (_filter == 'Xavfsiz') return app['riskLevel'] == 'LOW';
      return true;
    }).toList();

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
          'Ilovalar tahlili',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh, color: AppColors.textPrimary, size: 22),
            onPressed: _loadApps,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Ilovalar tahlil qilinmoqda...',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredApps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildAppCard(filteredApps[i]),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final high = _apps.where((a) => a['riskLevel'] == 'HIGH').length;
    final medium = _apps.where((a) => a['riskLevel'] == 'MEDIUM').length;
    final low = _apps.where((a) => a['riskLevel'] == 'LOW').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('${_apps.length}', 'Jami ilova', AppColors.textPrimary),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildSummaryItem('$high', 'Xavfli', AppColors.danger),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildSummaryItem('$medium', 'O\'rta xavf', AppColors.warning),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildSummaryItem('$low', 'Xavfsiz', AppColors.safe),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Hammasi', 'Xavfli', 'O\'rta', 'Xavfsiz'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppCard(Map<String, dynamic> app) {
    final Uint8List? iconBytes = app['appIcon'] as Uint8List?;
    final risk = app['riskLevel'] as String;

    Color badgeColor = AppColors.safe;
    Color badgeBg = AppColors.safeLight;

    if (risk == 'HIGH') {
      badgeColor = AppColors.danger;
      badgeBg = AppColors.dangerLight;
    } else if (risk == 'MEDIUM') {
      badgeColor = AppColors.warning;
      badgeBg = AppColors.warningLight;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: iconBytes != null && iconBytes.isNotEmpty
                ? Image.memory(iconBytes, width: 44, height: 44)
                : Container(
                    width: 44,
                    height: 44,
                    color: AppColors.backgroundInput,
                    child: const Center(
                      child: HugeIcon(icon: HugeIcons.strokeRoundedFileDownload, color: AppColors.textDisabled),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        app['appName'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        risk,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${app['permCount']} ta xavfli ruxsatnoma',
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
    );
  }
}
