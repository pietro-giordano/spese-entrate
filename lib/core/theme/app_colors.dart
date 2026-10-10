import 'package:flutter/material.dart';

/// Famiglia di colori legata a un significato (spesa, entrata, gruppo di portafogli...).
@immutable
class ColorTone {
  const ColorTone({
    required this.fill,
    required this.onFill,
    required this.text,
    required this.tint,
    required this.onTint,
  });

  /// Sfondo pieno (pulsante salva, segmento attivo, chip categoria selezionata).
  final Color fill;

  /// Testo e icone sopra [fill].
  final Color onFill;

  /// Testo colorato su sfondo neutro (importi, link).
  final Color text;

  /// Sfondo tenue (icone dei movimenti, tessere dei portafogli, badge).
  final Color tint;

  /// Testo e icone sopra [tint].
  final Color onTint;

  static ColorTone lerp(ColorTone a, ColorTone b, double t) {
    return ColorTone(
      fill: Color.lerp(a.fill, b.fill, t)!,
      onFill: Color.lerp(a.onFill, b.onFill, t)!,
      text: Color.lerp(a.text, b.text, t)!,
      tint: Color.lerp(a.tint, b.tint, t)!,
      onTint: Color.lerp(a.onTint, b.onTint, t)!,
    );
  }
}

