// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_detail_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Movimento con allegati e date; null se non esiste o è stato cancellato.

@ProviderFor(transactionDetail)
final transactionDetailProvider = TransactionDetailFamily._();

/// Movimento con allegati e date; null se non esiste o è stato cancellato.

final class TransactionDetailProvider
    extends $FunctionalProvider<AsyncValue<TransactionDetail?>, TransactionDetail?, FutureOr<TransactionDetail?>>
    with $FutureModifier<TransactionDetail?>, $FutureProvider<TransactionDetail?> {
  /// Movimento con allegati e date; null se non esiste o è stato cancellato.
  TransactionDetailProvider._({required TransactionDetailFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'transactionDetailProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionDetailHash();

  @override
  String toString() {
    return r'transactionDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TransactionDetail?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TransactionDetail?> create(Ref ref) {
    final argument = this.argument as String;
    return transactionDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionDetailHash() => r'cd3f0c1fdbd96e5d7b9d6530585e919e2e4e0601';

/// Movimento con allegati e date; null se non esiste o è stato cancellato.

final class TransactionDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TransactionDetail?>, String> {
  TransactionDetailFamily._()
    : super(
        retry: null,
        name: r'transactionDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Movimento con allegati e date; null se non esiste o è stato cancellato.

  TransactionDetailProvider call(String id) => TransactionDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'transactionDetailProvider';
}
