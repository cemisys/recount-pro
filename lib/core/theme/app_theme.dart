import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Colores principales - Degradado Indigo a Teal
  static const Color primaryColor = Color(0xFF3F51B5); // Índigo
  static const Color primaryVariant = Color(0xFF303F9F);
  static const Color secondaryColor = Color(0xFF009688); // Teal
  static const Color secondaryVariant = Color(0xFF00695C);

  // Colores adicionales del degradado
  static const Color gradientStart = Color(0xFF3F51B5); // Indigo 500
  static const Color gradientMiddle = Color(0xFF26A69A); // Teal 400
  static const Color gradientEnd = Color(0xFF009688); // Teal 500

  // Colores de acento para el degradado
  static const Color accentLight = Color(0xFF5C6BC0); // Indigo 400
  static const Color accentDark = Color(0xFF004D40); // Teal 900

  // Colores de superficie - Light Theme
  static const Color backgroundColorLight = Color(0xFFF5F5F5);
  static const Color surfaceColorLight = Colors.white;
  static const Color cardColorLight = Colors.white;

  // Colores de superficie - Dark Theme
  static const Color backgroundColorDark = Color(0xFF121212);
  static const Color surfaceColorDark = Color(0xFF1E1E1E);
  static const Color cardColorDark = Color(0xFF2D2D2D);

  // Colores de estado
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color errorColorDark = Color(0xFFCF6679);
  static const Color successColor = Color(0xFF38A169);
  static const Color successColorDark = Color(0xFF81C784);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color warningColorDark = Color(0xFFFFB74D);
  static const Color infoColor = Color(0xFF2196F3);
  static const Color infoColorDark = Color(0xFF64B5F6);

  // Colores de texto
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        secondary: secondaryColor,
        surface: backgroundColorLight,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColorLight,
      cardColor: cardColorLight,

      // System UI - AppBar con degradado
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Usar color primario como fallback
          foregroundColor: Colors.white,
          shadowColor: gradientStart.withValues(alpha: 0.3),
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimaryLight,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryLight,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondaryLight,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textPrimaryLight,
        size: 24,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        secondary: secondaryColor,
        surface: backgroundColorDark,
        error: errorColorDark,
      ),
      scaffoldBackgroundColor: backgroundColorDark,
      cardColor: cardColorDark,

      // System UI
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColorDark,
        foregroundColor: textPrimaryDark,
        elevation: 2,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: textSecondaryDark.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: textSecondaryDark.withValues(alpha: 0.3)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        fillColor: surfaceColorDark,
        filled: true,
      ),

      cardTheme: const CardThemeData(
        elevation: 2,
        color: cardColorDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimaryDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondaryDark,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textPrimaryDark,
        size: 24,
      ),
    );
  }

  // Degradados principales
  static LinearGradient get primaryGradient {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [gradientStart, gradientEnd],
      stops: [0.0, 1.0],
    );
  }

  static LinearGradient get primaryGradientVertical {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [gradientStart, gradientEnd],
      stops: [0.0, 1.0],
    );
  }

  static LinearGradient get primaryGradientHorizontal {
    return const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [gradientStart, gradientEnd],
      stops: [0.0, 1.0],
    );
  }

  static LinearGradient get primaryGradientWithMiddle {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [gradientStart, gradientMiddle, gradientEnd],
      stops: [0.0, 0.5, 1.0],
    );
  }

  static LinearGradient get backgroundGradient {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, secondaryColor],
    );
  }

  static LinearGradient get darkBackgroundGradient {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryVariant, secondaryVariant],
    );
  }

  static LinearGradient get subtleGradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        gradientStart.withValues(alpha: 0.1),
        gradientEnd.withValues(alpha: 0.1),
      ],
    );
  }

  // Métodos de utilidad para colores
  static Color getSuccessColor(bool isDark) => isDark ? successColorDark : successColor;
  static Color getErrorColor(bool isDark) => isDark ? errorColorDark : errorColor;
  static Color getWarningColor(bool isDark) => isDark ? warningColorDark : warningColor;
  static Color getInfoColor(bool isDark) => isDark ? infoColorDark : infoColor;
  static Color getTextPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimaryLight;
  static Color getTextSecondary(bool isDark) => isDark ? textSecondaryDark : textSecondaryLight;

  // Métodos helper para widgets con degradado
  static Widget gradientAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return Container(
      decoration: BoxDecoration(gradient: primaryGradient),
      child: AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
    );
  }

  static Widget gradientButton({
    required String text,
    required VoidCallback onPressed,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: primaryGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              text,
              style: textStyle ?? const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  static Widget gradientCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    bool subtle = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: subtle ? subtleGradient : primaryGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}