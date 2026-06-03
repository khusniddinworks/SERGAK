import 'package:flutter/material.dart';

class AppColors {
  // Yangi "Toza" fon - Oq va ochiq kulrang
  static const Color background = Color(0xFFF8F9FA); 
  static const Color cardBackground = Colors.white;
  
  // Asosiy Xavfsizlik Ranglari
  static const Color primary = Color(0xFF00C853); // Vibrant Green
  static const Color primaryDark = Color(0xFF00A944);
  static const Color accent = Color(0xFF00E676);
  
  // Holat ranglari
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF2196F3);

  // Text ranglari
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textWhite = Colors.white;
  
  // Gradientlar
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00E676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF009624)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
