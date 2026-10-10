// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tutti i movimenti non cancellati (servono ai saldi).

@ProviderFor(allTransactions)
final allTransactionsProvider = AllTransactionsProvider._();

/// Tutti i movimenti non cancellati (servono ai saldi).

final class AllTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          Stream<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $StreamProvider<List<Transaction>> {
  /// Tutti i movimenti non cancellati (servono ai saldi).
  AllTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allTransactionsHash();

  @$internal
  @override
  $StreamProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Transaction>> create(Ref ref) {
    return allTransactions(ref);
  }
}

String _$allTransactionsHash() => r'f09c6d447a99822e18b6a458df1c425aff972d31';

/// Movimenti con data nel periodo, dal più recente.

@ProviderFor(transactionsInRange)
final transactionsInRangeProvider = TransactionsInRangeFamily._();

/// Movimenti con data nel periodo, dal più recente.

final class TransactionsInRangeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          Stream<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $StreamProvider<List<Transaction>> {
  /// Movimenti con data nel periodo, dal più recente.
  TransactionsInRangeProvider._({
    required TransactionsInRangeFamily super.from,
    required DateRange super.argument,
  }) : super(
         retry: null,
         name: r'transactionsInRangeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionsInRangeHash();

  @override
  String toString() {
    return r'transactionsInRangeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Transaction>> create(Ref ref) {
    final argument = this.argument as DateRange;
    return transactionsInRange(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionsInRangeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionsInRangeHash() =>
    r'576e81ea1c8d387ad9394371a5e2effe4029cde4';

/// Movimenti con data nel periodo, dal più recente.

final class TransactionsInRangeFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Transaction>>, DateRange> {
  TransactionsInRangeFamily._()
    : super(
        retry: null,
        name: r'transactionsInRangeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Movimenti con data nel periodo, dal più recente.

  TransactionsInRangeProvider call(DateRange range) =>
      TransactionsInRangeProvider._(argument: range, from: this);

  @override
  String toString() => r'transactionsInRangeProvider';
}

/// Entrate, uscite e saldo del periodo (solo spese ed entrate confermate).

@ProviderFor(periodSummary)
final periodSummaryProvider = PeriodSummaryFamily._();

/// Entrate, uscite e saldo del periodo (solo spese ed entrate confermate).

final class PeriodSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<PeriodSummary>,
          PeriodSummary,
          FutureOr<PeriodSummary>
        >
    with $FutureModifier<PeriodSummary>, $FutureProvider<PeriodSummary> {
  /// Entrate, uscite e saldo del periodo (solo spese ed entrate confermate).
  PeriodSummaryProvider._({
    required PeriodSummaryFamily super.from,
    required DateRange super.argument,
  }) : super(
         retry: null,
         name: r'periodSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$periodSummaryHash();

  @override
  String toString() {
    return r'periodSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PeriodSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PeriodSummary> create(Ref ref) {
    final argument = this.argument as DateRange;
    return periodSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PeriodSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$periodSummaryHash() => r'48d16167087c501f5c72990f3ca488db6c3b30ed';

/// Entrate, uscite e saldo del periodo (solo spese ed entrate confermate).

final class PeriodSummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PeriodSummary>, DateRange> {
  PeriodSummaryFamily._()
    : super(
        retry: null,
        name: r'periodSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Entrate, uscite e saldo del periodo (solo spese ed entrate confermate).

  PeriodSummaryProvider call(DateRange range) =>
      PeriodSummaryProvider._(argument: range, from: this);

  @override
  String toString() => r'periodSummaryProvider';
}
