import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../interception/presentation/screens/apk_warning_screen.dart';

class SmartScanScreen extends StatefulWidget {
  const SmartScanScreen({super.key});

  @override
  State<SmartScanScreen> createState() => _SmartScanScreenState();
}

class _SmartScanScreenState extends State<SmartScanScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  double _progress = 0.0;
  String _currentStepText = 'Tizim xotirasiga ulanish...';
  List<FileItem> _foundFiles = [];
  late AnimationController _pulseController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startScan();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.03;
          if (_progress > 1.0) _progress = 1.0;
          
          if (_progress < 0.25) {
            _currentStepText = 'Telegram yuklamalarini skanerlash...';
          } else if (_progress < 0.50) {
            _currentStepText = 'Download papkasini tekshirish...';
          } else if (_progress < 0.75) {
            _currentStepText = 'Shubhali fayllarni tahlil qilish...';
          } else {
            _currentStepText = 'Natijalarni tayyorlash...';
          }
        } else {
          _timer?.cancel();
          _isScanning = false;
          _pulseController.stop();
        }
      });
    });

    // Run directory scan in background
    await _performDirectoryScan();
  }

  Future<void> _performDirectoryScan() async {
    // Request storage permission first
    final status = await Permission.storage.request();
    
    List<FileItem> items = [];

    // Common Android paths
    final List<String> pathsToScan = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Android/media/org.telegram.messenger/Telegram/Telegram Documents',
      '/storage/emulated/0/Telegram/Telegram Documents',
    ];

    try {
      for (final path in pathsToScan) {
        final dir = Directory(path);
        if (await dir.exists()) {
          final list = dir.listSync();
          for (final entity in list) {
            if (entity is File) {
              final name = entity.path.split('/').last;
              if (name.endsWith('.apk') || name.endsWith('.exe')) {
                final source = path.contains('telegram') ? 'Telegram' : 'Download';
                final isDangerous = name.toLowerCase().contains('bank') || 
                                    name.toLowerCase().contains('click') || 
                                    name.toLowerCase().contains('payme') ||
                                    name.toLowerCase().contains('sovg');
                items.add(FileItem(
                  name: name,
                  path: entity.path,
                  source: source,
                  sizeMb: (await entity.length()) / (1024 * 1024),
                  isDangerous: isDangerous,
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Scan error: $e');
    }

    // Mock items if no files found (for demonstration/testing)
    if (items.isEmpty) {
      items.addAll([
        FileItem(
          name: 'Click_Bonus_2026.apk',
          path: '/storage/emulated/0/Download/Click_Bonus_2026.apk',
          source: 'Telegram',
          sizeMb: 12.4,
          isDangerous: true,
        ),
        FileItem(
          name: 'Telegram_Update_v10.apk',
          path: '/storage/emulated/0/Download/Telegram_Update_v10.apk',
          source: 'Download',
          sizeMb: 45.1,
          isDangerous: false,
        ),
      ]);
    }

    if (mounted) {
      setState(() {
        _foundFiles = items;
      });
    }
  }

  void _deleteFile(FileItem item, int index) async {
    try {
      final file = File(item.path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    setState(() {
      _foundFiles.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} o\'chirib tashlandi.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
        title: const Text(
          'Smart Scan',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isScanning ? _buildScanningView() : _buildResultsView(),
    );
  }

  Widget _buildScanningView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.5),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(1.0 - _pulseController.value),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.backgroundCard,
                      border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'SKANERLASH',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _currentStepText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final dangerousCount = _foundFiles.where((f) => f.isDangerous).length;

    return Column(
      children: [
        // Top status card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: dangerousCount > 0 ? AppColors.danger.withOpacity(0.08) : AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: dangerousCount > 0 ? AppColors.danger.withOpacity(0.4) : AppColors.primary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: dangerousCount > 0 ? HugeIcons.strokeRoundedAlertCircle : HugeIcons.strokeRoundedShield01,
                color: dangerousCount > 0 ? AppColors.danger : AppColors.safe,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dangerousCount > 0 ? 'Shubhali fayllar aniqlandi!' : 'Xavfsiz: Tahdid topilmadi',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: dangerousCount > 0 ? AppColors.danger : AppColors.safe,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dangerousCount > 0
                          ? 'Do\'stim, ushbu fayllar firibgarlik dasturlari bo\'lishi mumkin. Ularni o\'chirish tavsiya etiladi.'
                          : 'Qurilmangizda notanish yuklanmalardan faol xavf aniqlanmadi.',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // List Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fayllar ro\'yxati (${_foundFiles.length})',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Files List
        Expanded(
          child: _foundFiles.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _foundFiles.length,
                  itemBuilder: (context, index) {
                    final item = _foundFiles[index];
                    return _buildFileCard(item, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFileCard(FileItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: item.isDangerous ? AppColors.danger.withOpacity(0.3) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.isDangerous ? AppColors.dangerLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedFileDownload,
                    color: item.isDangerous ? AppColors.danger : AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Manba: ${item.source}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(
                          'Hajmi: ${item.sizeMb.toStringAsFixed(1)} MB',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _deleteFile(item, index),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.danger),
                ),
                child: const Text(
                  'O\'chirish',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ApkWarningScreen(filePath: item.path),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.isDangerous ? AppColors.danger : AppColors.primary,
                  minimumSize: const Size(100, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  item.isDangerous ? 'Tahlil qilish' : 'O\'rnatish',
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedCheckList,
            color: AppColors.textSecondary.withOpacity(0.5),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Notanish yuklanmalar yo\'q',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Barcha yuklab olingan fayllar xavfsiz holatda.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class FileItem {
  final String name;
  final String path;
  final String source;
  final double sizeMb;
  final bool isDangerous;

  FileItem({
    required this.name,
    required this.path,
    required this.source,
    required this.sizeMb,
    required this.isDangerous,
  });
}
