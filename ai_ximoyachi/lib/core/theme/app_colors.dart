import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === BACKGROUND ===
  static const Color background       = Color(0xFF0B0B0F); // Asosiy fon
  static const Color backgroundCard   = Color(0xFF17181D); // Karta foni
  static const Color backgroundInput  = Color(0xFF1E1F25); // Input foni
  static const Color backgroundChip   = Color(0xFF252630); // Chip, badge

  // === BORDER ===
  static const Color border           = Color(0xFF2A2B32); // Standart chegara
  static const Color borderFocus      = Color(0xFF00C8FF); // Faol input chegara

  // === PRIMARY (Cyan/Blue) ===
  static const Color primary          = Color(0xFF00C8FF); // Asosiy cyan
  static const Color primaryDark      = Color(0xFF0099CC); // To'q cyan
  static const Color primaryLight     = Color(0x1900C8FF); // Cyan fon chip (10% alpha)
  static const Color primarySurface   = Color(0x0F00C8FF); // Cyan surface (6% alpha)
  static const Color accent           = Color(0xFF00E5FF);

  // === SAFE (Xavfsiz yashil) ===
  static const Color safe             = Color(0xFF22C55E); // Yashil
  static const Color safeDark         = Color(0xFF16A34A); // To'q yashil
  static const Color safeLight        = Color(0x1922C55E); // Yashil chip
  static const Color safeSurface      = Color(0x0F22C55E); // Yashil surface

  // === PREMIUM (Purple & Gold) ===
  static const Color premium          = Color(0xFF8B5CF6); // Purple
  static const Color premiumDark      = Color(0xFF7C3AED); // To'q purple
  static const Color premiumLight     = Color(0x198B5CF6); // Purple chip
  static const Color premiumGold      = Color(0xFFD4A017); // Gold accent

  // === DANGER (Xavf qizil) ===
  static const Color danger           = Color(0xFFEF4444); // Xavfli qizil
  static const Color dangerDark       = Color(0xFFDC2626); // To'q qizil
  static const Color dangerLight      = Color(0x19EF4444); // Qizil chip
  static const Color error            = Color(0xFFEF4444);

  // === WARNING (Ogohlantirish) ===
  static const Color warning          = Color(0xFFF59E0B); // Sariq
  static const Color warningDark      = Color(0xFFD97706); // To'q sariq
  static const Color warningLight     = Color(0x19F59E0B); // Sariq chip

  // === INFO (Ma'lumot) ===
  static const Color info             = Color(0xFF00C8FF); // Primary bilan bir xil
  static const Color infoDark         = Color(0xFF0099CC);
  static const Color infoLight        = Color(0x1900C8FF);

  // === TEXT ===
  static const Color textPrimary      = Color(0xFFEEEEEE); // Asosiy oqish matn
  static const Color textSecondary    = Color(0xFF8B8D93); // Kulrang ikkinchi matn
  static const Color textDisabled     = Color(0xFF555555); // O'chirilgan
  static const Color textOnPrimary    = Color(0xFF0B0B0F); // Cyan ustidagi qora matn
  static const Color textOnDanger     = Color(0xFFFFFFFF); // Qizil ustidagi oq matn
  static const Color textWhite        = Colors.white;

  // === SHADOW ===
  static const Color shadow           = Color(0x1F000000); // Dark uchun mos shadow
  static const Color shadowMedium     = Color(0x3F000000);

  // === DIVIDER ===
  static const Color divider          = Color(0xFF2A2B32);

  // === SCORE COLORS ===
  static const Color scoreHigh        = Color(0xFF22C55E); // 80-100 (Safe)
  static const Color scoreMedium      = Color(0xFFF59E0B); // 50-79 (Warning)
  static const Color scoreLow         = Color(0xFFEF4444); // 0-49 (Danger)

  // === THREAT LEVEL ===
  static const Color threatHigh       = Color(0xFFEF4444);
  static const Color threatHighBg     = Color(0x19EF4444);
  static const Color threatMedium     = Color(0xFFF59E0B);
  static const Color threatMediumBg   = Color(0x19F59E0B);
  static const Color threatLow        = Color(0xFF22C55E);
  static const Color threatLowBg      = Color(0x1922C55E);

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00C8FF), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF00C8FF), Color(0xFF0099CC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
