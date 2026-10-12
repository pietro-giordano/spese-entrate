import 'package:collection/collection.dart';

import '../../core/dates.dart';
import '../models/enums.dart';
import '../models/recurrence_exception.dart';
import '../models/recurrence_rule.dart';
import '../models/transaction.dart';

// Calcolo delle occorrenze delle ricorrenze: funzioni pure, senza database né Flutter.

/// Titolo di una ricorrenza in elenco e dettaglio: il nome, altrimenti la descrizione dei movimenti
/// (la nota), altrimenti la categoria ([categoryName]), altrimenti "Trasferimento" o "Ricorrenza".
/// Nomi e note fatti di soli spazi contano come vuoti.
String recurrenceTitle(RecurrenceRule rule, {String? categoryName}) =>
    recurrenceTitleOf(name: rule.name, note: rule.note, categoryName: categoryName, type: rule.type);

/// Come [recurrenceTitle], dai singoli valori: serve anche prima che la regola esista
/// (segnaposto del nome mentre si compila il movimento).
String recurrenceTitleOf({String? name, String? note, String? categoryName, required TransactionType type}) {
  String? text(String? value) => (value == null || value.trim().isEmpty) ? null : value.trim();
  return text(name) ??
      text(note) ??
      text(categoryName) ??
      (type == TransactionType.transfer ? 'Trasferimento' : 'Ricorrenza');
}

/// Nome iniziale di una regola creata da "Ripeti": la nota del movimento se c'è, altrimenti vuoto
/// (e il titolo si calcola con [recurrenceTitle]).
String initialRuleName(String? note) => note?.trim() ?? '';

/// Imposta l'inizio della regola e ne ricava i "punti fissi": il giorno della settimana
/// per le settimanali, il giorno del mese per le mensili, giorno e mese per le annuali.
RecurrenceRule anchorRuleAt(RecurrenceRule rule, LocalDate start) => rule.copyWith(
  startDate: start,
  byWeekday: rule.frequency == RecurrenceFrequency.weekly ? start.weekday : null,
  byMonthDay: rule.frequency == RecurrenceFrequency.monthly || rule.frequency == RecurrenceFrequency.yearly
      ? start.day
      : null,
  byMonth: rule.frequency == RecurrenceFrequency.yearly ? start.month : null,
);

/// Date delle occorrenze in ordine, dalla prima, rispettando `end_date` e `max_count`.
///
/// La sequenza è pigra e può essere infinita: chi la usa la limita (es. con `takeWhile`).
/// Le eccezioni (date saltate) non sono escluse qui e contano per `max_count`, come negli
/// standard dei calendari: saltare un'occorrenza non ne aggiunge una in fondo.
/// Mensili e annuali con un giorno che non esiste nel mese (31, 29 febbraio) cadono
/// nell'ultimo giorno del mese, e il mese dopo tornano al giorno della regola.
Iterable<LocalDate> occurrenceDates(RecurrenceRule rule) sync* {
  final start = rule.startDate;
  var count = 0;
  for (var k = 0; ; k++) {
    final date = _candidate(rule, k);
    // Il primo candidato di mensili/annuali può cadere prima dell'inizio (es. giorno 5, inizio il 10).
    if (date.isBefore(start)) continue;
    if (rule.endDate case final end? when date.isAfter(end)) return;
    if (rule.maxCount case final max? when count >= max) return;
    count++;
    yield date;
  }
}

LocalDate _candidate(RecurrenceRule rule, int k) {
  final start = rule.startDate;
  final step = k * rule.interval;
  switch (rule.frequency) {
    case RecurrenceFrequency.daily:
      return start.addDays(step);
    case RecurrenceFrequency.weekly:
      final weekday = rule.byWeekday ?? start.weekday;
      final first = start.addDays((weekday - start.weekday + 7) % 7);
      return first.addDays(7 * step);
    case RecurrenceFrequency.monthly:
      final month = LocalDate(start.year, start.month, 1).addMonths(step);
      return _clampedDay(month.year, month.month, rule.byMonthDay ?? start.day);
    case RecurrenceFrequency.yearly:
      return _clampedDay(start.year + step, rule.byMonth ?? start.month, rule.byMonthDay ?? start.day);
  }
}

LocalDate _clampedDay(int year, int month, int day) {
  final last = LocalDate.daysInMonth(year, month);
  return LocalDate(year, month, day > last ? last : day);
}

/// Occorrenze con data tra [from] e [to] compresi.
List<LocalDate> occurrencesBetween(RecurrenceRule rule, LocalDate from, LocalDate to) =>
    occurrenceDates(rule).takeWhile((date) => !date.isAfter(to)).where((date) => !date.isBefore(from)).toList();

