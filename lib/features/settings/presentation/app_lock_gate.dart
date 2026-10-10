import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../application/app_lock.dart';

/// Ascolta il ciclo di vita dell'app e, quando è bloccata, copre tutto con la schermata di sblocco.
/// Le schermate sotto restano in memoria (si ritrovano come le si era lasciate).
///
/// Quando l'app non è in primo piano mostra anche un velo di privacy, così gli importi non
/// restano visibili nel selettore delle app. Il velo non blocca nulla: sparisce al ritorno.
/// Le protezioni native (MainActivity, AppDelegate) coprono i casi in cui iOS e Android
/// fotografano la finestra prima che Flutter disegni un nuovo fotogramma.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _lifecycle;
  var _obscured = _isObscured(WidgetsBinding.instance.lifecycleState);

  /// Velo su tutto tranne che in primo piano (anche `inactive`: selettore delle app su iOS).
  static bool _isObscured(AppLifecycleState? state) => state != null && state != AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (_isObscured(state) != _obscured) setState(() => _obscured = _isObscured(state));
        final lock = ref.read(appLockProvider.notifier);
        switch (state) {
          case AppLifecycleState.hidden || AppLifecycleState.paused:
            lock.wentToBackground();
          case AppLifecycleState.resumed:
            lock.cameToForeground();
          default:
            break;
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(appLockProvider);
    return Stack(
      children: [
        // Nascosto allo screen reader e ai tocchi mentre è bloccato.
        ExcludeSemantics(
          excluding: locked,
          child: AbsorbPointer(absorbing: locked, child: widget.child),
        ),
        if (locked) const Positioned.fill(child: _LockScreen()),
        if (_obscured) const Positioned.fill(child: _PrivacyCover()),
      ],
    );
  }
}

/// Velo neutro: solo il nome dell'app, nessun dato.
class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: ColoredBox(
        key: const Key('privacy-cover'),
        color: colors.background,
        child: Center(child: Icon(Icons.lock_outline_rounded, size: 40, color: colors.textMuted)),
      ),
    );
  }
}

class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen();

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  var _failed = false;

  @override
  void initState() {
    super.initState();
    // Chiede subito la biometria, senza bisogno di toccare il pulsante.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    final ok = await ref.read(appLockProvider.notifier).unlock();
    if (!ok && mounted) setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: colors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: colors.text),
              const SizedBox(height: AppSpacing.lg),
              Text('Spese & Entrate è bloccata', textAlign: TextAlign.center, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _failed ? 'Sblocco non riuscito. Riprova.' : 'Usa Face ID, l\'impronta o il codice del telefono.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: _unlock,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Sblocca'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
