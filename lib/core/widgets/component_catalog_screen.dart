import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'amount_text.dart';
import 'app_bottom_sheet.dart';
import 'app_chip.dart';
import 'app_list_row.dart';
import 'app_segmented.dart';
import 'app_switch.dart';
import 'section_label.dart';

/// Catalogo del design system, raggiungibile solo in debug.
/// Il selettore in alto applica il tema chiaro o scuro solo a questa schermata.
class ComponentCatalogScreen extends StatefulWidget {
  const ComponentCatalogScreen({super.key});

  @override
  State<ComponentCatalogScreen> createState() => _ComponentCatalogScreenState();
}

enum _TxType { expense, income, transfer }

class _ComponentCatalogScreenState extends State<ComponentCatalogScreen> {
  late Brightness _brightness = MediaQuery.platformBrightnessOf(context);
  _TxType _type = _TxType.expense;
  String _filterType = 'all';
  String _period = 'month';
  String _category = 'Spesa alimentare';
  final Set<String> _labels = {'#casa'};
  final Set<String> _wallets = {'Contanti'};
  bool _biometric = true;
  bool _transfers = false;
  String _sheetWallet = 'Conto corrente';

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      // Builder fornisce un context "sotto" Theme, così context.colors legge il tema scelto qui.
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogo componenti')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 40),
        children: [
          AppSegmented<Brightness>(
            segments: const [
              AppSegment(value: Brightness.light, label: 'Chiaro'),
              AppSegment(value: Brightness.dark, label: 'Scuro'),
            ],
            selected: _brightness,
            onChanged: (value) => setState(() => _brightness = value),
          ),

          _section('Colori di dominio'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ToneSwatch(name: 'Spesa', tone: colors.expense),
              _ToneSwatch(name: 'Entrata', tone: colors.income),
              _ToneSwatch(name: 'Neutro', tone: colors.neutral),
              _ToneSwatch(name: 'Liquidità', tone: colors.liquidity),
              _ToneSwatch(name: 'Risparmi', tone: colors.savings),
              _ToneSwatch(name: 'Investimenti', tone: colors.investments),
            ],
          ),

          _section('Tipografia'),
          Text('Profilo e impostazioni', style: textTheme.headlineMedium),
          Text('Titolo pannello', style: textTheme.titleLarge),
          Text('Titolo riga', style: textTheme.titleSmall),
          Text('Testo normale del corpo', style: textTheme.bodyLarge),
          Text('Testo secondario', style: textTheme.bodySmall),

          _section('SectionLabel'),
          const SectionLabel('Categorie', trailing: '2 selezionate'),

