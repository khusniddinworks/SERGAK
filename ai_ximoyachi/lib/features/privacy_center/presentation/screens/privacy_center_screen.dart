import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';

class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> with WidgetsBindingObserver {
  bool _smsGranted = false;
  bool _phoneGranted = false;
  bool _storageGranted = false;
  bool _cameraGranted = false;
  bool _notifGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final sms = await Permission.sms.isGranted;
    final phone = await Permission.phone.isGranted;
    final storage = await Permission.storage.isGranted;
    final camera = await Permission.camera.isGranted;
    final notif = await Permission.notification.isGranted;

    if (mounted) {
      setState(() {
        _smsGranted = sms;
        _phoneGranted = phone;
        _storageGranted = storage;
        _cameraGranted = camera;
        _notifGranted = notif;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
        title: Text(
          'Privacy Center',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroCard(),
            const SizedBox(height: 24),
            Text(
              'Xavfsizlik Ruxsatnomalari',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              icon: HugeIcons.strokeRoundedMessageLock01,
              title: 'SMS Himoyasi',
              description: 'Kiruvchi shubhali xabarlar va firibgarlik havolalarini avtomatik aniqlash uchun.',
              isGranted: _smsGranted,
              permission: Permission.sms,
            ),
            _buildPermissionItem(
              icon: HugeIcons.strokeRoundedCall,
              title: 'Qo\'ng\'iroqlar Himoyasi',
              description: 'Firibgarlar qo\'ng\'iroq qilganda proaktiv ogohlantirish berish uchun.',
              isGranted: _phoneGranted,
              permission: Permission.phone,
            ),
            _buildPermissionItem(
              icon: HugeIcons.strokeRoundedSquareLock02,
              title: 'Maxfiy Seyf (Storage)',
              description: 'Surat, video va hujjatlarni AES-256 algoritmi orqali shifrlab saqlash uchun.',
              isGranted: _storageGranted,
              permission: Permission.storage,
            ),
            _buildPermissionItem(
              icon: HugeIcons.strokeRoundedQrCode,
              title: 'Kamera Skaneri',
              description: 'Xavfsiz QR-kodlarni va havolalarni kamera orqali skanerlash uchun.',
              isGranted: _cameraGranted,
              permission: Permission.camera,
            ),
            _buildPermissionItem(
              icon: HugeIcons.strokeRoundedNotification03,
              title: 'Ogohlantirishlar',
              description: 'Kiberxavfsizlik tahdidlari va shoshilinch xabarlarni yuborish uchun.',
              isGranted: _notifGranted,
              permission: Permission.notification,
            ),
            const SizedBox(height: 24),
            _buildSettingsActionCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedShieldUser,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maxfiylik va Xavfsizlik Kafolati',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'SERGAK 100% oflayn rejimda ishlaydi. Siz ruxsat bergan hech bir shaxsiy ma\'lumot yoki SMS xabarnomalar internetga yuborilmaydi va serverlarda saqlanmaydi.',
                  style: GoogleFonts.outfit(
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
    );
  }

  Widget _buildPermissionItem({
    required List<List<dynamic>> icon,
    required String title,
    required String description,
    required bool isGranted,
    required Permission permission,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isGranted ? AppColors.safeLight : AppColors.backgroundInput,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: icon,
                        color: isGranted ? AppColors.safe : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: isGranted,
                activeColor: AppColors.primary,
                onChanged: (value) async {
                  if (value) {
                    final status = await permission.request();
                    if (status.isGranted) {
                      _checkPermissions();
                    }
                  } else {
                    await openAppSettings();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'Qurilma sozlamalarini boshqarish',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ilova ruxsatnomalarini butunlay o\'chirish yoki qayta sozlash uchun tizim sozlamalariga o\'ting.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => openAppSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.backgroundInput,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Tizim Sozlamalariga O\'tish'),
          ),
        ],
      ),
    );
  }
}
