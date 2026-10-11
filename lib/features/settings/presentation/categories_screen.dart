import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/category_palette.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/label.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../domain/repositories/label_repository.dart';
import '../application/category_label_actions.dart';
import '../application/settings_providers.dart';

enum _Tab { categories, labels }

String _usageText(int count) => switch (count) {
  0 => 'Nessun movimento',
  1 => '1 movimento',
  _ => '$count movimenti',
};

/// Categorie e label: elenco, riordino delle categorie, creazione e modifica.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  var _tab = _Tab.categories;
  var _kind = CategoryKind.expense;

  /// Ordine mostrato durante il trascinamento, finché il database non conferma il nuovo.
  List<Category>? _pendingOrder;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final allCategories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final labels = ref.watch(labelsProvider).value ?? const <Label>[];
    final categoryUsage = ref.watch(categoryUsageProvider).value ?? const <String, int>{};
    final labelUsage = ref.watch(labelUsageProvider).value ?? const <String, int>{};

    final ofKind = allCategories.where((c) => c.kind == _kind);
    final active = _pendingOrder ?? ofKind.where((c) => !c.isArchived).toList();
    final archived = ofKind.where((c) => c.isArchived).toList();
    final isCategories = _tab == _Tab.categories;

    final header = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        isCategories
            ? 'Tieni premuto e trascina per riordinare: l\'ordine è quello dell\'inserimento rapido.'
            : 'Le label sono condivise tra spese ed entrate. Un movimento può averne più di una.',
        style: textTheme.bodySmall,
      ),
    );
    final addButton = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: _DashedButton(
        label: isCategories ? '+ Nuova categoria' : '+ Nuova label',
        onTap: () => isCategories ? _editCategory(null, allCategories, 0) : _editLabel(null, labels, 0),
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 14, AppSpacing.screen, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppIconButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Indietro',
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text('Categorie e label', style: textTheme.headlineMedium),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppSegmented<_Tab>(
                    segments: const [
                      AppSegment(value: _Tab.categories, label: 'Categorie'),
                      AppSegment(value: _Tab.labels, label: 'Label'),
                    ],
                    selected: _tab,
                    onChanged: (tab) => setState(() => _tab = tab),
                  ),
                  if (isCategories)
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final (kind, label) in [(CategoryKind.expense, 'Spese'), (CategoryKind.income, 'Entrate')])
                          AppChip(label: label, selected: _kind == kind, onTap: () => setState(() => _kind = kind)),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(
              child: isCategories
                  ? ReorderableListView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.xs,
                        AppSpacing.screen,
                        AppSpacing.xl + bottomSystemInset(context),
                      ),
                      header: header,
                      footer: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          addButton,
                          if (archived.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xl),
                            const SectionLabel('Archiviate', indent: true),
                            const SizedBox(height: AppSpacing.sm),
                            for (final (i, category) in archived.indexed)
                              _ItemRow(
                                key: ValueKey('archived-${category.id}'),
                                name: category.name,
                                color: Color(category.color),
                                subtitle: 'Archiviata · ${_usageText(categoryUsage[category.id] ?? 0)}',
                                position: _position(i, archived.length),
                                draggable: false,
                                onEdit: () => _editCategory(category, allCategories, categoryUsage[category.id] ?? 0),
                              ),
                          ],
                        ],
                      ),
                      onReorderItem: (oldIndex, newIndex) => _reorder(active, oldIndex, newIndex),
                      children: [
                        for (final (i, category) in active.indexed)
                          _ItemRow(
                            key: ValueKey(category.id),
                            name: category.name,
                            color: Color(category.color),
                            subtitle: _usageText(categoryUsage[category.id] ?? 0),
                            position: _position(i, active.length),
                            draggable: true,
                            onEdit: () => _editCategory(category, allCategories, categoryUsage[category.id] ?? 0),
                          ),
                      ],
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.xs,
                        AppSpacing.screen,
                        AppSpacing.xl + bottomSystemInset(context),
                      ),
                      children: [
                        header,
                        if (labels.isEmpty)
                          Text(
                            'Non hai ancora creato label.',
                            style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                          ),
                        // Le label non hanno un ordine proprio: sono in ordine alfabetico.
                        for (final (i, label) in labels.indexed)
                          _ItemRow(
                            key: ValueKey(label.id),
                            name: '#${label.name}',
                            color: Color(label.color),
                            subtitle: _usageText(labelUsage[label.id] ?? 0),
                            position: _position(i, labels.length),
                            draggable: false,
                            onEdit: () => _editLabel(label, labels, labelUsage[label.id] ?? 0),
                          ),
                        addButton,
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static _Position _position(int index, int length) => (first: index == 0, last: index == length - 1);

  Future<void> _reorder(List<Category> current, int oldIndex, int newIndex) async {
    // onReorderItem dà già l'indice finale, calcolato dopo aver tolto l'elemento trascinato.
    final ordered = [...current];
    ordered.insert(newIndex, ordered.removeAt(oldIndex));
    setState(() => _pendingOrder = ordered);
    try {
      await ref.read(categoryLabelActionsProvider).reorderCategories(ordered);
    } finally {
      if (mounted) setState(() => _pendingOrder = null);
    }
  }

  Future<void> _editCategory(Category? category, List<Category> all, int usage) async {
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(categoryLabelActionsProvider);
    final kind = category?.kind ?? _kind;
    final result = await _showEditor(
      context,
      isCategory: true,
      existingName: category?.name,
      existingColor: category?.color,
      usage: usage,
      isArchived: category?.isArchived ?? false,
      mergeTargets: [
        for (final c in all)
          if (c.kind == kind && !c.isArchived && c.id != category?.id) Choice(value: c.id, label: c.name),
      ],
      onSave: (name, color) async {
        try {
          if (category == null) {
            await actions.createCategory(name: name, color: color, kind: kind);
          } else {
            await actions.updateCategory(category.copyWith(name: name, color: color));
          }
          return null;
        } on DuplicateCategoryNameException {
          // Lo stesso nome va bene solo nell'altro tipo (es. "Regali" di spesa e di entrata).
          return kind == CategoryKind.expense
              ? 'Esiste già una categoria di spesa con questo nome'
              : 'Esiste già una categoria di entrata con questo nome';
        }
      },
    );
    if (result == null || category == null) return;
    switch (result) {
      case _EditorResult.archive:
        await actions.archiveCategory(category);
        messenger.showSnackBar(
          SnackBar(
            content: Text('«${category.name}» archiviata'),
            action: SnackBarAction(label: 'Annulla', onPressed: () => actions.restoreCategory(category)),
          ),
        );
      case _EditorResult.restore:
        await actions.restoreCategory(category);
      case _EditorResult.delete:
        break;
      case _EditorMerge(:final targetId):
        final target = all.firstWhere((c) => c.id == targetId);
        await actions.mergeCategory(category, target);
        messenger.showSnackBar(SnackBar(content: Text('«${category.name}» unita a «${target.name}»')));
    }
  }

  Future<void> _editLabel(Label? label, List<Label> all, int usage) async {
    final messenger = ScaffoldMessenger.of(context);
    final actions = ref.read(categoryLabelActionsProvider);
    final result = await _showEditor(
      context,
      isCategory: false,
      existingName: label?.name,
      existingColor: label?.color,
      usage: usage,
      isArchived: false,
      mergeTargets: [
        for (final l in all)
          if (l.id != label?.id) Choice(value: l.id, label: '#${l.name}'),
      ],
      onSave: (name, color) async {
        try {
          if (label == null) {
            await actions.createLabel(name: name, color: color);
          } else {
            await actions.updateLabel(label.copyWith(name: name, color: color));
          }
          return null;
        } on DuplicateLabelNameException {
          return 'Esiste già una label con questo nome';
        } on DeletedLabelException {
          return 'Questa label è stata eliminata';
        }
      },
    );
    if (result == null || label == null) return;
    switch (result) {
      case _EditorResult.delete:
        await actions.deleteLabel(label);
        messenger.showSnackBar(SnackBar(content: Text('#${label.name} eliminata')));
      case _EditorMerge(:final targetId):
        final target = all.firstWhere((l) => l.id == targetId);
        await actions.mergeLabel(label, target);
        messenger.showSnackBar(SnackBar(content: Text('#${label.name} unita a #${target.name}')));
      case _EditorResult.archive || _EditorResult.restore:
        break;
    }
  }
}

