/// Spaziature: base 4, margini laterali delle schermate 20.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Margine orizzontale standard delle schermate.
  static const double screen = 20;
}

/// Raggi degli angoli.
abstract final class AppRadius {
  static const double labelChip = 8;
  static const double field = 12;
  static const double button = 16;
  static const double card = 18;
  static const double cardLarge = 20;
  static const double sheet = 24;
}

/// Dimensioni minime per l'accessibilità.
abstract final class AppSizes {
  /// Target tattile minimo (44×44).
  static const double minTouchTarget = 44;
}
