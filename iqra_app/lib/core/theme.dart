import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Colour tokens used by every screen. Reached with `context.c`.
@immutable
class IqraColors extends ThemeExtension<IqraColors> {
  const IqraColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.sidebar,
    required this.text,
    required this.textSecondary,
    required this.separator,
    required this.accent,
    required this.onAccent,
    required this.paper,
    required this.ink,
    required this.dark,
  });

  final Color bg, surface, surfaceAlt, sidebar, text, textSecondary, separator, accent, onAccent, paper, ink;
  final bool dark;

  Color get tint => accent.withValues(alpha: dark ? 0.22 : 0.12);

  IqraColors withAccent(Color? a) {
    if (a == null) return this;
    return copyWith(accent: a, onAccent: onFor(a));
  }

  @override
  IqraColors copyWith({Color? accent, Color? onAccent}) => IqraColors(
        bg: bg,
        surface: surface,
        surfaceAlt: surfaceAlt,
        sidebar: sidebar,
        text: text,
        textSecondary: textSecondary,
        separator: separator,
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
        paper: paper,
        ink: ink,
        dark: dark,
      );

  @override
  IqraColors lerp(ThemeExtension<IqraColors>? other, double t) {
    if (other is! IqraColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return IqraColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      sidebar: l(sidebar, other.sidebar),
      text: l(text, other.text),
      textSecondary: l(textSecondary, other.textSecondary),
      separator: l(separator, other.separator),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      paper: l(paper, other.paper),
      ink: l(ink, other.ink),
      dark: t < 0.5 ? dark : other.dark,
    );
  }
}

Color onFor(Color c) => c.computeLuminance() > 0.45 ? const Color(0xFF10150F) : Colors.white;

extension IqraContext on BuildContext {
  IqraColors get c => Theme.of(this).extension<IqraColors>()!;
}

class ThemeDef {
  const ThemeDef(this.id, this.name, this.colors);
  final String id, name;
  final IqraColors colors;
}

const _emerald = Color(0xFF0E7A5E);

const _light = IqraColors(
  bg: Color(0xFFFFFFFF), surface: Color(0xFFF5F5F7), surfaceAlt: Color(0xFFEBEBF0), sidebar: Color(0xFFF2F2F5),
  text: Color(0xFF1D1D1F), textSecondary: Color(0xFF6E6E73), separator: Color(0xFFE3E3E8),
  accent: _emerald, onAccent: Colors.white, paper: Color(0xFFFFFEFA), ink: Color(0xFF1B1B19), dark: false,
);

