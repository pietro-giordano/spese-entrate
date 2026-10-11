import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/dashed_border.dart';

/// Un riquadro della griglia allegati (salvato o appena aggiunto).
class AttachmentGridItem {
  const AttachmentGridItem({required this.name, required this.mimeType, required this.onRemove, this.onOpen});

  final String name;
  final String mimeType;
  final VoidCallback onRemove;

  /// Apre l'allegato (solo per quelli già salvati); null = riquadro non toccabile.
  final VoidCallback? onOpen;
}

/// Griglia 4 colonne di allegati con rimozione e un riquadro "+" per aggiungerne.
class AttachmentsGrid extends StatelessWidget {
  const AttachmentsGrid({super.key, required this.items, required this.onAdd});

  final List<AttachmentGridItem> items;

  /// Null quando si è al massimo: il "+" non compare.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    const columns = 4;
    const gap = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox.square(
                dimension: side,
                child: _Tile(item: item),
              ),
            if (onAdd != null)
              SizedBox.square(
                dimension: side,
                child: _AddTile(onTap: onAdd!),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});

  final AttachmentGridItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPdf = item.mimeType == 'application/pdf';
    final extension = p.extension(item.name).replaceFirst('.', '').toUpperCase();

    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            container: true,
            button: item.onOpen != null,
            label: item.onOpen != null ? 'Apri ${item.name}' : item.name,
            excludeSemantics: true,
            child: Material(
              color: colors.track,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.field),
                side: BorderSide(color: colors.borderStrong),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.field),
                onTap: item.onOpen,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPdf ? Icons.description_outlined : Icons.image_outlined,
                      size: 24,
                      color: colors.neutral.onTint,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      extension.isEmpty ? 'FILE' : extension,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(fontSize: 10, color: colors.neutral.onTint),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Il pulsante resta dentro il riquadro: i tocchi fuori da uno Stack non arrivano.
        Positioned(
          top: 0,
          right: 0,
          width: 36,
          height: 36,
          child: Semantics(
            container: true,
            button: true,
            label: 'Rimuovi ${item.name}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: item.onRemove,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.neutral.fill,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.background, width: 2),
                  ),
                  child: Icon(Icons.close_rounded, size: 12, color: colors.neutral.onFill),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: 'Aggiungi allegato',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: CustomPaint(
          painter: DashedBorderPainter(color: colors.textMuted, radius: AppRadius.field),
          child: Center(child: Icon(Icons.add_rounded, size: 22, color: colors.neutral.onTint)),
        ),
      ),
    );
  }
}
