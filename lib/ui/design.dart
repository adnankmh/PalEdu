import 'package:flutter/material.dart';

class PColors {
  static const midnight = Color(0xFF102950);
  static const royal = Color(0xFF183E78);
  static const teal = Color(0xFF03AFA5);
  static const gold = Color(0xFFFFC766);
  static const pale = Color(0xFFF3F7FC);
  static const mint = Color(0xFFE2F6F2);
  static const lavender = Color(0xFFECE7FF);
}

ThemeData palTheme(bool dark) {
  final colors = ColorScheme.fromSeed(
    seedColor: PColors.royal,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: dark ? const Color(0xFF82DAD2) : PColors.midnight,
    secondary: PColors.teal,
    surface: dark ? const Color(0xFF1A2942) : Colors.white,
  );
  return ThemeData(
    useMaterial3: true, colorScheme: colors,
    scaffoldBackgroundColor: dark ? const Color(0xFF0D1A2E) : PColors.pale,
    appBarTheme: const AppBarTheme(centerTitle: false,
      backgroundColor: Colors.transparent),
    cardTheme: CardThemeData(elevation: 0, margin: EdgeInsets.zero,
      color: colors.surface, shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: colors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(16)),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
  );
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) =>
    Card(child: Padding(padding: padding, child: child));
}
