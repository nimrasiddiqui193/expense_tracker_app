import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Premium emerald fintech palette.
  static const Color primaryColor = Color(0xFF087F5B);
  static const Color primaryDark = Color(0xFF056449);
  static const Color accentColor = Color(0xFF43D9A3);

  static const Color lightBackground = Color(0xFFF4F7F5);
  static const Color darkBackground = Color(0xFF0A100E);

  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF151F1B);

  static const Color lightText = Color(0xFF172B25);
  static const Color darkText = Color(0xFFF1F7F4);

  static const Color incomeColor = Color(0xFF159B70);
  static const Color expenseColor = Color(0xFFE05D5D);
  static const Color mutedColor = Color(0xFF89958F);

  static BorderRadius get cardRadius => BorderRadius.circular(24);
  static BorderRadius get buttonRadius => BorderRadius.circular(16);

  static ThemeData get lightTheme {
    const secondaryText = Color(0xFF718078);
    const borderColor = Color(0xFFE8EFEB);
    const fieldColor = Color(0xFFF0F4F1);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: accentColor,
      surface: lightSurface,
      error: expenseColor,
    );

    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    ).apply(bodyColor: lightText, displayColor: lightText);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      textTheme: textTheme,
      dividerColor: borderColor,
      splashColor: primaryColor.withValues(alpha: 0.07),
      highlightColor: primaryColor.withValues(alpha: 0.03),
      visualDensity: VisualDensity.standard,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: lightText,
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        iconTheme: const IconThemeData(color: lightText, size: 23),
      ),

      cardTheme: CardThemeData(
        color: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0xFF183D2D).withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: const BorderSide(color: borderColor, width: 0.6),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        hintStyle: GoogleFonts.inter(color: mutedColor, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: secondaryText, fontSize: 14),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: primaryColor, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: expenseColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: expenseColor, width: 1.4),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFB9CBC2);
            }
            if (states.contains(WidgetState.pressed)) {
              return primaryDark;
            }
            return primaryColor;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 54)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) return 1;
            return 3;
          }),
          shadowColor: WidgetStateProperty.all(
            primaryDark.withValues(alpha: 0.25),
          ),
          animationDuration: const Duration(milliseconds: 180),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: buttonRadius),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: primaryDark.withValues(alpha: 0.25),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          animationDuration: const Duration(milliseconds: 180),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: Color(0xFFDCE7E0)),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 7,
        focusElevation: 9,
        hoverElevation: 10,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: const Color(0xFF183D2D).withValues(alpha: 0.07),
        height: 72,
        indicatorColor: const Color(0xFFDDF5E9),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primaryColor : mutedColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? primaryColor : mutedColor,
          );
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: fieldColor,
        selectedColor: const Color(0xFFDDF5E9),
        disabledColor: const Color(0xFFE7EBE8),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: lightText,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Color(0xFFDCE8E0),
        circularTrackColor: Color(0xFFDCE8E0),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF19372B),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Color(0xFFD2DDD6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: GoogleFonts.inter(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: GoogleFonts.inter(color: secondaryText, fontSize: 14),
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkPrimary = Color(0xFF43D9A3);
    const darkSecondary = Color(0xFFA3B5AC);
    const darkBorder = Color(0xFF26372F);
    const darkField = Color(0xFF1C2923);
    const darkError = Color(0xFFFF7777);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: darkPrimary,
      brightness: Brightness.dark,
      primary: darkPrimary,
      secondary: const Color(0xFF7BE8BD),
      surface: darkSurface,
      error: darkError,
    );

    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: darkText, displayColor: darkText);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      textTheme: textTheme,
      dividerColor: darkBorder,
      splashColor: darkPrimary.withValues(alpha: 0.08),
      highlightColor: darkPrimary.withValues(alpha: 0.04),
      visualDensity: VisualDensity.standard,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: darkText,
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        iconTheme: const IconThemeData(color: darkText, size: 23),
      ),

      cardTheme: CardThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: const BorderSide(color: darkBorder, width: 0.6),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkField,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        hintStyle: GoogleFonts.inter(color: darkSecondary, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: darkSecondary, fontSize: 14),
        prefixIconColor: darkSecondary,
        suffixIconColor: darkSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: darkPrimary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: darkError, width: 1.4),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF33483D);
            }
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFF2CB989);
            }
            return darkPrimary;
          }),
          foregroundColor: WidgetStateProperty.all(const Color(0xFF06251A)),
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 54)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) return 1;
            return 3;
          }),
          shadowColor: WidgetStateProperty.all(
            darkPrimary.withValues(alpha: 0.22),
          ),
          animationDuration: const Duration(milliseconds: 180),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: buttonRadius),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF06251A),
          elevation: 3,
          shadowColor: darkPrimary.withValues(alpha: 0.22),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          animationDuration: const Duration(milliseconds: 180),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          minimumSize: const Size(0, 50),
          side: const BorderSide(color: Color(0xFF34483D)),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: const Color(0xFF06251A),
        elevation: 7,
        focusElevation: 9,
        hoverElevation: 10,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        height: 72,
        indicatorColor: const Color(0xFF294D3D),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? darkPrimary : darkSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? darkPrimary : darkSecondary,
          );
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: darkField,
        selectedColor: const Color(0xFF294D3D),
        disabledColor: const Color(0xFF222D27),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: darkPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkPrimary,
        linearTrackColor: Color(0xFF2C3B33),
        circularTrackColor: Color(0xFF2C3B33),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF21372C),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Color(0xFF43564A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: GoogleFonts.inter(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: GoogleFonts.inter(color: darkSecondary, fontSize: 14),
      ),
    );
  }
}
