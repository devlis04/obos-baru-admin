import 'package:flutter/material.dart';

class Tema {
  static const Color seed = Color(0xFF1B75CB);
  static const Color biru = seed;
  static const Color latar = Color(0xFFF3F5F8);
  static const Color kartu = Colors.white;
  static const Color teksKartu = Colors.black;
  static const Color redup = Colors.grey;
  static const Color salah = Colors.red;
  static const Color teksTerang = Colors.white;

  static const double pxSudut = 5;
  static const BorderRadius sudut = BorderRadius.all(Radius.circular(pxSudut));

  static ThemeData terang() {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: seed).copyWith(
      primary: seed,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD6E8F7),
      onPrimaryContainer: seed,
      secondary: seed,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD6E8F7),
      onSecondaryContainer: seed,
      surfaceTint: seed,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: latar,
      iconTheme: const IconThemeData(color: seed),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.6,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: seed),
        actionsIconTheme: const IconThemeData(color: seed),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const RoundedRectangleBorder(
          borderRadius: sudut,
          side: BorderSide(color: seed, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seed,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: const OutlineInputBorder(
          borderRadius: sudut,
          borderSide: BorderSide(color: seed, width: 1.2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: sudut,
          borderSide: BorderSide(color: seed, width: 1.2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: sudut,
          borderSide: BorderSide(color: seed, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: sudut,
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: sudut),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        shape: RoundedRectangleBorder(borderRadius: sudut),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: sudut),
        contentTextStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: seed),
    );
  }
}
