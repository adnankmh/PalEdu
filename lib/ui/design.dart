import 'package:flutter/material.dart';

/// PalEdu Royal Emerald — a single coherent design system across all roles.
/// Colors are accessible in light and dark modes; no remote font is required.
class PColors {
  static const midnight = Color(0xFF073E31);
  static const royal = Color(0xFF0B563E);
  static const teal = Color(0xFF087E67);
  static const gold = Color(0xFFF2BE50);
  static const pale = Color(0xFFF5F7FA);
  static const mint = Color(0xFFE6F3EB);
  static const lavender = Color(0xFFECE9FB);
  static const ink = Color(0xFF152238);
  static const muted = Color(0xFF66788D);
  static const orange = Color(0xFFE78A14);
  static const blue = Color(0xFF367DE8);
}

ThemeData palTheme(bool dark) {
  final scheme = ColorScheme.fromSeed(
    seedColor: PColors.royal,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: dark ? const Color(0xFF77D6AE) : PColors.royal,
    secondary: dark ? PColors.gold : PColors.teal,
    surface: dark ? const Color(0xFF182C30) : Colors.white,
    onSurface: dark ? const Color(0xFFF4F8F7) : PColors.ink,
  );
  final field = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: dark
        ? const Color(0xFF43555A) : const Color(0xFFDDE5EF)),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF102024) : PColors.pale,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: dark ? const Color(0xFF102024) : PColors.pale,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: scheme.onSurface, fontWeight: FontWeight.w900, fontSize: 20)),
    cardTheme: CardThemeData(
      elevation: 0, margin: EdgeInsets.zero,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: dark
          ? const Color(0xFF34474A) : const Color(0xFFE0E7EF)),
        borderRadius: BorderRadius.circular(23))),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      indicatorColor: dark ? const Color(0xFF275846) : PColors.mint,
      backgroundColor: scheme.surface,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: scheme.surface,
      border: field, enabledBorder: field,
      focusedBorder: field.copyWith(
        borderSide: BorderSide(color: scheme.primary, width: 1.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15)),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        side: BorderSide(color: dark
          ? const Color(0xFF43555A) : const Color(0xFFDCE5ED)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)))),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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

class RoyalSectionHeading extends StatelessWidget {
  const RoyalSectionHeading({super.key,required this.title,this.subtitle,this.action,this.onAction});
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900)),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(subtitle!, style: TextStyle(fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    ])),
    if (action != null && onAction != null)
      TextButton(onPressed:onAction,child: Text(action!)),
  ]);
}

/// Consistent compact icon tile, safe for RTL and narrow phone screens.
class RoyalQuickAction extends StatelessWidget {
  const RoyalQuickAction({super.key, required this.icon, required this.label,
    required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true, label: label,
    child: InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 2),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 49,height:49,
            decoration: BoxDecoration(color:color.withValues(alpha:.11),
              borderRadius:BorderRadius.circular(15)),
            child:Icon(icon,color:color,size:25)),
          const SizedBox(height: 8),
          Text(label, maxLines:2,overflow:TextOverflow.ellipsis,
            textAlign:TextAlign.center,
            style:const TextStyle(fontSize:12,fontWeight:FontWeight.w800)),
        ]))),
  );
}
