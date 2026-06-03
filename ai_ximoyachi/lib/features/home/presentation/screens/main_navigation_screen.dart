import 'package:flutter/material.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../features_hub/presentation/screens/features_screen.dart'; // 3 ta nuqta qo'shildi
import '../../../ai_chat/presentation/screens/ai_chat_screen.dart';       // 3 ta nuqta qo'shildi
import '../../../settings/presentation/screens/settings_screen.dart';      // 3 ta nuqta qo'shildi
import 'home_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  void initState() {
    super.initState();
    // Ilova to'liq ochilgach, yangilanishlarni tekshirish (1 soniya kutib, UI render bo'lishiga ruxsat beramiz)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        UpdateService().checkForUpdates(context);
      }
    });
  }

  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const FeaturesScreen(),
    const AiChatScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Bosh sahifa'),
          BottomNavigationBarItem(icon: Icon(Icons.shield_rounded), label: 'Himoya'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'AI Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Sozlamalar'),
        ],
      ),
    );
  }
}
