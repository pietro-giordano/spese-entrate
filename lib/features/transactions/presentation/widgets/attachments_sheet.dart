import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../data/files/attachment_picker.dart';
import '../../application/transaction_form_controller.dart';

/// Pannello Allegati: anteprime dei nuovi allegati con rimozione, foto, galleria e file.
/// Legge e modifica direttamente lo stato del form ([provider]). Con [showThumbnails] false
/// mostra solo le azioni (in Modifica movimento le anteprime sono già nella schermata).
Future<void> showAttachmentsSheet(
  BuildContext context,
  TransactionFormControllerProvider provider, {
  bool showThumbnails = true,
}) {
  return AppBottomSheet.show<void>(
    context,
    title: 'Allegati',
    titleTrailing: Consumer(
      builder: (context, ref, _) => Text(
        '${ref.watch(provider.select((s) => s.attachmentCount))} di $maxAttachments',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.colors.textMuted),
      ),
    ),
    builder: (_) => _AttachmentsBody(provider: provider, showThumbnails: showThumbnails),
  );
}

class _AttachmentsBody extends ConsumerStatefulWidget {
  const _AttachmentsBody({required this.provider, required this.showThumbnails});

  final TransactionFormControllerProvider provider;
  final bool showThumbnails;

  @override
  ConsumerState<_AttachmentsBody> createState() => _AttachmentsBodyState();
}

class _AttachmentsBodyState extends ConsumerState<_AttachmentsBody> {
  String? _error;

  Future<void> _pick(Future<PickedAttachment?> Function(AttachmentPicker picker) pick, String deniedMessage) async {
    setState(() => _error = null);
    try {
      final file = await pick(ref.read(attachmentPickerProvider));
      if (file != null) ref.read(widget.provider.notifier).addAttachment(file);
    } on PlatformException {
      // Di solito è un permesso negato (fotocamera o foto).
      if (mounted) setState(() => _error = deniedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachments = ref.watch(widget.provider.select((s) => s.newAttachments));
    final canAdd = ref.watch(widget.provider.select((s) => s.canAddAttachment));
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showThumbnails && attachments.isNotEmpty) ...[
          Wrap(
            children: [
              for (final file in attachments)
                _Thumbnail(file: file, onRemove: () => ref.read(widget.provider.notifier).removeAttachment(file)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        _ActionButton(
          icon: Icons.photo_camera_outlined,
          label: 'Scatta una foto',
          onTap: canAdd
              ? () => _pick(
                  (picker) => picker.takePhoto(),
                  'Accesso alla fotocamera negato. Puoi consentirlo nelle Impostazioni del telefono.',
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        _ActionButton(
          icon: Icons.image_outlined,
          label: 'Scegli dalla galleria',
          onTap: canAdd
              ? () => _pick(
                  (picker) => picker.pickFromGallery(),
                  'Accesso alle foto negato. Puoi consentirlo nelle Impostazioni del telefono.',
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        _ActionButton(
          icon: Icons.description_outlined,
          label: 'Scegli un file (PDF, immagine)',
          onTap: canAdd ? () => _pick((picker) => picker.pickFile(), 'Non è stato possibile aprire il file.') : null,
        ),
        const SizedBox(height: AppSpacing.md),
        if (_error != null) ...[
          Text(_error!, style: textTheme.labelMedium?.copyWith(color: context.colors.danger)),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          canAdd
              ? 'Le foto vengono compresse prima del salvataggio. Max $maxAttachments allegati per movimento.'
              : 'Hai raggiunto il massimo di $maxAttachments allegati per movimento.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Fatto')),
      ],
    );
  }
}

/// Anteprima 76×76 con il pulsante di rimozione nell'angolo.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.file, required this.onRemove});

  final PickedAttachment file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final placeholder = Icon(
      file.isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
      size: 26,
      color: colors.neutral.onTint,
    );

    // Il riquadro esterno lascia spazio al pulsante nell'angolo: i tocchi fuori dai limiti
    // di uno Stack non arrivano ai suoi figli.
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 16,
            width: 76,
            height: 76,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.track,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(color: colors.borderStrong),
              ),
              child: file.isImage && file.previewPath != null
                  ? Image.file(
                      File(file.previewPath!),
                      fit: BoxFit.cover,
                      cacheWidth: 228,
                      errorBuilder: (_, _, _) => placeholder,
                    )
                  : Center(child: placeholder),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            child: Semantics(
              container: true,
              button: true,
              label: 'Rimuovi ${file.name}',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.neutral.fill,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 2),
                    ),
                    child: Icon(Icons.close_rounded, size: 14, color: colors.neutral.onFill),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(14);
    final color = onTap == null ? colors.textMuted : colors.text;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