const kThemes = <ThemeDef>[
  ThemeDef('light', 'Light', _light),
  ThemeDef(
    'sepia',
    'Sepia',
    IqraColors(
      bg: Color(0xFFF6EEDB), surface: Color(0xFFEFE4C8), surfaceAlt: Color(0xFFE6D8B5), sidebar: Color(0xFFEFE4C8),
      text: Color(0xFF3B2F1C), textSecondary: Color(0xFF7A6A4C), separator: Color(0xFFDCCDA6),
      accent: Color(0xFF8A5A14), onAccent: Color(0xFFFFF8E8), paper: Color(0xFFF8F0DC), ink: Color(0xFF3B2F1C), dark: false,
    ),
  ),
  ThemeDef(
    'rose',
    'Rose',
    IqraColors(
      bg: Color(0xFFFFF7F8), surface: Color(0xFFFCEBEE), surfaceAlt: Color(0xFFF8DCE2), sidebar: Color(0xFFFBEAEE),
      text: Color(0xFF2B1A1F), textSecondary: Color(0xFF86606A), separator: Color(0xFFF1D5DB),
      accent: Color(0xFFC2335B), onAccent: Colors.white, paper: Color(0xFFFFFBFB), ink: Color(0xFF2B1A1F), dark: false,
    ),
  ),
  ThemeDef(
    'ocean',
    'Ocean',
    IqraColors(
      bg: Color(0xFFF5FAFC), surface: Color(0xFFE6F1F6), surfaceAlt: Color(0xFFD6E8F0), sidebar: Color(0xFFE5F0F5),
      text: Color(0xFF10252E), textSecondary: Color(0xFF55727F), separator: Color(0xFFD0E2EA),
      accent: Color(0xFF0A7AA0), onAccent: Colors.white, paper: Color(0xFFFBFEFF), ink: Color(0xFF10252E), dark: false,
    ),
  ),
  ThemeDef(
    'lavender',
    'Lavender',
    IqraColors(
      bg: Color(0xFFFAF8FF), surface: Color(0xFFEFEBFA), surfaceAlt: Color(0xFFE3DDF5), sidebar: Color(0xFFEEEAFA),
      text: Color(0xFF1F1A30), textSecondary: Color(0xFF6A6285), separator: Color(0xFFDDD6F0),
      accent: Color(0xFF6A4FD0), onAccent: Colors.white, paper: Color(0xFFFEFDFF), ink: Color(0xFF1F1A30), dark: false,
    ),
  ),
  ThemeDef(
    'dark',
    'Dark',
    IqraColors(
      bg: Color(0xFF1C1C1E), surface: Color(0xFF2C2C2E), surfaceAlt: Color(0xFF3A3A3C), sidebar: Color(0xFF242426),
      text: Color(0xFFF5F5F7), textSecondary: Color(0xFF9A9AA0), separator: Color(0xFF38383A),
      accent: Color(0xFF34C79A), onAccent: Color(0xFF04201A), paper: Color(0xFF1E2321), ink: Color(0xFFE8E4D4), dark: true,
    ),
  ),
  ThemeDef(
    'midnight',
    'Midnight',
    IqraColors(
      bg: Color(0xFF0B1220), surface: Color(0xFF131C2E), surfaceAlt: Color(0xFF1B2740), sidebar: Color(0xFF0F1727),
      text: Color(0xFFE8EEFB), textSecondary: Color(0xFF8798B8), separator: Color(0xFF1F2B45),
      accent: Color(0xFF6FA8FF), onAccent: Color(0xFF06142B), paper: Color(0xFF0F1828), ink: Color(0xFFE4EAF7), dark: true,
    ),
  ),
  ThemeDef(
    'forest',
    'Forest',
    IqraColors(
      bg: Color(0xFF0E1814), surface: Color(0xFF16241E), surfaceAlt: Color(0xFF1E3029), sidebar: Color(0xFF121E19),
      text: Color(0xFFE6F0E8), textSecondary: Color(0xFF86A08F), separator: Color(0xFF223A30),
      accent: Color(0xFF5BD59A), onAccent: Color(0xFF03180E), paper: Color(0xFF111D18), ink: Color(0xFFE2EBDD), dark: true,
    ),
  ),
  ThemeDef(
    'dune',
    'Dune',
    IqraColors(
      bg: Color(0xFFFFF9F0), surface: Color(0xFFF6EBD9), surfaceAlt: Color(0xFFEEDCC0), sidebar: Color(0xFFF7ECDA),
      text: Color(0xFF2E2113), textSecondary: Color(0xFF8A7358), separator: Color(0xFFEBDBC2),
      accent: Color(0xFFB5651D), onAccent: Colors.white, paper: Color(0xFFFFFCF6), ink: Color(0xFF2E2113), dark: false,
    ),
  ),
  ThemeDef(
    'sage',
    'Sage',
    IqraColors(
      bg: Color(0xFFF5F7F1), surface: Color(0xFFE8EDDF), surfaceAlt: Color(0xFFDAE2CC), sidebar: Color(0xFFE9EEE0),
      text: Color(0xFF1F2A17), textSecondary: Color(0xFF69795A), separator: Color(0xFFD7E0C9),
      accent: Color(0xFF4F7A2B), onAccent: Colors.white, paper: Color(0xFFFAFBF6), ink: Color(0xFF1F2A17), dark: false,
    ),
  ),
  ThemeDef(
    'amethyst',
    'Amethyst',
    IqraColors(
      bg: Color(0xFF14101F), surface: Color(0xFF1E1830), surfaceAlt: Color(0xFF2A2142), sidebar: Color(0xFF191426),
      text: Color(0xFFEFE9FF), textSecondary: Color(0xFF9C90BD), separator: Color(0xFF2B2344),
      accent: Color(0xFFB18CFF), onAccent: Color(0xFF1A0B38), paper: Color(0xFF171222), ink: Color(0xFFEAE4F8), dark: true,
    ),
  ),
  ThemeDef(
    'ember',
    'Ember',
    IqraColors(
      bg: Color(0xFF17110E), surface: Color(0xFF241915), surfaceAlt: Color(0xFF33231C), sidebar: Color(0xFF1C1411),
      text: Color(0xFFF6EDE6), textSecondary: Color(0xFFA38C7C), separator: Color(0xFF35261F),
      accent: Color(0xFFFF9A5A), onAccent: Color(0xFF2C1203), paper: Color(0xFF1A1310), ink: Color(0xFFF0E6DB), dark: true,
    ),
  ),
  ThemeDef(
    'black',
    'Black',
    IqraColors(
      bg: Color(0xFF000000), surface: Color(0xFF111112), surfaceAlt: Color(0xFF1C1C1E), sidebar: Color(0xFF080808),
      text: Color(0xFFF2F2F2), textSecondary: Color(0xFF8E8E93), separator: Color(0xFF232325),
      accent: Color(0xFF34C79A), onAccent: Color(0xFF04201A), paper: Color(0xFF000000), ink: Color(0xFFE6E2D3), dark: true,
    ),
  ),
];

/// "auto" follows the system brightness (light or dark).
ThemeDef resolveTheme(String id, Brightness system) {
  final want = id == 'auto' ? (system == Brightness.dark ? 'dark' : 'light') : id;
  return kThemes.firstWhere((t) => t.id == want, orElse: () => kThemes.first);
}

const kAccents = <(String, Color?)>[
  ('Theme', null),
  ('Emerald', Color(0xFF0E9F7A)),
  ('Teal', Color(0xFF0D8F9A)),
  ('Blue', Color(0xFF2F6FD6)),
  ('Indigo', Color(0xFF5B5BD6)),
  ('Violet', Color(0xFF8A4FD0)),
  ('Rose', Color(0xFFFA2D55)),
  ('Terracotta', Color(0xFFD0572D)),
  ('Amber', Color(0xFFC98512)),
  ('Slate', Color(0xFF5D6B7A)),
];

ThemeData buildTheme(IqraColors c) {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: c.dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: c.accent, brightness: c.dark ? Brightness.dark : Brightness.light).copyWith(
      primary: c.accent,
      onPrimary: c.onAccent,
      surface: c.bg,
      onSurface: c.text,
    ),
  );
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.separator,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    iconTheme: IconThemeData(color: c.text),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: IqraPageTransitions(),
      TargetPlatform.linux: IqraPageTransitions(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    }),
    extensions: [c],
  );
}

/// Opening a page: the new page slides in a short way while it fades up, and the page beneath drifts back and dims a little.
class IqraPageTransitions extends PageTransitionsBuilder {
  const IqraPageTransitions();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final under = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return SlideTransition(
      position: Tween(begin: const Offset(0.07, 0), end: Offset.zero).animate(enter),
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween(begin: Offset.zero, end: const Offset(-0.035, 0)).animate(under),
          child: FadeTransition(opacity: Tween(begin: 1.0, end: 0.9).animate(under), child: child),
        ),
      ),
    );
  }
}
