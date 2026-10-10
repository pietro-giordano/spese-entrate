import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../domain/models/attachment.dart';
import '../application/attachment_actions.dart';

/// Immagini allegate a schermo intero: si scorre tra le immagini, si ingrandisce con due dita
/// (doppio tocco per tornare alla dimensione normale) e si condivide quella mostrata.
class AttachmentViewerScreen extends ConsumerStatefulWidget {
  const AttachmentViewerScreen({super.key, required this.images, this.initialIndex = 0});

  final List<Attachment> images;
  final int initialIndex;

  /// Apre il visualizzatore sopra la schermata corrente.
  static Future<void> show(BuildContext context, List<Attachment> images, {int initialIndex = 0}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => AttachmentViewerScreen(images: images, initialIndex: initialIndex),
        ),
      );

  @override
  ConsumerState<AttachmentViewerScreen> createState() => _AttachmentViewerScreenState();
}

class _AttachmentViewerScreenState extends ConsumerState<AttachmentViewerScreen> {
  late final _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  /// Con un'immagine ingrandita il trascinamento sposta l'immagine, non cambia pagina.
  var _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    final problem = await ref.read(attachmentActionsProvider).share(widget.images[_index]);
    if (problem != null) messenger.showSnackBar(SnackBar(content: Text(problem.message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = widget.images.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 14, AppSpacing.screen, 10),
              child: Row(
                children: [
                  AppIconButton(icon: Icons.close_rounded, tooltip: 'Chiudi', onPressed: () => Navigator.pop(context)),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        count > 1 ? '${_index + 1} di $count' : 'Allegato',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium,
                      ),
                    ),
                  ),
                  AppIconButton(icon: Icons.ios_share_rounded, tooltip: 'Condividi', onPressed: _share),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
                itemCount: count,
                onPageChanged: (index) => setState(() {
                  _index = index;
                  _zoomed = false;
                }),
                itemBuilder: (context, index) => _ZoomableImage(
                  key: ValueKey(widget.images[index].id),
                  attachment: widget.images[index],
                  onZoomChanged: (zoomed) {
                    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableImage extends ConsumerStatefulWidget {
  const _ZoomableImage({super.key, required this.attachment, required this.onZoomChanged});

  final Attachment attachment;
  final ValueChanged<bool> onZoomChanged;

  @override
  ConsumerState<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends ConsumerState<_ZoomableImage> {
  final _transform = TransformationController();
  late final Future<(File?, AttachmentProblem?)> _file = ref.read(attachmentActionsProvider).resolve(widget.attachment);

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _reset() {
    _transform.value = Matrix4.identity();
    widget.onZoomChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _file,
      builder: (context, snapshot) => switch (snapshot.data) {
        null => const SizedBox.shrink(),
        (_, final problem?) => _ImageProblem(message: problem.message),
        (final file?, _) => GestureDetector(
          onDoubleTap: _reset,
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 1,
            maxScale: 5,
            onInteractionEnd: (_) => widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.01),
            child: Center(
              child: Semantics(
                image: true,
                label: 'Immagine allegata',
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  // Un file che non è un'immagine valida: messaggio invece dell'errore.
                  errorBuilder: (_, _, _) =>
                      const _ImageProblem(message: 'Questa immagine non si può mostrare: il file è danneggiato.'),
                ),
              ),
            ),
          ),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _ImageProblem extends StatelessWidget {
  const _ImageProblem({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 40, color: colors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