/// Prima occorrenza a partire da [from] compreso; null se la regola è finita.
LocalDate? nextOccurrence(RecurrenceRule rule, LocalDate from) =>
    occurrenceDates(rule).firstWhereOrNull((date) => !date.isBefore(from));

/// Ultima occorrenza prima di [date] (esclusa); null se non ce ne sono.
LocalDate? previousOccurrence(RecurrenceRule rule, LocalDate date) =>
    occurrenceDates(rule).takeWhile((d) => d.isBefore(date)).lastOrNull;

/// Posizione di [date] nella sequenza (0 = prima occorrenza); null se non è un'occorrenza.
int? occurrenceIndex(RecurrenceRule rule, LocalDate date) {
  var index = 0;
  for (final d in occurrenceDates(rule)) {
    if (d == date) return index;
    if (d.isAfter(date)) return null;
    index++;
  }
  return null;
}

/// True se la regola non ha più occorrenze da [today] in poi.
bool isRuleFinished(RecurrenceRule rule, LocalDate today) => nextOccurrence(rule, today) == null;

/// Importo medio al mese di una regola: le mensili valgono l'importo diviso l'intervallo,
/// le altre sono una media (settimanali × 52 / 12, giornaliere × 365 / 12, annuali / 12).
int monthlyEquivalentCents(RecurrenceRule rule) {
  final perYear = switch (rule.frequency) {
    RecurrenceFrequency.daily => 365,
    RecurrenceFrequency.weekly => 52,
    RecurrenceFrequency.monthly => 12,
    RecurrenceFrequency.yearly => 1,
  };
  return (rule.amountCents * perYear / (12 * rule.interval)).round();
}

/// True se la regola cade esattamente una volta al mese (nessuna media da calcolare).
bool isMonthly(RecurrenceRule rule) => rule.frequency == RecurrenceFrequency.monthly && rule.interval == 1;

/// True se l'utente può confermare a mano [tx]: un `pending` che non appartiene a una regola
/// automatica ([rule] è la sua regola, se c'è). Le occorrenze automatiche le conferma solo
/// il generatore, alla loro data.
bool canConfirmManually(Transaction tx, RecurrenceRule? rule) => !tx.isConfirmed && rule?.mode != RecurrenceMode.auto;

/// Tentativo di confermare a mano un'occorrenza di una regola automatica.
class AutomaticOccurrenceException implements Exception {
  const AutomaticOccurrenceException(this.transactionId);

  final String transactionId;

  @override
  String toString() => 'Il movimento $transactionId verrà confermato automaticamente alla sua data';
}

/// La nuova data di "questa e le successive" deve venire dopo l'occorrenza precedente,
/// altrimenti le due regole si sovrapporrebbero.
class SplitDateException implements Exception {
  const SplitDateException(this.previousOccurrence);

  final LocalDate previousOccurrence;

  @override
  String toString() => 'La nuova data deve essere dopo il $previousOccurrence';
}

/// Esito di [splitRule].
class RuleSplit {
  const RuleSplit({required this.ended, required this.next, required this.nextSkips});

  /// La regola di prima, che ora termina prima dell'occorrenza modificata.
  final RecurrenceRule ended;

  /// La regola nuova, dalla data scelta nel form.
  final RecurrenceRule next;

  /// Date della regola nuova da saltare, perché la corrispondente occorrenza della vecchia
  /// è già stata registrata, eliminata o saltata.
  final List<LocalDate> nextSkips;
}