typedef _Position = ({bool first, bool last});

/// Esito del pannello di modifica (oltre al semplice salvataggio, che avviene nel pannello).
sealed class _EditorOutcome {
  const _EditorOutcome();
}

enum _EditorResult implements _EditorOutcome { archive, restore, delete }

class _EditorMerge implements _EditorOutcome {
  const _EditorMerge(this.targetId);

  final String targetId;
}

/// Pannello di modifica di categoria o label. [onSave] restituisce un messaggio d'errore o null.
Future<_EditorOutcome?> _showEditor(
  BuildContext context, {
  required bool isCategory,
  required String? existingName,
  required int? existingColor,
  required int usage,
  required bool isArchived,
  required List<Choice<String>> mergeTargets,
  required Future<String?> Function(String name, int color) onSave,
}) {
  final isNew = existingName == null;
  return AppBottomSheet.show<_EditorOutcome>(
    context,
    title: switch ((isNew, isCategory)) {
      (true, true) => 'Nuova categoria',
      (true, false) => 'Nuova label',
      (false, true) => 'Modifica categoria',
      (false, false) => 'Modifica label',
    },
    titleTrailing: Builder(
      builder: (context) =>
          IconButton(icon: const Icon(Icons.close_rounded), tooltip: 'Chiudi', onPressed: () => Navigator.pop(context)),
    ),
    builder: (_) => _Editor(
      isCategory: isCategory,
      existingName: existingName,
      existingColor: existingColor,
      usage: usage,
      isArchived: isArchived,
      mergeTargets: mergeTargets,
      onSave: onSave,
    ),
  );
}

