import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../vault/presentation/screens/vault_screen.dart';
import '../../../permission_analyzer/presentation/screens/permission_screen.dart';
import '../../../payment/presentation/screens/premium_screen.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  String tr(String key) => AppTranslations.get(key, AppState().language);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('extra_features'), 
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      
                      _buildFeatureCard(
                        context,
                        tr('vault'), 
                        tr('vault_desc'), 
                        Icons.lock_rounded, 
                        Colors.purpleAccent, 
                        'AES-256',
                        VaultScreen()
                      ),
                      
                      _buildFeatureCard(
                        context,
                        tr('perm_analyzer'), 
                        tr('perm_desc'), 
                        Icons.settings_suggest_rounded, 
                        Colors.green, 
                        'Aqlli',
                        PermissionScreen()
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 40, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient, 
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))
      ),
      child: Column(children: [
        const Icon(Icons.shield_rounded, color: Colors.white, size: 50),
        const SizedBox(height: 10),

        Text('SERGAK', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
        const SizedBox(height: 4),
        Text(tr('device_protected'), style: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withOpacity(0.9))),
      ]),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String subtitle, IconData icon, Color color, String badge, Widget destinationScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12), 
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), 
              child: Icon(icon, color: Colors.white, size: 28)
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(subtitle, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.9))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), 
              child: Text(badge, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))
            ),
          ]),
        ),
        Container(
          width: double.infinity, 
          padding: const EdgeInsets.all(16), 
          child: ElevatedButton(
            onPressed: () {
              if (title == tr('vault') && !AppState().isPremium) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => destinationScreen));
              }
            }, 
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1), 
              foregroundColor: isDark ? Colors.white : AppColors.textPrimary, 
              elevation: 0, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ), 
            child: Text(tr('open'))
          )
        ),
      ]),
    );
  }
}
