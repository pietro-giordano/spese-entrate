import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Un'opzione di [AppSegmented].
class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.selectedTone});

  final T value;
  final String label;

  /// Colore pieno quando è attivo (es. Spesa/Entrata). Se null: superficie in rilievo.
  final ColorTone? selectedTone;
}

/// Dimensione: [large] per la scelta del tipo nell'inserimento, [regular] per tutto il resto.
enum AppSegmentedSize { regular, large }

/// Selettore a segmenti su un binario grigio (scelta singola).
///
/// È generico su `T`: il valore può essere un enum, una stringa, ecc.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.size = AppSegmentedSize.regular,
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final AppSegmentedSize size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLarge = size == AppSegmentedSize.large;
    final textStyle = isLarge ? Theme.of(context).textTheme.labelLarge : Theme.of(context).textTheme.labelMedium;

    return Container(
      decoration: BoxDecoration(color: colors.track, borderRadius: BorderRadius.circular(isLarge ? 14 : 12)),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++)
            Expanded(
              child: _SegmentButton(
                label: segments[i].label,
                selected: segments[i].value == selected,
                tone: segments[i].selectedTone,
                height: isLarge ? 44 : 38,
                radius: isLarge ? 11 : 9,
                textStyle: textStyle,
                // Il padding fa parte dell'area toccabile: 38 + 8 = 46 px ≥ 44.
                padding: EdgeInsets.fromLTRB(i == 0 ? 4 : 2, 4, i == segments.length - 1 ? 4 : 2, 4),
                onTap: () => onChanged(segments[i].value),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.tone,
    required this.height,
    required this.radius,
    required this.textStyle,
    required this.padding,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ColorTone? tone;
  final double height;
  final double radius;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final Color background;
    final Color foreground;
    if (!selected) {
      background = Colors.transparent;
      foreground = colors.textMuted;
    } else if (tone != null) {
      background = tone!.fill;
      foreground = tone!.onFill;
    } else {
      background = colors.surfaceRaised;
      foreground = colors.text;
    }

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: padding,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: selected && tone == null ? colors.raisedShadow : null,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle?.copyWith(color: foreground, fontWeight: selected ? FontWeight.w800 : FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
