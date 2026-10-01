import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppColors {
  static const background = Color(0xFF101016);
  static const surface = Color(0xFF1C1B25);
  static const muted = Color(0xFF9A98AC);
  static const violet = Color(0xFFB7A0FF);
  static const line = Color(0xFF2C2A38);
}

ThemeData buildAppTheme({Brightness brightness = Brightness.dark}) {
  final dark = brightness == Brightness.dark;
  final scheme = dark
      ? const ColorScheme.dark(
          primary: AppColors.violet,
          onPrimary: Color(0xFF231441),
          surface: AppColors.surface,
          onSurface: Color(0xFFF5F3FB),
          onSurfaceVariant: AppColors.muted,
          secondary: Color(0xFFC4D9BE),
          outline: AppColors.line,
        )
      : const ColorScheme.light(
          primary: Color(0xFF6941B5),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFECE3FA),
          onPrimaryContainer: Color(0xFF402475),
          surface: Colors.white,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xFFF6F3FA),
          surfaceContainer: Color(0xFFF0EBF5),
          surfaceContainerHigh: Color(0xFFEAE4F0),
          surfaceContainerHighest: Color(0xFFE4DDEB),
          onSurface: Color(0xFF231E30),
          onSurfaceVariant: Color(0xFF696274),
          secondary: Color(0xFF476942),
          secondaryContainer: Color(0xFFECE3FA),
          onSecondaryContainer: Color(0xFF402475),
          outline: Color(0xFF857B92),
          outlineVariant: Color(0xFFE1DCE9),
          inverseSurface: Color(0xFF2E263A),
          onInverseSurface: Color(0xFFF7F3FC),
          inversePrimary: AppColors.violet,
        );
  final background = dark ? AppColors.background : const Color(0xFFF6F3FA);
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: background,
    colorScheme: scheme,
  );
  final theme = base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    textTheme: base.textTheme.copyWith(
      headlineLarge: const TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.7,
        height: 1.15,
      ),
      headlineMedium: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: scheme.surface,
      selectedColor: scheme.primary,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
  if (dark) return theme;

  return theme.copyWith(
    textTheme: theme.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
    ),
    listTileTheme: ListTileThemeData(
      textColor: scheme.onSurface,
      iconColor: scheme.onSurfaceVariant,
    ),
    navigationBarTheme: NavigationBarThemeData(
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    chipTheme: theme.chipTheme.copyWith(
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.onSurfaceVariant,
      ),
    ),
  );
}
