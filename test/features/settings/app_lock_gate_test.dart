import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_entrate/core/theme/app_theme.dart';
import 'package:spese_entrate/data/device/biometric_auth.dart';
import 'package:spese_entrate/features/settings/application/app_lock.dart';
import 'package:spese_entrate/features/settings/presentation/app_lock_gate.dart';

/// Blocco finto: parte da [initial] e registra gli eventi del ciclo di vita che riceve.
class _RecordingAppLock extends AppLock {
  _RecordingAppLock(this.initial);

  final bool initial;
  final events = <String>[];

  @override
  bool build() => initial;

  @override
  void wentToBackground() => events.add('background');

  @override
  void cameToForeground() => events.add('foreground');
}

/// Biometria che non riesce mai: la schermata di sblocco resta.
class _FailingBiometricAuth extends BiometricAuth {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate(String reason) async => false;
}

void main() {
  final cover = find.byKey(const Key('privacy-cover'));
  final balance = find.text('€ 1.234,56');
  final lockScreen = find.text('Finanze è bloccata');

  Future<_RecordingAppLock> pumpGate(WidgetTester tester, {bool locked = false}) async {
    final lock = _RecordingAppLock(locked);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockProvider.overrideWith(() => lock),
          biometricAuthProvider.overrideWithValue(_FailingBiometricAuth()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AppLockGate(child: Scaffold(body: Text('€ 1.234,56'))),
        ),
      ),
    );
    await tester.pump();
    return lock;
  }

  Future<void> goTo(WidgetTester tester, List<AppLifecycleState> states) async {
    for (final state in states) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
  }

  const toBackground = [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused];
  const toForeground = [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed];

  tearDown(() => TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed));

  testWidgets('in primo piano niente velo', (tester) async {
    await pumpGate(tester);
    expect(cover, findsNothing);
    expect(balance, findsOneWidget);
  });

  testWidgets('inactive (selettore delle app su iOS): velo subito, senza contare come background', (tester) async {
    final lock = await pumpGate(tester);
    await goTo(tester, [AppLifecycleState.inactive]);
    expect(cover, findsOneWidget);
    expect(lock.events, isEmpty, reason: 'il timer del blocco parte solo da hidden/paused');

    await goTo(tester, [AppLifecycleState.resumed]);
    expect(cover, findsNothing);
    expect(balance, findsOneWidget, reason: 'le schermate sotto restano dove erano');
  });

  testWidgets('background e ritorno: velo per tutto il tempo, eventi del blocco invariati', (tester) async {
    final lock = await pumpGate(tester);
    await goTo(tester, toBackground);
    expect(cover, findsOneWidget);
    expect(lock.events, ['background', 'background']);

    await goTo(tester, toForeground);
    expect(cover, findsNothing);
    expect(lock.events.last, 'foreground');
  });

  testWidgets('con l\'app bloccata il velo copre anche la schermata di sblocco, che poi resta', (tester) async {
    await pumpGate(tester, locked: true);
    expect(lockScreen, findsOneWidget);

    await goTo(tester, toBackground);
    expect(cover, findsOneWidget);
    // Il velo è sopra la schermata di sblocco.
    final stack = tester.widget<Stack>(find.ancestor(of: cover, matching: find.byType(Stack)).first);
    expect((stack.children.last as Positioned).child.runtimeType.toString(), '_PrivacyCover');

    await goTo(tester, toForeground);
    expect(cover, findsNothing);
    expect(lockScreen, findsOneWidget, reason: 'il velo non sblocca nulla');
  });
}
