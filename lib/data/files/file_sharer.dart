import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'file_sharer.g.dart';

/// Apre il menu di condivisione del telefono per un file (share_plus). Nei test si sostituisce.
class FileSharer {
  const FileSharer();

  Future<void> shareFile(String path, {required String mimeType, String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: mimeType)],
        subject: subject,
      ),
    );
  }
}

@Riverpod(keepAlive: true)
FileSharer fileSharer(Ref ref) => const FileSharer();
