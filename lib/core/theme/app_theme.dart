import 'package:flutter/material.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.navy,
    required this.navyDeep,
    required this.navyMid,
    required this.silverBlue,
    required this.silverGlow,
    required this.silverFrost,
    required this.donation,
    required this.onDonation,
    required this.donationContainer,
    required this.warning,
    required this.warningContainer,
    required this.border,
    required this.subtleSurface,
    required this.textMuted,
  });

  final Color navy;
  final Color navyDeep;
  final Color navyMid;
  final Color silverBlue;
  final Color silverGlow;
  final Color silverFrost;
  final Color donation;
  final Color onDonation;
  final Color donationContainer;
  final Color warning;
  final Color warningContainer;
  final Color border;
  final Color subtleSurface;
  final Color textMuted;

  Color get itsBlue => navy;

  static const AppSemanticColors light = AppSemanticColors(
    navy: Color(0xFF0B2245),
    navyDeep: Color(0xFF07162E),
    navyMid: Color(0xFF173E73),
    silverBlue: Color(0xFF4F83BE),
    silverGlow: Color(0xFF9AC3EE),
    silverFrost: Color(0xFFE8F1FB),
    donation: Color(0xFF15803D),
    onDonation: Color(0xFFFFFFFF),
    donationContainer: Color(0xFFDCFCE7),
    warning: Color(0xFFB45309),
    warningContainer: Color(0xFFFEF3C7),
    border: Color(0xFFDCE5F2),
    subtleSurface: Color(0xFFEEF3FA),
    textMuted: Color(0xFF5A6B84),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    navy: Color(0xFF8AB8E8),
    navyDeep: Color(0xFF060E1C),
    navyMid: Color(0xFF142B50),
    silverBlue: Color(0xFF7FAEE2),
    silverGlow: Color(0xFFB8D8F8),
    silverFrost: Color(0xFF162A4A),
    donation: Color(0xFF4ADE80),
    onDonation: Color(0xFF052E16),
    donationContainer: Color(0xFF123724),
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF3F2A0C),
    border: Color(0xFF213654),
    subtleSurface: Color(0xFF15253E),
    textMuted: Color(0xFF95AAC6),
  );

  static AppSemanticColors of(BuildContext context) {
    return Theme.of(context).extension<AppSemanticColors>() ?? light;
  }

  @override
  AppSemanticColors copyWith({
    Color? navy,
    Color? navyDeep,
    Color? navyMid,
    Color? silverBlue,
    Color? silverGlow,
    Color? silverFrost,
    Color? donation,
    Color? onDonation,
    Color? donationContainer,
    Color? warning,
    Color? warningContainer,
    Color? border,
    Color? subtleSurface,
    Color? textMuted,
  }) {
    return AppSemanticColors(
      navy: navy ?? this.navy,
      navyDeep: navyDeep ?? this.navyDeep,
      navyMid: navyMid ?? this.navyMid,
      silverBlue: silverBlue ?? this.silverBlue,
      silverGlow: silverGlow ?? this.silverGlow,
      silverFrost: silverFrost ?? this.silverFrost,
      donation: donation ?? this.donation,
      onDonation: onDonation ?? this.onDonation,
      donationContainer: donationContainer ?? this.donationContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      border: border ?? this.border,
      subtleSurface: subtleSurface ?? this.subtleSurface,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      navy: Color.lerp(navy, other.navy, t) ?? navy,
      navyDeep: Color.lerp(navyDeep, other.navyDeep, t) ?? navyDeep,
      navyMid: Color.lerp(navyMid, other.navyMid, t) ?? navyMid,
      silverBlue: Color.lerp(silverBlue, other.silverBlue, t) ?? silverBlue,
      silverGlow: Color.lerp(silverGlow, other.silverGlow, t) ?? silverGlow,
      silverFrost: Color.lerp(silverFrost, other.silverFrost, t) ?? silverFrost,
      donation: Color.lerp(donation, other.donation, t) ?? donation,
      onDonation: Color.lerp(onDonation, other.onDonation, t) ?? onDonation,
      donationContainer:
          Color.lerp(donationContainer, other.donationContainer, t) ??
          donationContainer,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
          warningContainer,
      border: Color.lerp(border, other.border, t) ?? border,
      subtleSurface:
          Color.lerp(subtleSurface, other.subtleSurface, t) ?? subtleSurface,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static const String displayFont = 'Poppins';
  static const String bodyFont = 'Inter';

  static ThemeData get light => _build(
    brightness: Brightness.light,
    semantic: AppSemanticColors.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0B2245),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE8F1FB),
      onPrimaryContainer: Color(0xFF0B2245),
      secondary: Color(0xFF4F83BE),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFDCFCE7),
      onSecondaryContainer: Color(0xFF052E16),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0F1D36),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF4F7FC),
      surfaceContainer: Color(0xFFEEF3FA),
      surfaceContainerHigh: Color(0xFFE2EBF6),
      outline: Color(0xFFC8D5E6),
      outlineVariant: Color(0xFFDCE5F2),
      error: Color(0xFFDC2626),
      onError: Color(0xFFFFFFFF),
    ),
    scaffoldBg: const Color(0xFFF4F7FC),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    semantic: AppSemanticColors.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8AB8E8),
      onPrimary: Color(0xFF07162E),
      primaryContainer: Color(0xFF162A4A),
      onPrimaryContainer: Color(0xFFDCEBFF),
      secondary: Color(0xFF4ADE80),
      onSecondary: Color(0xFF052E16),
      secondaryContainer: Color(0xFF123724),
      onSecondaryContainer: Color(0xFFDCFCE7),
      surface: Color(0xFF0F1D33),
      onSurface: Color(0xFFF1F5FA),
      surfaceContainerLowest: Color(0xFF081120),
      surfaceContainerLow: Color(0xFF0D192D),
      surfaceContainer: Color(0xFF15253E),
      surfaceContainerHigh: Color(0xFF1E3354),
      outline: Color(0xFF395073),
      outlineVariant: Color(0xFF213654),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
    ),
    scaffoldBg: const Color(0xFF081120),
  );

  static TextTheme _textTheme(
    Color onSurface,
    Color muted, {
    required bool isDark,
  }) {
    final bodyTrack = isDark ? 0.1 : 0.0;
    final bodyHeight = isDark ? 1.54 : 1.48;

    return TextTheme(
      displaySmall: TextStyle(
        fontFamily: displayFont,
        fontSize: 25,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.6,
        height: 1.22,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFont,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.22,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.35,
        height: 1.26,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: displayFont,
        fontSize: 17.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.28,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: displayFont,
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.32,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        letterSpacing: bodyTrack,
        height: 1.34,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: bodyTrack,
        height: bodyHeight,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: bodyTrack,
        height: bodyHeight,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        letterSpacing: bodyTrack,
        height: 1.44,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      labelSmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required AppSemanticColors semantic,
    required ColorScheme colorScheme,
    required Color scaffoldBg,
  }) {
    final radius = BorderRadius.circular(14);
    final isDark = brightness == Brightness.dark;
    final textTheme = _textTheme(
      colorScheme.onSurface,
      semantic.textMuted,
      isDark: isDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: bodyFont,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      extensions: [semantic],
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: displayFont,
          fontSize: 16.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: semantic.border, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: const Color(0xFF07162E).withValues(alpha: 0.52),
        dragHandleColor: semantic.border,
        dragHandleSize: const Size(44, 4.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        hintStyle: TextStyle(
          fontFamily: bodyFont,
          fontSize: 14,
          color: semantic.textMuted.withValues(alpha: 0.8),
        ),
        labelStyle: TextStyle(
          fontFamily: bodyFont,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: semantic.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: semantic.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: semantic.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(
            fontFamily: bodyFont,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          side: BorderSide(color: semantic.border, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(
            fontFamily: bodyFont,
            fontWeight: FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontFamily: bodyFont,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary,
        checkmarkColor: colorScheme.onPrimary,
        labelStyle: TextStyle(
          fontFamily: bodyFont,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: bodyFont,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: semantic.border),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF1E3354)
            : const Color(0xFF0B2245),
        contentTextStyle: const TextStyle(
          fontFamily: bodyFont,
          color: Colors.white,
          fontSize: 13.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: semantic.border, thickness: 1),
    );
  }
}
