// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recurrenceGenerator)
final recurrenceGeneratorProvider = RecurrenceGeneratorProvider._();

final class RecurrenceGeneratorProvider
    extends $FunctionalProvider<RecurrenceGenerator, RecurrenceGenerator, RecurrenceGenerator>
    with $Provider<RecurrenceGenerator> {
  RecurrenceGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurrenceGeneratorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurrenceGeneratorHash();

  @$internal
  @override
  $ProviderElement<RecurrenceGenerator> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  RecurrenceGenerator create(Ref ref) {
    return recurrenceGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurrenceGenerator value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<RecurrenceGenerator>(value));
  }
}

String _$recurrenceGeneratorHash() => r'a2fbacfbfefcf6abdf2885ac75db10923a4e6b3a';

/// Regole non cancellate, per nome.

@ProviderFor(recurrenceRules)
final recurrenceRulesProvider = RecurrenceRulesProvider._();

/// Regole non cancellate, per nome.

final class RecurrenceRulesProvider
    extends $FunctionalProvider<AsyncValue<List<RecurrenceRule>>, List<RecurrenceRule>, Stream<List<RecurrenceRule>>>
    with $FutureModifier<List<RecurrenceRule>>, $StreamProvider<List<RecurrenceRule>> {
  /// Regole non cancellate, per nome.
  RecurrenceRulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurrenceRulesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurrenceRulesHash();

  @$internal
  @override
  $StreamProviderElement<List<RecurrenceRule>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<RecurrenceRule>> create(Ref ref) {
    return recurrenceRules(ref);
  }
}

String _$recurrenceRulesHash() => r'46da93267a75f35550c188c03119a8f197e69d18';

/// Date saltate di tutte le regole.

@ProviderFor(recurrenceExceptions)
final recurrenceExceptionsProvider = RecurrenceExceptionsProvider._();

/// Date saltate di tutte le regole.

final class RecurrenceExceptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecurrenceException>>,
          List<RecurrenceException>,
          Stream<List<RecurrenceException>>
        >
    with $FutureModifier<List<RecurrenceException>>, $StreamProvider<List<RecurrenceException>> {
  /// Date saltate di tutte le regole.
  RecurrenceExceptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurrenceExceptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurrenceExceptionsHash();

  @$internal
  @override
  $StreamProviderElement<List<RecurrenceException>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<RecurrenceException>> create(Ref ref) {
    return recurrenceExceptions(ref);
  }
}

String _$recurrenceExceptionsHash() => r'501811a30fd5bb6cf314016e331ae85ef8e71200';

@ProviderFor(recurrenceRule)
final recurrenceRuleProvider = RecurrenceRuleFamily._();

