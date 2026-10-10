import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment.freezed.dart';

@freezed
abstract class Attachment with _$Attachment {
  const factory Attachment({
    required String id,
    required String transactionId,

    /// Relativo alla cartella documenti dell'app.
    required String localPath,
    required String mimeType,
    required int sizeBytes,
    required String sha256,
    String? remoteUrl,
  }) = _Attachment;
}
