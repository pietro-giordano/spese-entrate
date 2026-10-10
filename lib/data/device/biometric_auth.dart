import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_auth.g.dart';

/// Face ID, impronta o, se l'utente lo preferisce, il codice del telefono (local_auth).
/// Nei test si sostituisce con un finto.
class BiometricAuth {
  BiometricAuth([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// True se il dispositivo può autenticare l'utente (biometria o codice).
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on LocalAuthException {
      return false;
    }
  }

  /// Chiede l'autenticazione. False se l'utente annulla o non è possibile.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, persistAcrossBackgrounding: true);
    } on LocalAuthException {
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
BiometricAuth biometricAuth(Ref ref) => BiometricAuth();
