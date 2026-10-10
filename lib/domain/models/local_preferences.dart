import 'package:freezed_annotation/freezed_annotation.dart';

part 'local_preferences.freezed.dart';

enum AppThemeMode { system, light, dark }

/// Preferenze solo di questo dispositivo (tabella `app_meta`): non si sincronizzano.
@freezed
abstract class LocalPreferences with _$LocalPreferences {
  const factory LocalPreferences({
    @Default(AppThemeMode.system) AppThemeMode themeMode,

    /// Chiede la biometria all'apertura e al ritorno dopo 1 minuto in background.
    @Default(false) bool biometricLock,

    /// Profilo facoltativo, solo locale.
    String? profileName,
    String? profileEmail,
  }) = _LocalPreferences;
}
