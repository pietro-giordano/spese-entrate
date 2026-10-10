// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quick_add_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Stato dell'inserimento rapido. [initialType] arriva dalla rotta (`/add?type=`).
/// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.

@ProviderFor(QuickAddController)
final quickAddControllerProvider = QuickAddControllerFamily._();

/// Stato dell'inserimento rapido. [initialType] arriva dalla rotta (`/add?type=`).
/// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.
final class QuickAddControllerProvider
    extends $NotifierProvider<QuickAddController, QuickAddState> {
  /// Stato dell'inserimento rapido. [initialType] arriva dalla rotta (`/add?type=`).
  /// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.
  QuickAddControllerProvider._({
    required QuickAddControllerFamily super.from,
    required TransactionType super.argument,
  }) : super(
         retry: null,
         name: r'quickAddControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quickAddControllerHash();

  @override
  String toString() {
    return r'quickAddControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  QuickAddController create() => QuickAddController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuickAddState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuickAddState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is QuickAddControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quickAddControllerHash() =>
    r'c8deaf3b459d65ab2470b26be29bb26351c4f978';

/// Stato dell'inserimento rapido. [initialType] arriva dalla rotta (`/add?type=`).
/// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.

final class QuickAddControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          QuickAddController,
          QuickAddState,
          QuickAddState,
          QuickAddState,
          TransactionType
        > {
  QuickAddControllerFamily._()
    : super(
        retry: null,
        name: r'quickAddControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stato dell'inserimento rapido. [initialType] arriva dalla rotta (`/add?type=`).
  /// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.

  QuickAddControllerProvider call(TransactionType initialType) =>
      QuickAddControllerProvider._(argument: initialType, from: this);

  @override
  String toString() => r'quickAddControllerProvider';
}

/// Stato dell'inserimento rapido. [initialType] arriva dalla rotta (`/add?type=`).
/// Si auto-elimina quando la schermata si chiude, così ogni apertura riparte da zero.

abstract class _$QuickAddController extends $Notifier<QuickAddState> {
  late final _$args = ref.$arg as TransactionType;
  TransactionType get initialType => _$args;

  QuickAddState build(TransactionType initialType);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<QuickAddState, QuickAddState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuickAddState, QuickAddState>,
              QuickAddState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
