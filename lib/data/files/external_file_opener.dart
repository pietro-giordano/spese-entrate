import 'package:open_filex/open_filex.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'external_file_opener.g.dart';

/// Esito dell'apertura di un file con un'altra app.
enum ExternalOpenResult { opened, noApp, failed }

/// Apre un file privato dell'app con un'app esterna (open_filex). Nei test si sostituisce.
///
/// - Android: passa all'altra app un URI `content://` del FileProvider del plugin, con un
///   permesso di sola lettura temporaneo per quel file; i file nella cartella privata
///   non richiedono permessi di archiviazione.
/// - iOS: anteprima di sistema (Quick Look), con "Apri in…" se non è possibile.
class ExternalFileOpener {
  const ExternalFileOpener();

  Future<ExternalOpenResult> open(String path, {required String mimeType}) async {
    try {
      final result = await OpenFilex.open(path, type: mimeType);
      return switch (result.type) {
        ResultType.done => ExternalOpenResult.opened,
        ResultType.noAppToOpen => ExternalOpenResult.noApp,
        _ => ExternalOpenResult.failed,
      };
    } on Exception {
      return ExternalOpenResult.failed;
    }
  }
}

@Riverpod(keepAlive: true)
ExternalFileOpener externalFileOpener(Ref ref) => const ExternalFileOpener();