final class RecurrenceRuleProvider
    extends $FunctionalProvider<AsyncValue<RecurrenceRule?>, RecurrenceRule?, FutureOr<RecurrenceRule?>>
    with $FutureModifier<RecurrenceRule?>, $FutureProvider<RecurrenceRule?> {
  RecurrenceRuleProvider._({required RecurrenceRuleFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'recurrenceRuleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurrenceRuleHash();

  @override
  String toString() {
    return r'recurrenceRuleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RecurrenceRule?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecurrenceRule?> create(Ref ref) {
    final argument = this.argument as String;
    return recurrenceRule(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RecurrenceRuleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$recurrenceRuleHash() => r'920be98949e22f13fa40fbd9254f784cef8ad865';

final class RecurrenceRuleFamily extends $Family with $FunctionalFamilyOverride<FutureOr<RecurrenceRule?>, String> {
  RecurrenceRuleFamily._()
    : super(
        retry: null,
        name: r'recurrenceRuleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RecurrenceRuleProvider call(String id) => RecurrenceRuleProvider._(argument: id, from: this);

  @override
  String toString() => r'recurrenceRuleProvider';
}

/// Sezione "In arrivo" della home: movimenti da confermare fino a oggi + 7 giorni
/// (anche quelli scaduti e non ancora confermati), dal più vicino.
/// I `pending` delle regole in pausa restano nascosti finché la regola non riprende.

@ProviderFor(upcomingTransactions)
final upcomingTransactionsProvider = UpcomingTransactionsProvider._();

/// Sezione "In arrivo" della home: movimenti da confermare fino a oggi + 7 giorni
/// (anche quelli scaduti e non ancora confermati), dal più vicino.
/// I `pending` delle regole in pausa restano nascosti finché la regola non riprende.

final class UpcomingTransactionsProvider
    extends $FunctionalProvider<AsyncValue<List<Transaction>>, List<Transaction>, FutureOr<List<Transaction>>>
    with $FutureModifier<List<Transaction>>, $FutureProvider<List<Transaction>> {
  /// Sezione "In arrivo" della home: movimenti da confermare fino a oggi + 7 giorni
  /// (anche quelli scaduti e non ancora confermati), dal più vicino.
  /// I `pending` delle regole in pausa restano nascosti finché la regola non riprende.
  UpcomingTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'upcomingTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$upcomingTransactionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    return upcomingTransactions(ref);
  }
}

String _$upcomingTransactionsHash() => r'3aa91be9b952fe415800101c4f04c20361e27988';

/// Date delle occorrenze eliminate di una regola (non si rigenerano).

@ProviderFor(deletedOccurrences)
final deletedOccurrencesProvider = DeletedOccurrencesFamily._();

/// Date delle occorrenze eliminate di una regola (non si rigenerano).

final class DeletedOccurrencesProvider
    extends $FunctionalProvider<AsyncValue<Set<LocalDate>>, Set<LocalDate>, Stream<Set<LocalDate>>>
    with $FutureModifier<Set<LocalDate>>, $StreamProvider<Set<LocalDate>> {
  /// Date delle occorrenze eliminate di una regola (non si rigenerano).
  DeletedOccurrencesProvider._({required DeletedOccurrencesFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'deletedOccurrencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletedOccurrencesHash();

  @override
  String toString() {
    return r'deletedOccurrencesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Set<LocalDate>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<Set<LocalDate>> create(Ref ref) {
    final argument = this.argument as String;
    return deletedOccurrences(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DeletedOccurrencesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deletedOccurrencesHash() => r'8161624490be8594eb9afa442f4550b587f61ed2';

/// Date delle occorrenze eliminate di una regola (non si rigenerano).

final class DeletedOccurrencesFamily extends $Family with $FunctionalFamilyOverride<Stream<Set<LocalDate>>, String> {
  DeletedOccurrencesFamily._()
    : super(
        retry: null,
        name: r'deletedOccurrencesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Date delle occorrenze eliminate di una regola (non si rigenerano).

  DeletedOccurrencesProvider call(String ruleId) => DeletedOccurrencesProvider._(argument: ruleId, from: this);

  @override
  String toString() => r'deletedOccurrencesProvider';
}

/// Movimenti (non cancellati) di una regola, dal più recente.

@ProviderFor(ruleTransactions)
final ruleTransactionsProvider = RuleTransactionsFamily._();

/// Movimenti (non cancellati) di una regola, dal più recente.

final class RuleTransactionsProvider
    extends $FunctionalProvider<AsyncValue<List<Transaction>>, List<Transaction>, FutureOr<List<Transaction>>>
    with $FutureModifier<List<Transaction>>, $FutureProvider<List<Transaction>> {
  /// Movimenti (non cancellati) di una regola, dal più recente.
  RuleTransactionsProvider._({required RuleTransactionsFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'ruleTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ruleTransactionsHash();

  @override
  String toString() {
    return r'ruleTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    final argument = this.argument as String;
    return ruleTransactions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RuleTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ruleTransactionsHash() => r'e2c3c1606f5e89b6807e2bc2dfe6b8b797a6d364';

/// Movimenti (non cancellati) di una regola, dal più recente.

final class RuleTransactionsFamily extends $Family with $FunctionalFamilyOverride<FutureOr<List<Transaction>>, String> {
  RuleTransactionsFamily._()
    : super(
        retry: null,
        name: r'ruleTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Movimenti (non cancellati) di una regola, dal più recente.

  RuleTransactionsProvider call(String ruleId) => RuleTransactionsProvider._(argument: ruleId, from: this);

  @override
  String toString() => r'ruleTransactionsProvider';
}

/// Totali fissi del mese in corso e media mensile prevista.

@ProviderFor(recurringTotalsThisMonth)
final recurringTotalsThisMonthProvider = RecurringTotalsThisMonthProvider._();

/// Totali fissi del mese in corso e media mensile prevista.

final class RecurringTotalsThisMonthProvider
    extends $FunctionalProvider<AsyncValue<RecurringTotals>, RecurringTotals, FutureOr<RecurringTotals>>
    with $FutureModifier<RecurringTotals>, $FutureProvider<RecurringTotals> {
  /// Totali fissi del mese in corso e media mensile prevista.
  RecurringTotalsThisMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringTotalsThisMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurringTotalsThisMonthHash();

  @$internal
  @override
  $FutureProviderElement<RecurringTotals> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecurringTotals> create(Ref ref) {
    return recurringTotalsThisMonth(ref);
  }
}

String _$recurringTotalsThisMonthHash() => r'426255d0a7663d415cc19c22f3ccb5beb1e1a5a9';

@ProviderFor(recurrenceActions)
final recurrenceActionsProvider = RecurrenceActionsProvider._();

final class RecurrenceActionsProvider
    extends $FunctionalProvider<RecurrenceActions, RecurrenceActions, RecurrenceActions>
    with $Provider<RecurrenceActions> {
  RecurrenceActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurrenceActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurrenceActionsHash();

  @$internal
  @override
  $ProviderElement<RecurrenceActions> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  RecurrenceActions create(Ref ref) {
    return recurrenceActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurrenceActions value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<RecurrenceActions>(value));
  }
}

String _$recurrenceActionsHash() => r'4bd430900cdb7bd9c24c20e811d37e7c3fa4258c';
