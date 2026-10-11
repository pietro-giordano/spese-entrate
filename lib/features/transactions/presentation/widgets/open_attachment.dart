import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_list_row.dart';
import '../../../../domain/models/attachment.dart';
import '../../application/attachment_actions.dart';
import '../attachment_viewer_screen.dart';

enum _FileAction { open, share }

/// Apre un allegato salvato: le immagini nel visualizzatore (scorrendo tra tutte le immagini
/// di [all]), gli altri file (PDF) con un'altra app oppure con il menu di condivisione.
/// I problemi (file mancante, danneggiato, nessuna app) diventano un messaggio.
Future<void> openAttachment(BuildContext context, WidgetRef ref, Attachment attachment, List<Attachment> all) async {
  if (attachment.mimeType.startsWith('image/')) {
    final images = all.where((a) => a.mimeType.startsWith('image/')).toList();
    return AttachmentViewerScreen.show(context, images, initialIndex: images.indexOf(attachment));
  }

  final action = await AppBottomSheet.show<_FileAction>(
    context,
    title: attachment.mimeType == 'application/pdf' ? 'Documento PDF' : 'Allegato',
    builder: (sheetContext) => AppListGroup(
      children: [
        AppListRow(
          title: 'Apri',
          subtitle: 'Con un\'app del telefono per i PDF',
          onTap: () => Navigator.pop(sheetContext, _FileAction.open),
        ),
        AppListRow(
          title: 'Condividi',
          subtitle: 'Invia o salva il file con il menu del telefono',
          onTap: () => Navigator.pop(sheetContext, _FileAction.share),
        ),
      ],
    ),
  );
  if (action == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(attachmentActionsProvider);
  final problem = switch (action) {
    _FileAction.open => await actions.openExternally(attachment),
    _FileAction.share => await actions.share(attachment),
  };
  if (problem != null) messenger.showSnackBar(SnackBar(content: Text(problem.message)));
}