/// Divide [old] per "Modifica questa e le successive" sull'occorrenza originale [boundary].
///
/// - La vecchia termina il giorno prima di [boundary] (o della nuova data, se è precedente).
/// - [next] ha già campi e inizio scelti nel form; qui eredita la fine e le occorrenze
///   rimaste di `max_count`.
/// - Le occorrenze successive della vecchia già "risolte" ([resolvedOldDates]: confermate,
///   eliminate o saltate) non si ricreano: la n-esima occorrenza dopo [boundary] corrisponde
///   alla n-esima della nuova, che viene saltata. Così non nascono duplicati e lo storico resta.
///
/// Lancia [SplitDateException] se la nuova data non viene dopo l'occorrenza precedente,
/// e [ArgumentError] se [boundary] non è un'occorrenza di [old].
RuleSplit splitRule(
  RecurrenceRule old, {
  required LocalDate boundary,
  required RecurrenceRule next,
  Set<LocalDate> resolvedOldDates = const {},
}) {
  final boundaryIndex = occurrenceIndex(old, boundary);
  if (boundaryIndex == null) throw ArgumentError.value(boundary, 'boundary', 'non è un\'occorrenza della regola');
  final previous = previousOccurrence(old, boundary);
  if (previous != null && !next.startDate.isAfter(previous)) throw SplitDateException(previous);

  final firstNew = next.startDate.isBefore(boundary) ? next.startDate : boundary;
  final end = firstNew.addDays(-1);
  final ended = old.copyWith(endDate: old.endDate != null && old.endDate!.isBefore(end) ? old.endDate : end);

  final adjustedNext = next.copyWith(
    endDate: old.endDate,
    maxCount: old.maxCount == null ? null : old.maxCount! - boundaryIndex,
  );

  final newDates = occurrenceDates(adjustedNext);
  final skips = <LocalDate>{};
  for (final date in resolvedOldDates) {
    if (!date.isAfter(boundary)) continue;
    final index = occurrenceIndex(old, date);
    if (index == null) continue;
    final counterpart = newDates.elementAtOrNull(index - boundaryIndex);
    if (counterpart != null) skips.add(counterpart);
  }
  return RuleSplit(ended: ended, next: adjustedNext, nextSkips: skips.sorted());
}

/// Totali delle ricorrenze di spesa ed entrata (i trasferimenti non contano).
class RecurringTotals {
  const RecurringTotals({
    required this.expenseInMonth,
    required this.incomeInMonth,
    required this.expenseMonthlyAverage,
    required this.incomeMonthlyAverage,
    required this.expenseHasNonMonthly,
    required this.incomeHasNonMonthly,
  });

  /// Quanto cade davvero nel mese: importi registrati o, se non ancora creati, quelli della regola.
  final int expenseInMonth;
  final int incomeInMonth;

  /// Media mensile prevista delle regole attive (vedi [monthlyEquivalentCents]).
  final int expenseMonthlyAverage;
  final int incomeMonthlyAverage;

  /// True se qualche regola attiva di spesa (o di entrata) non è mensile: la media è una
  /// stima, diversa da un totale effettivo, e va mostrata come tale.
  final bool expenseHasNonMonthly;
  final bool incomeHasNonMonthly;
}

/// Calcola i [RecurringTotals] del mese [month].
///
/// Per ogni occorrenza del mese: se esiste il movimento conta il suo importo (anche se
/// modificato a mano), altrimenti quello della regola, salvo che sia saltata o la regola in pausa.
RecurringTotals recurringTotals({
  required List<RecurrenceRule> rules,
  required List<RecurrenceException> exceptions,
  required List<Transaction> transactions,
  required DateRange month,
  required LocalDate today,
}) {
  final skipped = {for (final e in exceptions) (e.ruleId, e.occurrenceDate)};
  final bySlot = {
    for (final tx in transactions)
      if (tx.recurrenceId != null && tx.occurrenceDate != null) (tx.recurrenceId!, tx.occurrenceDate!): tx,
  };
  var expenseInMonth = 0, incomeInMonth = 0, expenseAverage = 0, incomeAverage = 0;
  var expenseHasNonMonthly = false, incomeHasNonMonthly = false;

  for (final rule in rules) {
    if (rule.type == TransactionType.transfer) continue;
    for (final date in occurrencesBetween(rule, month.start, month.end)) {
      final tx = bySlot[(rule.id, date)];
      final (type, cents) = switch (tx) {
        final tx? => (tx.type, tx.amountCents),
        null when skipped.contains((rule.id, date)) || rule.isPaused => (rule.type, 0),
        null => (rule.type, rule.amountCents),
      };
      if (type == TransactionType.expense) expenseInMonth += cents;
      if (type == TransactionType.income) incomeInMonth += cents;
    }

    if (rule.isPaused || isRuleFinished(rule, today)) continue;
    if (rule.type == TransactionType.expense) {
      expenseAverage += monthlyEquivalentCents(rule);
      expenseHasNonMonthly |= !isMonthly(rule);
    } else {
      incomeAverage += monthlyEquivalentCents(rule);
      incomeHasNonMonthly |= !isMonthly(rule);
    }
  }

  return RecurringTotals(
    expenseInMonth: expenseInMonth,
    incomeInMonth: incomeInMonth,
    expenseMonthlyAverage: expenseAverage,
    incomeMonthlyAverage: incomeAverage,
    expenseHasNonMonthly: expenseHasNonMonthly,
    incomeHasNonMonthly: incomeHasNonMonthly,
  );
}
