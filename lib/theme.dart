import 'package:flutter/material.dart';

/// Palette ya app: navy ya kina + rangi angavu (bluu, zambarau, machungwa, kijani)
/// kwa mtindo wa dashboard ya kisasa. Rangi zote ni imara (solid, bila gradient)
/// ili zionekane sawa kabisa kwenye Windows na Android.
class C {
  // ── Mandharinyuma (navy) ──────────────────────────────────────────────
  static const bgTop = Color(0xFF1B2158); // juu ya mandhari
  static const bg = Color(0xFF121740); // mandharinyuma kuu
  static const bgDeep = Color(0xFF0C1030); // sidebar / top bar
  static const card = Color(0xFF1B2152); // kadi
  static const cardAlt = Color(0xFF232A63); // kadi ya pili / hover
  static const head = Color(0xFF262E6B); // vichwa vya jedwali
  static const soft = Color(0xFF1F2658); // sehemu laini (chips, tracks)
  static const border = Color(0xFF343D82);

  // ── Maandishi ─────────────────────────────────────────────────────────
  static const text = Color(0xFFF2F4FF);
  static const muted = Color(0xFFA7AFD8);

  // ── Msisitizo ─────────────────────────────────────────────────────────
  static const navy = Color(0xFF8FA2FF); // kichwa/namba muhimu (periwinkle angavu)
  static const rose = Color(0xFF7C6CF0); // violet - msisitizo mkuu
  static const sky = Color(0xFF38BDF8);
  static const green = Color(0xFF34D399);
  static const amber = Color(0xFFFBBF24);
  static const danger = Color(0xFFFB7185);

  // Rangi imara ya vitufe (maandishi meupe yanasomeka juu yake)
  static const btn = Color(0xFF5B5BE0);
  static const btnGreen = Color(0xFF12A579);

  // ── Rangi imara za kadi/vitufe vilivyokuwa gradient ───────────────────
  // Gradient zilionekana NYEUPE kwenye baadhi ya Windows (GPU/driver), na
  // kuficha maandishi. Rangi imara zinaonekana sawa kila kifaa.
  static const cBlue = Color(0xFF3F7DF5);
  static const cOrange = Color(0xFFF2685A);
  static const cGreen = Color(0xFF0FA678);
  static const cViolet = Color(0xFF7C6CF0);
  static const cHeader = Color(0xFF4A4CC8);
}

OutlineInputBorder _ob(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c, width: w));

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: C.rose,
    brightness: Brightness.dark,
  ).copyWith(
    primary: C.rose,
    onPrimary: Colors.white,
    secondary: C.sky,
    surface: C.card,
    onSurface: C.text,
    surfaceContainerHighest: C.cardAlt,
    outline: C.border,
    error: C.danger,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    canvasColor: C.card,
    dividerColor: C.border,
    dividerTheme: const DividerThemeData(color: C.border, thickness: .8),
    // Fonti za mfumo (Segoe UI kwenye Windows, Roboto kwenye Android).
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: Typography.material2021().white.apply(
          bodyColor: C.text,
          displayColor: C.text,
        ),
    cardTheme: CardThemeData(
      color: C.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: C.border, width: .8)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: C.border, width: .8)),
      titleTextStyle: const TextStyle(
          color: C.text, fontSize: 18, fontWeight: FontWeight.w600),
      contentTextStyle: const TextStyle(color: C.text, fontSize: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: C.cardAlt,
      surfaceTintColor: Colors.transparent,
      textStyle: const TextStyle(color: C.text, fontSize: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: C.border, width: .8)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.cardAlt,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.soft,
      isDense: true,
      hintStyle: const TextStyle(color: C.muted),
      labelStyle: const TextStyle(color: C.muted),
      floatingLabelStyle: const TextStyle(color: C.navy),
      prefixIconColor: C.muted,
      suffixIconColor: C.muted,
      border: _ob(C.border),
      enabledBorder: _ob(C.border),
      focusedBorder: _ob(C.rose, 1.6),
      errorBorder: _ob(C.danger),
      focusedErrorBorder: _ob(C.danger, 1.6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.btn,
        foregroundColor: Colors.white,
        disabledBackgroundColor: C.cardAlt,
        disabledForegroundColor: C.muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.text,
        disabledForegroundColor: C.muted,
        side: const BorderSide(color: C.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: C.navy),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: C.text),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: C.soft,
      side: const BorderSide(color: C.border),
      labelStyle: const TextStyle(color: C.text, fontSize: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: C.rose,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.bgDeep,
      surfaceTintColor: Colors.transparent,
      indicatorColor: C.rose.withOpacity(.35),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
          fontSize: 11,
          color: s.contains(WidgetState.selected) ? Colors.white : C.muted)),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? Colors.white : C.muted)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.sky),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(C.border.withOpacity(.9)),
    ),
  );
}
