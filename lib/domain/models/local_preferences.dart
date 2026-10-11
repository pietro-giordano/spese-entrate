import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_preferences.freezed.dart';

enum AppThemeMode { system, light, dark }

/// Saldi all'apertura dell'app: sempre visibili, sempre nascosti o come li si era lasciati.
enum BalancesOnOpen { visible, hidden, remember }

/// Preferenze solo di questo dispositivo (tabella `app_meta`): non si sincronizzano.
@freezed
abstract class LocalPreferences with _$LocalPreferences {
  const factory LocalPreferences({
    @Default(AppThemeMode.system) AppThemeMode themeMode,

    /// Chiede la biometria all'apertura e al ritorno dopo 1 minuto in background.
    @Default(false) bool biometricLock,

    /// Saldi visibili o nascosti all'apertura (sezione Privacy delle Impostazioni).
    @Default(BalancesOnOpen.visible) BalancesOnOpen balancesOnOpen,

    /// Ultima scelta dell'occhio in Portafogli: serve con [BalancesOnOpen.remember].
    @Default(false) bool balancesHidden,

    /// Profilo facoltativo, solo locale.
    String? profileName,
    String? profileEmail,
  }) = _LocalPreferences;
}
