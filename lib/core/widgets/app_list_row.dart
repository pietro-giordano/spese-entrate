import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Riga di lista: titolo, sottotitolo e valore opzionali, chevron se toccabile.
///
/// Per un interruttore passa un [AppSwitch] come [trailing].
/// Va messa dentro un [AppListGroup] (card con divisori) o un'altra superficie Material.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.value,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;

  /// Al posto di [subtitle], quando il sottotitolo è un widget (es. un saldo nascondibile).
  /// Riceve già lo stile del sottotitolo.
  final Widget? subtitleWidget;

  /// Testo grigio a destra (es. "Euro (€)").
  final String? value;
  final Widget? leading;

  /// Sostituisce il chevron (es. un interruttore o un importo).
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: subtitle == null && subtitleWidget == null ? 52 : 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.md)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    if (subtitleWidget != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle.merge(style: textTheme.bodySmall, child: subtitleWidget!),
                    ] else if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 10),
                // Il titolo ha la precedenza: il valore resta accanto al chevron, al massimo 160 px,
                // e oltre si accorcia con i puntini.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.chevron_right_rounded, size: 20, color: colors.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Card bianca con bordo che impila righe separate da divisori.
class AppListGroup extends StatelessWidget {
  const AppListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(), children[i]],
        ],
      ),
    );
  }
}