/// Token di colore dell'app, letti nei widget con `context.colors`.
///
/// Una [ThemeExtension] aggiunge a [ThemeData] valori che Material non prevede;
/// Flutter la interpola ([lerp]) quando il tema cambia.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.raisedShadow,
    required this.track,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.text,
    required this.textMuted,
    required this.danger,
    required this.switchTrackOff,
    required this.switchThumb,
    required this.switchThumbShadow,
    required this.scrim,
    required this.chartSeries,
    required this.expense,
    required this.income,
    required this.neutral,
    required this.liquidity,
    required this.savings,
    required this.investments,
  });

  // Neutri
  final Color background;
  final Color surface;

  /// Segmento attivo; in chiaro è bianco con [raisedShadow], in scuro un grigio più chiaro.
  final Color surfaceRaised;
  final List<BoxShadow> raisedShadow;

  /// Sfondo dei segmented.
  final Color track;
  final Color border;
  final Color borderStrong;
  final Color divider;
  final Color text;
  final Color textMuted;
  final Color danger;
  final Color switchTrackOff;

  /// Pallino dell'interruttore (bianco in entrambi i temi) e la sua ombra.
  final Color switchThumb;
  final List<BoxShadow> switchThumbShadow;

  /// Velo dietro i pannelli dal basso.
  final Color scrim;

  /// Colori delle serie nei grafici di confronto, nell'ordine dei periodi (blu, arancio, verde acqua).
  final List<Color> chartSeries;

  // Dominio
  final ColorTone expense;
  final ColorTone income;

  /// Trasferimenti e azioni neutre.
  final ColorTone neutral;

  // Gruppi di portafogli
  final ColorTone liquidity;
  final ColorTone savings;
  final ColorTone investments;

  static const light = AppColors(
    background: Color(0xFFF7F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    raisedShadow: [BoxShadow(color: Color(0x1A000000), offset: Offset(0, 1), blurRadius: 2)],
    track: Color(0xFFE9E9E4),
    border: Color(0xFFE4E4DF),
    borderStrong: Color(0xFFDCDCD6),
    divider: Color(0xFFEFEFEA),
    text: Color(0xFF16181D),
    textMuted: Color(0xFF5B5F66),
    danger: Color(0xFFB4410C),
    switchTrackOff: Color(0xFFC9CBC4),
    switchThumb: Color(0xFFFFFFFF),
    switchThumbShadow: [BoxShadow(color: Color(0x40000000), offset: Offset(0, 1), blurRadius: 2)],
    scrim: Color(0x73111316),
    chartSeries: [Color(0xFF1D4ED8), Color(0xFFF08A4B), Color(0xFF0F5F58)],
    expense: ColorTone(
      fill: Color(0xFFC2410C),
      onFill: Color(0xFFFFFFFF),
      text: Color(0xFFC2410C),
      tint: Color(0xFFFCE9DF),
      onTint: Color(0xFF9A3412),
    ),
    income: ColorTone(
      fill: Color(0xFF1D4ED8),
      onFill: Color(0xFFFFFFFF),
      text: Color(0xFF1D4ED8),
      tint: Color(0xFFDCE5FB),
      onTint: Color(0xFF1E3A8A),
    ),
    neutral: ColorTone(
      fill: Color(0xFF16181D),
      onFill: Color(0xFFFFFFFF),
      text: Color(0xFF16181D),
      tint: Color(0xFFF1F1EE),
      onTint: Color(0xFF3D4148),
    ),
    liquidity: ColorTone(
      fill: Color(0xFF1D4ED8),
      onFill: Color(0xFFFFFFFF),
      text: Color(0xFF1D4ED8),
      tint: Color(0xFFDCE5FB),
      onTint: Color(0xFF1E3A8A),
    ),
    savings: ColorTone(
      fill: Color(0xFF0F5F58),
      onFill: Color(0xFFFFFFFF),
      text: Color(0xFF0F5F58),
      tint: Color(0xFFD5ECE9),
      onTint: Color(0xFF0F5F58),
    ),
    investments: ColorTone(
      fill: Color(0xFF7C3AED),
      onFill: Color(0xFFFFFFFF),
      text: Color(0xFF7C3AED),
      tint: Color(0xFFEAE2FB),
      onTint: Color(0xFF5B21B6),
    ),
  );

  static const dark = AppColors(
    background: Color(0xFF111316),
    surface: Color(0xFF1B1E23),
    surfaceRaised: Color(0xFF3A3F48),
    raisedShadow: [],
    track: Color(0xFF23272D),
    border: Color(0xFF2A2E35),
    borderStrong: Color(0xFF353A42),
    divider: Color(0xFF262A30),
    text: Color(0xFFEDEEF0),
    textMuted: Color(0xFFA3A8B0),
    danger: Color(0xFFF28C55),
    switchTrackOff: Color(0xFF4A4F58),
    switchThumb: Color(0xFFFFFFFF),
    switchThumbShadow: [BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 2)],
    scrim: Color(0x99000000),
    chartSeries: [Color(0xFF7DA0F7), Color(0xFFF08A4B), Color(0xFF4FB3A8)],
    expense: ColorTone(
      fill: Color(0xFFC2410C),
      onFill: Color(0xFFFFFFFF),
      text: Color(0xFFF28C55),
      tint: Color(0xFF3A2219),
      onTint: Color(0xFFF28C55),
    ),
    income: ColorTone(
      fill: Color(0xFF1D4ED8),
      onFill: Color(0xFFFFFFFF),
      text: Color(0xFF7DA0F7),
      tint: Color(0xFF1E2A4D),
      onTint: Color(0xFF7DA0F7),
    ),
    neutral: ColorTone(
      fill: Color(0xFFEDEEF0),
      onFill: Color(0xFF111316),
      text: Color(0xFFEDEEF0),
      tint: Color(0xFF23272D),
      onTint: Color(0xFFA3A8B0),
    ),
    liquidity: ColorTone(
      fill: Color(0xFF1D4ED8),
      onFill: Color(0xFFFFFFFF),
      text: Color(0xFF7DA0F7),
      tint: Color(0xFF1E2A4D),
      onTint: Color(0xFF7DA0F7),
    ),
    savings: ColorTone(
      fill: Color(0xFF4FB3A8),
      onFill: Color(0xFF111316),
      text: Color(0xFF4FB3A8),
      tint: Color(0xFF163A36),
      onTint: Color(0xFF4FB3A8),
    ),
    investments: ColorTone(
      fill: Color(0xFFA78BFA),
      onFill: Color(0xFF111316),
      text: Color(0xFFA78BFA),
      tint: Color(0xFF2E2448),
      onTint: Color(0xFFA78BFA),
    ),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    List<BoxShadow>? raisedShadow,
    Color? track,
    Color? border,
    Color? borderStrong,
    Color? divider,
    Color? text,
    Color? textMuted,
    Color? danger,
    Color? switchTrackOff,
    Color? switchThumb,
    List<BoxShadow>? switchThumbShadow,
    Color? scrim,
    List<Color>? chartSeries,
    ColorTone? expense,
    ColorTone? income,
    ColorTone? neutral,
    ColorTone? liquidity,
    ColorTone? savings,
    ColorTone? investments,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      raisedShadow: raisedShadow ?? this.raisedShadow,
      track: track ?? this.track,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      divider: divider ?? this.divider,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      danger: danger ?? this.danger,
      switchTrackOff: switchTrackOff ?? this.switchTrackOff,
      switchThumb: switchThumb ?? this.switchThumb,
      switchThumbShadow: switchThumbShadow ?? this.switchThumbShadow,
      scrim: scrim ?? this.scrim,
      chartSeries: chartSeries ?? this.chartSeries,
      expense: expense ?? this.expense,
      income: income ?? this.income,
      neutral: neutral ?? this.neutral,
      liquidity: liquidity ?? this.liquidity,
      savings: savings ?? this.savings,
      investments: investments ?? this.investments,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      raisedShadow: BoxShadow.lerpList(raisedShadow, other.raisedShadow, t)!,
      track: Color.lerp(track, other.track, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      switchTrackOff: Color.lerp(switchTrackOff, other.switchTrackOff, t)!,
      switchThumb: Color.lerp(switchThumb, other.switchThumb, t)!,
      switchThumbShadow: BoxShadow.lerpList(switchThumbShadow, other.switchThumbShadow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      chartSeries: [for (var i = 0; i < chartSeries.length; i++) Color.lerp(chartSeries[i], other.chartSeries[i], t)!],
      expense: ColorTone.lerp(expense, other.expense, t),
      income: ColorTone.lerp(income, other.income, t),
      neutral: ColorTone.lerp(neutral, other.neutral, t),
      liquidity: ColorTone.lerp(liquidity, other.liquidity, t),
      savings: ColorTone.lerp(savings, other.savings, t),
      investments: ColorTone.lerp(investments, other.investments, t),
    );
  }
}

/// Scorciatoia: `context.colors.expense.fill` invece di `Theme.of(context).extension<AppColors>()!`.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
