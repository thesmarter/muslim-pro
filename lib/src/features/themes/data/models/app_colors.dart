import 'package:flutter/material.dart';

/// مجموعة الألوان الجديدة للتطبيق
class AppColors {
  // الألوان الأساسية الموجودة
  static const Color defaultBlue = Color.fromARGB(255, 105, 187, 253);

  // ألوان جديدة إسلامية ومتناسقة
  static const Color islamicGreen = Color(0xFF2E7D32); // أخضر إسلامي
  static const Color goldenYellow = Color(0xFFFFB300); // ذهبي
  static const Color deepPurple = Color(0xFF512DA8); // بنفسجي عميق
  static const Color warmOrange = Color(0xFFFF6F00); // برتقالي دافئ
  static const Color royalBlue = Color(0xFF1565C0); // أزرق ملكي
  static const Color emeraldGreen = Color(0xFF00695C); // أخضر زمردي
  static const Color crimsonRed = Color(0xFFD32F2F); // أحمر قرمزي
  static const Color amberGold = Color(0xFFFF8F00); // كهرماني ذهبي
  static const Color indigoBlue = Color(0xFF303F9F); // نيلي
  static const Color forestGreen = Color(0xFF388E3C); // أخضر غابات
  static const Color burgundy = Color(0xFF8E24AA); // بورجوندي
  static const Color tealBlue = Color(0xFF00796B); // أزرق مخضر

  // ألوان متدرجة للخلفيات
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color darkCardBackground = Color(0xFF1E1E1E);

  // ألوان النصوص
  static const Color primaryText = Color(0xFF212121);
  static const Color secondaryText = Color(0xFF757575);
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFB0B0B0);

  // ألوان التأكيد والحالات
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  /// قائمة الألوان المتاحة للاختيار
  static const List<Color> availableColors = [
    defaultBlue,
    islamicGreen,
    goldenYellow,
    deepPurple,
    warmOrange,
    royalBlue,
    emeraldGreen,
    crimsonRed,
    amberGold,
    indigoBlue,
    forestGreen,
    burgundy,
    tealBlue,
  ];

  /// الحصول على اسم اللون
  static String getColorName(Color color) {
    if (color == defaultBlue) return 'الأزرق الافتراضي';
    if (color == islamicGreen) return 'الأخضر الإسلامي';
    if (color == goldenYellow) return 'الذهبي';
    if (color == deepPurple) return 'البنفسجي العميق';
    if (color == warmOrange) return 'البرتقالي الدافئ';
    if (color == royalBlue) return 'الأزرق الملكي';
    if (color == emeraldGreen) return 'الأخضر الزمردي';
    if (color == crimsonRed) return 'الأحمر القرمزي';
    if (color == amberGold) return 'الكهرماني الذهبي';
    if (color == indigoBlue) return 'النيلي';
    if (color == forestGreen) return 'أخضر الغابات';
    if (color == burgundy) return 'البورجوندي';
    if (color == tealBlue) return 'الأزرق المخضر';
    return 'لون مخصص';
  }

  /// إنشاء ColorScheme من لون أساسي
  static ColorScheme createColorScheme(Color seedColor, Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
  }

  /// ألوان متدرجة للبطاقات
  static List<Color> getGradientColors(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return [
      baseColor,
      hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor(),
    ];
  }
}
