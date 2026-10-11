import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/bottom_action_bar.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_list_row.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/section_label.dart';
import '../../../data/device/app_info.dart';
import '../../../data/device/biometric_auth.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/app_settings.dart';
import '../../../domain/models/local_preferences.dart';
import '../../../domain/models/wallet.dart';
import '../../transactions/application/transaction_list_providers.dart';
import '../../wallets/application/balance_visibility.dart';
import '../../wallets/application/wallet_providers.dart';
import '../application/app_lock.dart';
import '../application/settings_providers.dart';

const _periodLabels = {
  PeriodType.day: 'Giorno',
  PeriodType.week: 'Settimana',
  PeriodType.month: 'Mese',
  PeriodType.year: 'Anno',
};

const _balancesOnOpenLabels = {
  BalancesOnOpen.visible: 'Sempre visibili',
  BalancesOnOpen.hidden: 'Sempre nascosti',
  BalancesOnOpen.remember: 'Ricorda l\'ultima scelta',
};

const _weekdays = ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];

/// Profilo e impostazioni.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _saveSettings(WidgetRef ref, AppSettings settings) =>
      ref.read(settingsRepositoryProvider).save(settings);

  Future<void> _savePreferences(WidgetRef ref, LocalPreferences preferences) =>
      ref.read(localPreferencesRepositoryProvider).save(preferences);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final preferences = ref.watch(localPreferencesProvider).value ?? const LocalPreferences();
    final wallets = (ref.watch(walletsProvider).value ?? const <Wallet>[]).where((w) => !w.isArchived).toList();
    String walletName(String? id) => wallets.firstWhereOrNull((w) => w.id == id)?.name ?? 'Nessuno';

    Future<void> pickDefaultWallet({required bool expenses}) async {
      final current = expenses ? settings.defaultExpenseWalletId : settings.defaultIncomeWalletId;
      final picked = await showChoiceSheet<String>(
        context,
        title: expenses ? 'Portafoglio per le uscite' : 'Portafoglio per le entrate',
        choices: [for (final w in wallets) Choice(value: w.id, label: w.name)],
        selected: current,
        hint: 'È quello proposto nell\'inserimento rapido. Ce n\'è uno solo per tipo.',
      );
      if (picked == null) return;
      await _saveSettings(
        ref,
        expenses ? settings.copyWith(defaultExpenseWalletId: picked) : settings.copyWith(defaultIncomeWalletId: picked),
      );
    }

    Future<void> pickDefaultPeriod() async {
      final picked = await showChoiceSheet<PeriodType>(
        context,
        title: 'Vista predefinita',
        choices: [for (final MapEntry(:key, :value) in _periodLabels.entries) Choice(value: key, label: value)],
        selected: settings.defaultPeriod,
        hint: 'Il periodo con cui si apre la lista Movimenti.',
      );
      if (picked == null) return;
      await _saveSettings(ref, settings.copyWith(defaultPeriod: picked));
      // Si applica subito anche alla lista, non solo dal prossimo avvio.
      ref
          .read(selectedPeriodProvider.notifier)
          .changeType(picked, today: ref.read(todayProvider), weekStart: settings.weekStart);
    }

    Future<void> pickWeekStart() async {
      final picked = await showChoiceSheet<int>(
        context,
        title: 'La settimana inizia di',
        choices: [for (final (i, day) in _weekdays.indexed) Choice(value: i + 1, label: day)],
        selected: settings.weekStart,
      );
      if (picked == null) return;
      await _saveSettings(ref, settings.copyWith(weekStart: picked));
      // Una settimana già mostrata si ricalcola con il nuovo primo giorno.
      final period = ref.read(selectedPeriodProvider);
      if (period.type == PeriodType.week) {
        ref
            .read(selectedPeriodProvider.notifier)
            .set(Period.containing(PeriodType.week, period.start, weekStart: picked));
      }
    }

    Future<void> pickBalancesOnOpen() async {
      final picked = await showChoiceSheet<BalancesOnOpen>(
        context,
        title: 'Saldi all\'apertura',
        choices: [for (final MapEntry(:key, :value) in _balancesOnOpenLabels.entries) Choice(value: key, label: value)],
        selected: preferences.balancesOnOpen,
        hint:
            'Gli importi dei movimenti restano sempre visibili. Con «Sempre nascosti» i saldi si '
            'nascondono di nuovo anche quando torni nell\'app dopo almeno 1 minuto.',
      );
      if (picked == null) return;
      await ref.read(balancesHiddenProvider.notifier).setMode(picked);
    }

    Future<void> toggleBiometricLock(bool enable) async {
      final messenger = ScaffoldMessenger.of(context);
      if (!enable) {
        await _savePreferences(ref, preferences.copyWith(biometricLock: false));
        ref.read(appLockProvider.notifier).release();
        return;
      }
      final auth = ref.read(biometricAuthProvider);
      if (!await auth.isAvailable()) {
        messenger.showSnackBar(const SnackBar(content: Text('Su questo telefono la biometria non è disponibile')));
        return;
      }
      // Prima di attivarlo si verifica che funzioni, per non restare chiusi fuori.
      if (!await auth.authenticate('Conferma per attivare il blocco')) return;
      await _savePreferences(ref, preferences.copyWith(biometricLock: true));
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 14, AppSpacing.screen, 10),
              child: Row(
                children: [
                  AppIconButton(icon: Icons.chevron_left_rounded, tooltip: 'Indietro', onPressed: () => context.pop()),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text('Profilo e impostazioni', style: textTheme.headlineMedium),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  6,
                  AppSpacing.screen,
                  AppSpacing.xxl + bottomSystemInset(context),
                ),
                children: [
                  _ProfileCard(
                    preferences: preferences,
                    onEdit: () async {
                      final edited = await _showProfileSheet(context, preferences);
                      if (edited != null) await _savePreferences(ref, edited);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionLabel('Aspetto', indent: true),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Tema', style: textTheme.titleSmall),
                        const SizedBox(height: 10),
                        AppSegmented<AppThemeMode>(
                          segments: const [
                            AppSegment(value: AppThemeMode.system, label: 'Sistema'),
                            AppSegment(value: AppThemeMode.light, label: 'Chiaro'),
                            AppSegment(value: AppThemeMode.dark, label: 'Scuro'),
                          ],
                          selected: preferences.themeMode,
                          onChanged: (mode) => _savePreferences(ref, preferences.copyWith(themeMode: mode)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionLabel('Preferenze', indent: true),
                  const SizedBox(height: AppSpacing.sm),
                  AppListGroup(
                    children: [
                      // Una sola valuta per ora: il multi-valuta arriverà più avanti.
                      const AppListRow(title: 'Valuta', value: 'Euro (€)'),
                      AppListRow(
                        title: 'Portafoglio per le uscite',
                        value: walletName(settings.defaultExpenseWalletId),
                        onTap: () => pickDefaultWallet(expenses: true),
                      ),
                      AppListRow(
                        title: 'Portafoglio per le entrate',
                        value: walletName(settings.defaultIncomeWalletId),
                        onTap: () => pickDefaultWallet(expenses: false),
                      ),
                      AppListRow(
                        title: 'Vista predefinita',
                        value: _periodLabels[settings.defaultPeriod] ?? 'Mese',
                        onTap: pickDefaultPeriod,
                      ),
                      AppListRow(
                        title: 'La settimana inizia di',
                        value: _weekdays[(settings.weekStart - 1).clamp(0, 6)],
                        onTap: pickWeekStart,
                      ),
                      AppListRow(title: 'Movimenti ricorrenti', onTap: () => context.push(AppRoutes.recurring)),
                      AppListRow(title: 'Categorie e label', onTap: () => context.push(AppRoutes.categories)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionLabel('Sicurezza', indent: true),
                  const SizedBox(height: AppSpacing.sm),
                  AppListGroup(
                    children: [
                      AppListRow(
                        title: 'Blocco con biometria',
                        subtitle: 'Chiede Face ID o impronta all\'apertura e dopo 1 minuto in background',
                        onTap: () => toggleBiometricLock(!preferences.biometricLock),
                        trailing: AppSwitch(
                          value: preferences.biometricLock,
                          semanticLabel: 'Blocco con biometria',
                          onChanged: toggleBiometricLock,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionLabel('Privacy', indent: true),
                  const SizedBox(height: AppSpacing.sm),
                  AppListGroup(
                    children: [
                      AppListRow(
                        title: 'Saldi all\'apertura',
                        subtitle: 'L\'occhio in Portafogli li mostra o li nasconde in tutta l\'app',
                        value: _balancesOnOpenLabels[preferences.balancesOnOpen],
                        onTap: pickBalancesOnOpen,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionLabel('Dati', indent: true),
                  const SizedBox(height: AppSpacing.sm),
                  AppListGroup(
                    children: [
                      AppListRow(
                        title: 'Backup ed esportazione',
                        subtitle: 'Esporta i movimenti in CSV',
                        onTap: () => context.push(AppRoutes.backup),
                      ),
                      AppListRow(
                        title: 'Importa da CSV',
                        subtitle: 'Movimenti da un file, con anteprima prima di salvare',
                        onTap: () => context.push(AppRoutes.import),
                      ),
                      AppListRow(
                        title: 'Storico importazioni',
                        subtitle: 'File importati e annullamento',
                        onTap: () => context.push(AppRoutes.imports),
                      ),
                      if (kDebugMode)
                        AppListRow(
                          title: 'Catalogo componenti',
                          subtitle: 'Solo in debug',
                          onTap: () => context.push(AppRoutes.componentCatalog),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const _VersionText(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.preferences, required this.onEdit});

  final LocalPreferences preferences;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final name = preferences.profileName;
    final borderRadius = BorderRadius.circular(AppRadius.cardLarge);

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.liquidity.tint, shape: BoxShape.circle),
                child: name == null
                    ? Icon(Icons.person_outline_rounded, size: 28, color: colors.liquidity.onTint)
                    : Text(
                        name.characters.first.toUpperCase(),
                        style: textTheme.titleLarge?.copyWith(color: colors.liquidity.onTint),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name ?? 'Il tuo profilo', style: textTheme.titleMedium?.copyWith(fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(
                      preferences.profileEmail ?? 'Facoltativo: nome ed email restano su questo telefono',
                      style: textTheme.labelMedium?.copyWith(color: colors.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Modifica',
                style: textTheme.labelMedium?.copyWith(color: colors.income.text, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modifica di nome ed email del profilo locale. Restituisce le preferenze aggiornate.
Future<LocalPreferences?> _showProfileSheet(BuildContext context, LocalPreferences preferences) {
  return AppBottomSheet.show<LocalPreferences>(
    context,
    title: 'Profilo',
    builder: (_) => _ProfileForm(preferences: preferences),
  );
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.preferences});

  final LocalPreferences preferences;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  late final _name = TextEditingController(text: widget.preferences.profileName ?? '');
  late final _email = TextEditingController(text: widget.preferences.profileEmail ?? '');
  var _emailError = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    final email = _email.text.trim();
    // Controllo leggero: serve solo a evitare refusi evidenti.
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _emailError = true);
      return;
    }
    Navigator.pop(context, widget.preferences.copyWith(profileName: _name.text.trim(), profileEmail: email));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nome (facoltativo)'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Email (facoltativa)',
            errorText: _emailError ? 'Indirizzo email non valido' : null,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Nome ed email restano su questo telefono: non c\'è un account e non vengono inviati da nessuna parte.',
          style: textTheme.bodySmall?.copyWith(height: 1.45),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: _save, child: const Text('Salva')),
      ],
    );
  }
}

/// "Versione 1.0.0 (1)": versione e build dai metadati dell'app. Vuoto finché non arrivano.
class _VersionText extends ConsumerWidget {
  const _VersionText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider).value;
    return Text(
      info == null ? '' : 'Versione ${info.version} (${info.buildNumber})',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.colors.textMuted),
    );
  }
}
