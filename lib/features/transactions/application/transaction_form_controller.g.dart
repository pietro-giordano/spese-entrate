// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stato del form di un movimento, condiviso da Inserimento rapido e Modifica movimento.
/// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.

@ProviderFor(TransactionFormController)
final transactionFormControllerProvider = TransactionFormControllerFamily._();

/// Stato del form di un movimento, condiviso da Inserimento rapido e Modifica movimento.
/// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.
final class TransactionFormControllerProvider
    extends $NotifierProvider<TransactionFormController, TransactionFormState> {
  /// Stato del form di un movimento, condiviso da Inserimento rapido e Modifica movimento.
  /// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.
  TransactionFormControllerProvider._({
    required TransactionFormControllerFamily super.from,
    required TransactionFormSeed super.argument,
  }) : super(
         retry: null,
         name: r'transactionFormControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionFormControllerHash();

  @override
  String toString() {
    return r'transactionFormControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TransactionFormController create() => TransactionFormController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionFormState value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<TransactionFormState>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionFormControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionFormControllerHash() => r'1e1255e62cb08d652e83ec24de4cc5e307ae6e53';

/// Stato del form di un movimento, condiviso da Inserimento rapido e Modifica movimento.
/// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.

final class TransactionFormControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TransactionFormController,
          TransactionFormState,
          TransactionFormState,
          TransactionFormState,
          TransactionFormSeed
        > {
  TransactionFormControllerFamily._()
    : super(
        retry: null,
        name: r'transactionFormControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stato del form di un movimento, condiviso da Inserimento rapido e Modifica movimento.
  /// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.

  TransactionFormControllerProvider call(TransactionFormSeed seed) =>
      TransactionFormControllerProvider._(argument: seed, from: this);

  @override
  String toString() => r'transactionFormControllerProvider';
}

/// Stato del form di un movimento, condiviso da Inserimento rapido e Modifica movimento.
/// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.

abstract class _$TransactionFormController extends $Notifier<TransactionFormState> {
  late final _$args = ref.$arg as TransactionFormSeed;
  TransactionFormSeed get seed => _$args;

  TransactionFormState build(TransactionFormSeed seed);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TransactionFormState, TransactionFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransactionFormState, TransactionFormState>,
              TransactionFormState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(formWallets)
final formWalletsProvider = FormWalletsFamily._();

final class FormWalletsProvider extends $FunctionalProvider<FormWallets, FormWallets, FormWallets>
    with $Provider<FormWallets> {
  FormWalletsProvider._({required FormWalletsFamily super.from, required TransactionFormSeed super.argument})
    : super(
        retry: null,
        name: r'formWalletsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$formWalletsHash();

  @override
  String toString() {
    return r'formWalletsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<FormWallets> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  FormWallets create(Ref ref) {
    final argument = this.argument as TransactionFormSeed;
    return formWallets(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FormWallets value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<FormWallets>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is FormWalletsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$formWalletsHash() => r'e4426fafd7243f77895611e88186ce60a9e8a586';

final class FormWalletsFamily extends $Family with $FunctionalFamilyOverride<FormWallets, TransactionFormSeed> {
  FormWalletsFamily._()
    : super(
        retry: null,
        name: r'formWalletsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FormWalletsProvider call(TransactionFormSeed seed) => FormWalletsProvider._(argument: seed, from: this);

  @override
  String toString() => r'formWalletsProvider';
}
