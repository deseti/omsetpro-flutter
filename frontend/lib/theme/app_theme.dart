import 'package:flutter/material.dart';

class AppTheme {
  // Material 3 Color Scheme
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4F46E5), // Indigo-600
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE0E7FF), // Indigo-100
    onPrimaryContainer: Color(0xFF1E1B4B), // Indigo-900
    secondary: Color(0xFF059669), // Emerald-600
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD1FAE5), // Emerald-100
    onSecondaryContainer: Color(0xFF064E3B), // Emerald-900
    tertiary: Color(0xFFDC2626), // Red-600
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFEE2E2), // Red-100
    onTertiaryContainer: Color(0xFF7F1D1D), // Red-900
    error: Color(0xFFDC2626),
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    outline: Color(0xFFD1D5DB), // Gray-300
    outlineVariant: Color(0xFFF3F4F6), // Gray-100
    surface: Colors.white,
    onSurface: Color(0xFF111827), // Gray-900
    surfaceContainerHighest: Color(0xFFF9FAFB), // Gray-50
    onSurfaceVariant: Color(0xFF6B7280), // Gray-500
    inverseSurface: Color(0xFF111827),
    onInverseSurface: Colors.white,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF818CF8), // Indigo-400
    onPrimary: Color(0xFF1E1B4B),
    primaryContainer: Color(0xFF3730A3), // Indigo-700
    onPrimaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFF34D399), // Emerald-400
    onSecondary: Color(0xFF064E3B),
    secondaryContainer: Color(0xFF047857), // Emerald-700
    onSecondaryContainer: Color(0xFFD1FAE5),
    tertiary: Color(0xFFF87171), // Red-400
    onTertiary: Color(0xFF7F1D1D),
    tertiaryContainer: Color(0xFFB91C1C), // Red-700
    onTertiaryContainer: Color(0xFFFEE2E2),
    error: Color(0xFFF87171),
    onError: Color(0xFF7F1D1D),
    errorContainer: Color(0xFFB91C1C),
    onErrorContainer: Color(0xFFFEE2E2),
    outline: Color(0xFF4B5563), // Gray-600
    outlineVariant: Color(0xFF374151), // Gray-700
    surface: Color(0xFF111827), // Gray-900
    onSurface: Color(0xFFF9FAFB),
    surfaceContainerHighest: Color(0xFF1F2937), // Gray-800
    onSurfaceVariant: Color(0xFF9CA3AF), // Gray-400
    inverseSurface: Color(0xFFF9FAFB),
    onInverseSurface: Color(0xFF111827),
  );

  // Spacing Constants
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double space2XL = 48.0;
  static const double space3XL = 64.0;

  // Border Radius Constants
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;

  // Elevation Constants
  static const double elevationXS = 1.0;
  static const double elevationSM = 2.0;
  static const double elevationMD = 4.0;
  static const double elevationLG = 8.0;
  static const double elevationXL = 12.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      fontFamily: 'Poppins',

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: _lightColorScheme.surface,
        foregroundColor: _lightColorScheme.onSurface,
        elevation: elevationXS,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _lightColorScheme.onSurface,
          fontFamily: 'Poppins',
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: elevationSM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevationSM,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSM),
          ),
        ),
      ),

      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSM),
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLG,
            vertical: spaceMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSM),
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMD,
            vertical: spaceSM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSM),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightColorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: BorderSide(color: _lightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: BorderSide(color: _lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: BorderSide(color: _lightColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: BorderSide(color: _lightColorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMD,
          vertical: spaceMD,
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: elevationLG,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _lightColorScheme.onSurface,
          fontFamily: 'Poppins',
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: elevationLG,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLG),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: _lightColorScheme.outline,
        thickness: 1,
        space: spaceMD,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        elevation: elevationXS,
        pressElevation: elevationSM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      fontFamily: 'Poppins',

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: _darkColorScheme.onSurface,
        elevation: elevationXS,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _darkColorScheme.onSurface,
          fontFamily: 'Poppins',
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: elevationSM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),

      // Similar button themes and other components...
      // (Implementing the same structure as light theme but with dark colors)
    );
  }
}

// Responsive Breakpoints
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktop;
  }

  // Mobile-first responsive design
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 480;
  }

  static bool isMediumMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 480 && width < mobile;
  }

  static double getResponsiveValue(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    double? largeDesktop,
  }) {
    if (isLargeDesktop(context) && largeDesktop != null) {
      return largeDesktop;
    } else if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return mobile;
    }
  }
}

// Custom Extensions
extension ThemeExtension on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  bool get isMobile => ResponsiveBreakpoints.isMobile(this);
  bool get isTablet => ResponsiveBreakpoints.isTablet(this);
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(this);
}