class _Editor extends StatefulWidget {
  const _Editor({
    required this.isCategory,
    required this.existingName,
    required this.existingColor,
    required this.usage,
    required this.isArchived,
    required this.mergeTargets,
    required this.onSave,
  });

  final bool isCategory;
  final String? existingName;
  final int? existingColor;
  final int usage;
  final bool isArchived;
  final List<Choice<String>> mergeTargets;
  final Future<String?> Function(String name, int color) onSave;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final _name = TextEditingController(text: widget.existingName ?? '');
  late int _color = widget.existingColor ?? categoryPalette.first;
  String? _error;
  var _saving = false;

  bool get _isNew => widget.existingName == null;
  String get _what => widget.isCategory ? 'categoria' : 'label';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Inserisci un nome');
      return;
    }
    setState(() => _saving = true);
    final error = await widget.onSave(_name.text.trim(), _color);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.pop(context);
  }

  Future<void> _merge() async {
    final targetId = await showChoiceSheet<String>(
      context,
      title: 'Unisci in…',
      choices: widget.mergeTargets,
      selected: null,
    );
    if (targetId == null || !mounted) return;
    final target = widget.mergeTargets.firstWhere((c) => c.value == targetId).label;
    final name = widget.isCategory ? widget.existingName! : '#${widget.existingName}';
    final confirmed = await showConfirmDialog(
      context,
      title: 'Unire «$name» in «$target»?',
      message:
          '${_usageText(widget.usage)} ${widget.usage == 1 ? 'passa' : 'passano'} a «$target», '
          'anche nelle ricorrenze. «$name» verrà eliminata.',
      confirmLabel: 'Unisci',
    );
    if (confirmed && mounted) Navigator.pop(context, _EditorMerge(targetId));
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminare #${widget.existingName}?',
      message: 'La label viene tolta da ${_usageText(widget.usage).toLowerCase()}. I movimenti restano.',
      confirmLabel: 'Elimina',
      destructive: true,
    );
    if (confirmed && mounted) Navigator.pop(context, _EditorResult.delete);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Nome'),
        const SizedBox(height: 6),
        TextField(
          controller: _name,
          autofocus: _isNew,
          textCapitalization: widget.isCategory ? TextCapitalization.sentences : TextCapitalization.none,
          decoration: InputDecoration(
            hintText: widget.isCategory ? 'Es. Palestra' : 'Es. vacanze',
            prefixText: widget.isCategory ? null : '#',
            errorText: _error,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionLabel('Colore'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final (i, color) in categoryPalette.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  container: true,
                  button: true,
                  selected: color == _color,
                  label: 'Colore ${i + 1}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => setState(() => _color = color),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: AppSizes.minTouchTarget,
                      child: Center(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(color),
                            borderRadius: BorderRadius.circular(10),
                            border: color == _color ? Border.all(color: colors.surface, width: 3) : null,
                            boxShadow: color == _color ? [BoxShadow(color: colors.text, spreadRadius: 2)] : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (!_isNew) ...[
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel('Movimenti collegati'),
          const SizedBox(height: 6),
          Text(
            widget.usage == 0
                ? 'Nessun movimento usa questa $_what.'
                : widget.isCategory
                ? '${_usageText(widget.usage)} usano questa categoria. Per toglierla puoi unirla a un\'altra '
                      'oppure archiviarla: i movimenti esistenti restano invariati.'
                : '${_usageText(widget.usage)} usano questa label. Puoi unirla a un\'altra oppure eliminarla.',
            style: textTheme.labelMedium?.copyWith(
              color: colors.neutral.onTint,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.minTouchTarget)),
                  onPressed: widget.mergeTargets.isEmpty || widget.isArchived ? null : _merge,
                  child: const Text('Unisci in…'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
                    foregroundColor: widget.isArchived ? null : colors.danger,
                  ),
                  onPressed: () {
                    if (!widget.isCategory) {
                      _delete();
                    } else {
                      Navigator.pop(context, widget.isArchived ? _EditorResult.restore : _EditorResult.archive);
                    }
                  },
                  child: Text(widget.isCategory ? (widget.isArchived ? 'Ripristina' : 'Archivia') : 'Elimina'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          onPressed: _saving ? null : _save,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

/// Riga dell'elenco: colore con iniziale, nome, uso, modifica e maniglia di trascinamento.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.name,
    required this.color,
    required this.subtitle,
    required this.position,
    required this.draggable,
    required this.onEdit,
  });

  final String name;
  final Color color;
  final String subtitle;
  final _Position position;
  final bool draggable;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    // Ogni riga disegna il suo pezzo di card, così il riordino non rompe bordi e angoli.
    // Il bordo è uno sfondo di 1 px attorno alla riga: Flutter non ammette angoli arrotondati
    // su un Border con lati di colori diversi (bordo esterno e divisore).
    const radius = Radius.circular(AppRadius.card);
    const innerRadius = Radius.circular(AppRadius.card - 1);
    BorderRadius rounded(Radius r) =>
        BorderRadius.vertical(top: position.first ? r : Radius.zero, bottom: position.last ? r : Radius.zero);

    return Container(
      padding: EdgeInsets.fromLTRB(1, position.first ? 1 : 0, 1, position.last ? 1 : 0),
      decoration: BoxDecoration(color: colors.border, borderRadius: rounded(radius)),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: rounded(innerRadius)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!position.first) const Divider(),
            InkWell(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          name.replaceFirst('#', '').characters.first.toUpperCase(),
                          // Testo bianco: i colori della tavolozza sono tutti scuri abbastanza.
                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: colors.switchThumb),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleSmall),
                          const SizedBox(height: 1),
                          Text(subtitle, style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 20, color: colors.neutral.onTint),
                      tooltip: 'Modifica $name',
                      onPressed: onEdit,
                    ),
                    SizedBox(
                      width: 24,
                      child: draggable
                          ? ExcludeSemantics(
                              child: Icon(Icons.drag_indicator_rounded, size: 20, color: colors.textMuted),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulsante a tutta larghezza con bordo tratteggiato ("+ Nuova categoria").
class _DashedButton extends StatelessWidget {
  const _DashedButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(AppRadius.button);
    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: CustomPaint(
          painter: DashedBorderPainter(color: colors.textMuted, radius: AppRadius.button),
          child: SizedBox(
            height: 52,
            child: Center(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
    );
  }
}
