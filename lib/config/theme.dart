import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // VerhuurAgenda Brand Colors
  static const Color primaryColor = Color(0xFF4F46E5); // Indigo
  static const Color secondaryColor = Color(0xFF10B981); // Emerald
  static const Color accentColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color successColor = Color(0xFF22C55E); // Green

  // Booking Status Colors
  static const Color statusConfirmed = Color(0xFF22C55E);
  static const Color statusOption = Color(0xFFF59E0B);
  static const Color statusInquiry = Color(0xFF3B82F6);
  static const Color statusCancelled = Color(0xFFEF4444);

  // Payment Status Colors
  static const Color paymentPaid = Color(0xFF22C55E);
  static const Color paymentPartial = Color(0xFFF97316);
  static const Color paymentUnpaid = Color(0xFFEF4444);

  // Source Colors
  static const Color sourceAirbnb = Color(0xFFFF5A5F);
  static const Color sourceBooking = Color(0xFF003580);
  static const Color sourceDirect = Color(0xFF4F46E5);
  static const Color sourceOther = Color(0xFF6B7280);

  // ── Neutrals (iOS-inspired clean palette) ──────────
  // Page background — barely-grey, lets cards float on white
  static const Color _bg = Color(0xFFF7F7FA);
  // Hairline divider — almost invisible, 8% black
  static const Color _hairline = Color(0xFFE6E6EB);
  // Subtle text colors
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _textTertiary = Color(0xFF9CA3AF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: _bg,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: _textPrimary,
        displayColor: _textPrimary,
      ),
      // ── App bar ────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _bg, // matches page, no harsh divider
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textPrimary,
        titleTextStyle: TextStyle(
          color: _textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      // ── Cards ──────────────────────────────────────────
      // Flat white card on the soft grey page — no border, no
      // shadow. Stands out purely by contrast.
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      // ── Inputs ─────────────────────────────────────────
      // No fill, no thick borders — clean hairline that lifts
      // to primary color on focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: _hairline, width: 1),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _hairline, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          color: _textSecondary,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 13,
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          fontSize: 15,
          color: _textTertiary,
        ),
        helperStyle: const TextStyle(
          fontSize: 12,
          color: _textTertiary,
        ),
        prefixIconColor: _textTertiary,
        suffixIconColor: _textTertiary,
      ),
      // ── Buttons ────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimary,
          backgroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: _hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // ── Dialogs ────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: _textSecondary,
          height: 1.45,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      ),
      // ── Bottom sheets ──────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      // ── List tiles ─────────────────────────────────────
      // Roomy enough to tap, but hairline-only separation.
      listTileTheme: const ListTileThemeData(
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 10,
        iconColor: _textSecondary,
        titleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _textPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          color: _textSecondary,
        ),
      ),
      // ── Dividers ───────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: _hairline,
        thickness: 0.5,
        space: 0.5,
      ),
      // ── Switches / Checkboxes / Radios ─────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return _hairline;
        }),
        trackOutlineColor:
            const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return null;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: _textTertiary),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return _textTertiary;
        }),
      ),
      // ── Bottom navigation ──────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: _textTertiary,
        showUnselectedLabels: true,
      ),
      // ── Snackbars ──────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // ── Chips ──────────────────────────────────────────
      chipTheme: const ChipThemeData(
        backgroundColor: Colors.white,
        side: BorderSide(color: _hairline),
        shape: StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: TextStyle(
          fontSize: 13,
          color: _textPrimary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
}
