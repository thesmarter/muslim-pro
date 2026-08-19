import 'package:flutter/material.dart';

class DawaaDesignSystem {
  DawaaDesignSystem._();

  static const Color primary = Color(0xFF00838F);
  static const Color primaryDark = Color(0xFF005662);
  static const Color accent = Color(0xFFFFAB40);
  static const Color surface = Color(0xFFF4FFFE);
  static const Color surfaceDark = Color(0xFF0F1B1D);
  static const Color onSurface = Color(0xFF1A2C2E);
  static const Color gray = Color(0xFF607D8B);
  static const Color white = Color(0xFFFFFFFF);

  static const String _fontFamily = 'Tajawal';

  static ThemeData lightTheme() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF00838F),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFB2EBF2),
      onPrimaryContainer: Color(0xFF001F24),
      secondary: Color(0xFFFFAB40),
      onSecondary: Color(0xFF1A1A1A),
      secondaryContainer: Color(0xFFFFF3E0),
      onSecondaryContainer: Color(0xFF3E2723),
      tertiary: Color(0xFF4DB6AC),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFE0F2F1),
      onTertiaryContainer: Color(0xFF003D38),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFF4FFFE),
      onSurface: Color(0xFF1A2C2E),
      onSurfaceVariant: Color(0xFF4F6364),
      outline: Color(0xFF73898A),
      outlineVariant: Color(0xFFC2CDD0),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2E3133),
      onInverseSurface: Color(0xFFEFF1F1),
      inversePrimary: Color(0xFF80DEEA),
      surfaceTint: Color(0xFF00838F),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF005662),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF005662)),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 1,
        shadowColor: primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: gray.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: gray.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: gray,
        indicatorColor: accent,
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary,
        unselectedItemColor: gray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF005662),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          color: Color(0xFF1A2C2E),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF005662),
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE0F7FA),
        selectedColor: primary,
        labelStyle: const TextStyle(fontFamily: _fontFamily),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: gray.withValues(alpha: 0.15),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData darkTheme() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF80DEEA),
      onPrimary: Color(0xFF00363D),
      primaryContainer: Color(0xFF004F58),
      onPrimaryContainer: Color(0xFFB2EBF2),
      secondary: Color(0xFFFFCC80),
      onSecondary: Color(0xFF3E2723),
      secondaryContainer: Color(0xFF5D4037),
      onSecondaryContainer: Color(0xFFFFF3E0),
      tertiary: Color(0xFF80CBC4),
      onTertiary: Color(0xFF003D38),
      tertiaryContainer: Color(0xFF004D46),
      onTertiaryContainer: Color(0xFFE0F2F1),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF0F1B1D),
      onSurface: Color(0xFFDDE4E5),
      onSurfaceVariant: Color(0xFFB1C4C5),
      outline: Color(0xFF7B9293),
      outlineVariant: Color(0xFF4F6364),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFDDE4E5),
      onInverseSurface: Color(0xFF2E3133),
      inversePrimary: Color(0xFF00838F),
      surfaceTint: Color(0xFF80DEEA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF80DEEA),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF80DEEA)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A2A2C),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF80DEEA),
          foregroundColor: const Color(0xFF00363D),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF80DEEA),
          side: const BorderSide(color: Color(0xFF80DEEA), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF80DEEA),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A2A2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3A5052)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3A5052)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF80DEEA), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF80DEEA),
        unselectedLabelColor: Color(0xFF7B9293),
        indicatorColor: Color(0xFFFFCC80),
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A2A2C),
        selectedItemColor: Color(0xFF80DEEA),
        unselectedItemColor: Color(0xFF7B9293),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFFFFCC80),
        foregroundColor: const Color(0xFF3E2723),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A2A2C),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF80DEEA),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          color: Color(0xFFDDE4E5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1A2A2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF80DEEA),
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: Color(0xFF00363D),
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1A3A3C),
        selectedColor: const Color(0xFF80DEEA),
        labelStyle: const TextStyle(fontFamily: _fontFamily),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