          _section('AppSegmented'),
          AppSegmented<_TxType>(
            size: AppSegmentedSize.large,
            segments: [
              AppSegment(value: _TxType.expense, label: 'Spesa', selectedTone: colors.expense),
              AppSegment(value: _TxType.income, label: 'Entrata', selectedTone: colors.income),
              AppSegment(value: _TxType.transfer, label: 'Trasferimento', selectedTone: colors.neutral),
            ],
            selected: _type,
            onChanged: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSegmented<String>(
            segments: const [
              AppSegment(value: 'all', label: 'Tutti'),
              AppSegment(value: 'expense', label: 'Spese'),
              AppSegment(value: 'income', label: 'Entrate'),
            ],
            selected: _filterType,
            onChanged: (value) => setState(() => _filterType = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSegmented<String>(
            segments: const [
              AppSegment(value: 'day', label: 'Giorno'),
              AppSegment(value: 'week', label: 'Sett.'),
              AppSegment(value: 'month', label: 'Mese'),
              AppSegment(value: 'year', label: 'Anno'),
              AppSegment(value: 'custom', label: 'Periodo'),
            ],
            selected: _period,
            onChanged: (value) => setState(() => _period = value),
          ),

          _section('AppChip · categoria'),
          Wrap(
            spacing: 6,
            children: [
              for (final name in ['Spesa alimentare', 'Casa', 'Trasporti', 'Ristoranti', 'Svago'])
                AppChip(
                  label: name,
                  selected: name == _category,
                  selectedTone: _type == _TxType.income ? colors.income : colors.expense,
                  onTap: () => setState(() => _category = name),
                ),
            ],
          ),
          _section('AppChip · label (multiple)'),
          Wrap(
            spacing: 6,
            children: [
              for (final name in ['#casa', '#lavoro', '#ricorrente', '#vacanze'])
                AppChip(
                  label: name,
                  shape: AppChipShape.label,
                  selected: _labels.contains(name),
                  onTap: () => setState(() => _labels.contains(name) ? _labels.remove(name) : _labels.add(name)),
                ),
            ],
          ),
          _section('AppChip · filtro con spunta'),
          Wrap(
            spacing: 6,
            children: [
              for (final name in ['Conto corrente', 'Contanti', 'Carta prepagata'])
                AppChip(
                  label: name,
                  showCheck: true,
                  selected: _wallets.contains(name),
                  onTap: () => setState(() => _wallets.contains(name) ? _wallets.remove(name) : _wallets.add(name)),
                ),
            ],
          ),

          _section('AppSwitch'),
          Row(
            children: [
              Expanded(child: Text('Mostra anche i trasferimenti', style: textTheme.labelMedium)),
              AppSwitch(
                value: _transfers,
                semanticLabel: 'Mostra trasferimenti',
                onChanged: (value) => setState(() => _transfers = value),
              ),
              const SizedBox(width: AppSpacing.md),
              const AppSwitch(value: true, onChanged: null, semanticLabel: 'Disattivato'),
            ],
          ),

          _section('AppListRow in AppListGroup'),
          AppListGroup(
            children: [
              AppListRow(title: 'Valuta', value: 'Euro (€)', onTap: () {}),
              AppListRow(title: 'Portafoglio per le uscite', value: 'Conto corrente', onTap: () {}),
              AppListRow(
                title: 'Sblocco con Face ID',
                subtitle: 'Richiesto all\'apertura dell\'app',
                onTap: () => setState(() => _biometric = !_biometric),
                trailing: AppSwitch(value: _biometric, onChanged: (value) => setState(() => _biometric = value)),
              ),
              AppListRow(
                title: 'Spesa Esselunga',
                subtitle: 'Spesa alimentare · #casa',
                leading: _TintIcon(tone: colors.expense, icon: Icons.shopping_cart_outlined),
                trailing: const AmountText(6420, kind: AmountKind.expense, colored: false),
              ),
              AppListRow(
                title: 'Stipendio',
                subtitle: 'Stipendio',
                leading: _TintIcon(tone: colors.income, icon: Icons.work_outline_rounded),
                trailing: const AmountText(185000, kind: AmountKind.income),
              ),
            ],
          ),

          _section('AmountText'),
          Center(
            child: AmountText(
              6420,
              kind: _type == _TxType.income ? AmountKind.income : AmountKind.expense,
              style: textTheme.displaySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              AmountText(123456, kind: AmountKind.expense),
              AmountText(98000, kind: AmountKind.income),
              AmountText(-1500),
              AmountText(2972285),
            ],
          ),

          _section('AppBottomSheet e pulsanti'),
          FilledButton(onPressed: () => _openWalletSheet(context), child: const Text('Apri pannello')),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () {}, child: const Text('Esci')),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: colors.danger),
            child: const Text('Elimina account e dati'),
          ),
          const SizedBox(height: AppSpacing.md),
          const TextField(decoration: InputDecoration(hintText: 'Nota (facoltativa)')),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.sm),
      child: SectionLabel(title),
    );
  }

  Future<void> _openWalletSheet(BuildContext context) async {
    const wallets = ['Conto corrente', 'Contanti', 'Carta prepagata'];
    final picked = await AppBottomSheet.show<String>(
      context,
      title: 'Paga da',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppListGroup(
            children: [
              for (final name in wallets)
                AppListRow(
                  title: name,
                  subtitle: '€ 1.234,56',
                  trailing: Icon(
                    name == _sheetWallet ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: sheetContext.colors.text,
                  ),
                  onTap: () => Navigator.pop(sheetContext, name),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Questa scelta vale solo per questo movimento.', style: Theme.of(sheetContext).textTheme.bodySmall),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Fatto')),
        ],
      ),
    );
    if (picked != null) setState(() => _sheetWallet = picked);
  }
}

class _ToneSwatch extends StatelessWidget {
  const _ToneSwatch({required this.name, required this.tone});

  final String name;
  final ColorTone tone;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return SizedBox(
      width: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.fill,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Text(name, style: labelStyle?.copyWith(color: tone.onFill)),
          ),
          Container(
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.tint,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Text('tinta', style: labelStyle?.copyWith(color: tone.onTint)),
          ),
        ],
      ),
    );
  }
}

class _TintIcon extends StatelessWidget {
  const _TintIcon({required this.tone, required this.icon});

  final ColorTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 18, color: tone.onTint),
    );
  }
}
