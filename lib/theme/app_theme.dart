import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP COLORS — Ocean Aquarium Theme
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  static bool get isDark => AppTheme.isDark;

  // Ocean Base Backgrounds
  static Color get bg          => isDark ? const Color(0xFF090D16) : const Color(0xFFE8F4F8); // Very soft water white/blue / Premium dark
  static Color get surface     => isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF); // Pure white / Slate dark
  
  // Ocean Palette
  static Color get primary     => const Color(0xFF00838F); // Deep Aqua
  static Color get secondary   => const Color(0xFF00BCD4); // Turquoise
  static Color get accent      => const Color(0xFF26A69A); // Sea Green
  static Color get oceanDeep   => const Color(0xFF006064); // Dark Ocean Blue
  static Color get beigeAcc    => isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF3E0); // Soft sandy beige

  // Cards & Glass
  static Color get card        => isDark ? const Color(0xCC0F172A) : const Color(0xCCFFFFFF); // 80% white / dark slate for glass
  static Color get cardLight   => isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FAFC); // Very light cyan tint
  
  // Status
  static Color get success     => const Color(0xFF2E7D32); // Deep green
  static Color get successLight=> isDark ? const Color(0xFF1B5E20).withOpacity(0.2) : const Color(0xFFE8F5E9); 
  static Color get warning     => const Color(0xFFF57C00); // Amber
  static Color get warningLight=> isDark ? const Color(0xFFE65100).withOpacity(0.2) : const Color(0xFFFFF3E0); 
  static Color get danger      => const Color(0xFFE53935); // Coral Red
  static Color get dangerLight => isDark ? const Color(0xFFB71C1C).withOpacity(0.2) : const Color(0xFFFFEBEE); 
  static Color get info        => const Color(0xFF0288D1); 

  // Text
  static Color get textPrimary   => isDark ? Colors.white : const Color(0xFF004D40); // Very dark teal / White
  static Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF00796B); // Medium teal / Slate gray
  static Color get textMuted     => isDark ? const Color(0xFF64748B) : const Color(0xFF80CBC4); // Light teal/grey

  // Borders & Shadows
  static Color get border      => isDark ? const Color(0xFF1E293B) : const Color(0xFFB2EBF2); // Soft cyan border
  static Color get shadowBlue  => isDark ? const Color(0x1A000000) : const Color(0x1A00838F); // Soft aqua shadow
  static Color get divider     => isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F7FA);

  // Gradients
  static List<Color> get oceanGradient => [const Color(0xFF00BCD4), const Color(0xFF00838F)];
  static List<Color> get waveGradient  => [const Color(0xFF26A69A), const Color(0xFF00BCD4)];
  static List<Color> get sandGradient  => isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)];

  AppColors._();
}

// ─────────────────────────────────────────────────────────────────────────────
// APP THEME
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  static bool get isDark => themeNotifier.value == ThemeMode.dark;

  static void toggleTheme() {
    themeNotifier.value = themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.dark(
        brightness: Brightness.dark,
        primary:    AppColors.primary,
        secondary:  AppColors.secondary,
        surface:    AppColors.surface,
        error:      AppColors.danger,
        onPrimary:  Colors.white,
        onSecondary: Colors.white,
        onSurface:  AppColors.textPrimary,
        onError:    Colors.white,
      ),

      // Typography - Inter with softer coloring
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor:    AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.primary),
        actionsIconTheme: IconThemeData(color: AppColors.primary),
        surfaceTintColor: Colors.transparent,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 8,
        shadowColor: AppColors.shadowBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.border),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        elevation: 12,
        shadowColor: AppColors.shadowBlue,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        hintStyle:  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        prefixIconColor: AppColors.primary,
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface.withOpacity(0.9),
        indicatorColor: AppColors.secondary.withOpacity(0.15),
        elevation: 0,
        shadowColor: AppColors.shadowBlue,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: active ? AppColors.primary : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? AppColors.primary : AppColors.textMuted,
            size: 24,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        surfaceTintColor: Colors.transparent,
        height: 72,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 8,
        focusElevation: 12,
        hoverElevation: 12,
        splashColor: AppColors.primary,
        shape: StadiumBorder(),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardLight,
        side: BorderSide(color: AppColors.border),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.oceanDeep,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        elevation: 10,
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.secondary,
        circularTrackColor: AppColors.border,
      ),

      // Icon
      iconTheme: IconThemeData(color: AppColors.primary, size: 22),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.light(
        brightness: Brightness.light,
        primary:    AppColors.primary,
        secondary:  AppColors.secondary,
        surface:    AppColors.surface,
        error:      AppColors.danger,
        onPrimary:  Colors.white,
        onSecondary: Colors.white,
        onSurface:  AppColors.textPrimary,
        onError:    Colors.white,
      ),

      // Typography - Inter with softer coloring
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor:    AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.primary),
        actionsIconTheme: IconThemeData(color: AppColors.primary),
        surfaceTintColor: Colors.transparent,
      ),

      // Cards (Note: mostly using OceanGlassCard now)
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 8,
        shadowColor: AppColors.shadowBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.border),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        elevation: 12,
        shadowColor: AppColors.shadowBlue,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.danger),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        hintStyle:  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        prefixIconColor: AppColors.primary,
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface.withOpacity(0.9),
        indicatorColor: AppColors.secondary.withOpacity(0.15),
        elevation: 0,
        shadowColor: AppColors.shadowBlue,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: active ? AppColors.primary : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? AppColors.primary : AppColors.textMuted,
            size: 24,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        surfaceTintColor: Colors.transparent,
        height: 72,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 8,
        focusElevation: 12,
        hoverElevation: 12,
        splashColor: AppColors.primary,
        shape: StadiumBorder(),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardLight,
        side: BorderSide(color: AppColors.border),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.oceanDeep,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        elevation: 10,
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.secondary,
        circularTrackColor: AppColors.border,
      ),

      // Icon
      iconTheme: IconThemeData(color: AppColors.primary, size: 22),
    );
  }
}
