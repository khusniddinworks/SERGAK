import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Outfit',
    colorScheme: const ColorScheme.dark(
      primary:        AppColors.primary,
      onPrimary:      AppColors.textOnPrimary,
      secondary:      AppColors.primaryDark,
      error:          AppColors.danger,
      surface:        AppColors.backgroundCard,
      onSurface:      AppColors.textPrimary,
      background:     AppColors.background,
      onBackground:   AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.background,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor:  AppColors.backgroundCard,
      foregroundColor:  AppColors.textPrimary,
      elevation:        0,
      centerTitle:      false,
      titleTextStyle: TextStyle(
        fontFamily:   'Outfit',
        fontSize:     20,
        fontWeight:   FontWeight.w600,
        color:        AppColors.textPrimary,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor:           Colors.transparent,
        statusBarIconBrightness:  Brightness.light,
      ),
    ),

    // Card
    cardTheme: CardTheme(
      color:        AppColors.backgroundCard,
      elevation:    0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:  AppColors.primary,
        foregroundColor:  AppColors.textOnPrimary,
        elevation:        0,
        minimumSize:      const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontFamily:   'Outfit',
          fontSize:     16,
          fontWeight:   FontWeight.w600,
        ),
      ),
    ),

    // OutlinedButton
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor:  AppColors.primary,
        side:             const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize:      const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontFamily:   'Outfit',
          fontSize:     16,
          fontWeight:   FontWeight.w600,
        ),
      ),
    ),

    // TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
          fontFamily:   'Outfit',
          fontSize:     14,
          fontWeight:   FontWeight.w500,
        ),
      ),
    ),

    // InputDecoration
    inputDecorationTheme: InputDecorationTheme(
      filled:       true,
      fillColor:    AppColors.backgroundInput,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:   BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:   const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:   const BorderSide(color: AppColors.borderFocus, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:   const BorderSide(color: AppColors.danger, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize:   14,
        color:      AppColors.textSecondary,
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color:      AppColors.divider,
      thickness:  1,
      space:      1,
    ),

    // BottomNavigationBar (Although we will use floating glassmorphism, let's keep it styled for compatibility)
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:      AppColors.backgroundCard,
      selectedItemColor:    AppColors.primary,
      unselectedItemColor:  AppColors.textSecondary,
      elevation:            0,
      type:                 BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily:   'Outfit',
        fontSize:     11,
        fontWeight:   FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize:   11,
      ),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor:   MaterialStateProperty.resolveWith((s) =>
          s.contains(MaterialState.selected) ? AppColors.primary : AppColors.textSecondary),
      trackColor:   MaterialStateProperty.resolveWith((s) =>
          s.contains(MaterialState.selected) ? AppColors.primaryLight : AppColors.border),
    ),

    // ListTile
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      minLeadingWidth: 0,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor:  AppColors.backgroundCard,
      contentTextStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize:   14,
        color:      AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
      behavior: SnackBarBehavior.floating,
    ),

    // ProgressIndicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color:            AppColors.primary,
      linearTrackColor: AppColors.primaryLight,
    ),
  );
}
