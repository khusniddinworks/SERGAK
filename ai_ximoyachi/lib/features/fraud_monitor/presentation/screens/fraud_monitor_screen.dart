import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neon_widgets.dart';
import 'package:flutter/services.dart';

class FraudMonitorScreen extends StatefulWidget {
  const FraudMonitorScreen({super.key});

  @override
  State<FraudMonitorScreen> createState() => _FraudMonitorScreenState();
}

class _FraudMonitorScreenState extends State<FraudMonitorScreen> {
  static const platform = MethodChannel('com.aiximoyachi/fraud_monitor');
  bool _isMonitoringEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final bool hasPermissions = await platform.invokeMethod('checkPermissions');
      setState(() {
        _isMonitoringEnabled = hasPermissions;
      });
    } on PlatformException catch (e) {
      print("Failed to check permissions: '${e.message}'.");
    }
  }

  Future<void> _toggleMonitoring(bool enable) async {
    try {
      if (enable) {
        final bool result = await platform.invokeMethod('startFraudMonitor');
        setState(() {
          _isMonitoringEnabled = result; // True bo'lsa yongan, false bo'lsa ruxsat kutilmoqda
        });
      } else {
        await platform.invokeMethod('stopFraudMonitor');
        setState(() {
          _isMonitoringEnabled = false;
        });
      }
    } on PlatformException catch (e) {
      print("Failed to toggle service: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Fraud Monitor"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 30),
            const Text(
              "So'nggi hodisalar",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildLogList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return GlowCard(
      glowColor: _isMonitoringEnabled ? AppColors.accent : AppColors.error,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _isMonitoringEnabled ? Icons.security_rounded : Icons.warning_amber_rounded,
                    color: _isMonitoringEnabled ? AppColors.accent : AppColors.error,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isMonitoringEnabled ? "Monitoring Faol" : "Monitoring O'chirilgan",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _isMonitoringEnabled,
                activeColor: AppColors.accent,
                onChanged: _toggleMonitoring,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Ilova qo'ng'iroq vaqtida kelgan SMS kodlarni real-vaqtda tahlil qiladi va firibgarlik aniqlansa sizni ogohlantiradi.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    final List<Map<String, dynamic>> logs = [
      {
        'date': 'Bugun, 14:20',
        'type': 'SMS Fraud',
        'desc': 'Bank kodini so\'rash urinishi aniqlandi',
        'danger': true,
      },
      {
        'date': 'Kecha, 09:15',
        'type': 'Safe Call',
        'desc': 'Oddiy qo\'ng\'iroq tahlil qilindi',
        'danger': false,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (log['danger'] ? AppColors.error : AppColors.accent).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  log['danger'] ? Icons.gpp_bad_rounded : Icons.verified_user_rounded,
                  color: log['danger'] ? AppColors.error : AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          log['type'],
                          style: TextStyle(
                            color: log['danger'] ? AppColors.error : AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          log['date'],
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log['desc'],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
