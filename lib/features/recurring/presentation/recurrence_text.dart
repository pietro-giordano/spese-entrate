import 'package:intl/intl.dart';

import '../../../core/dates.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/recurrence_rule.dart';

// Testi delle ricorrenze, condivisi da Inserimento rapido, elenco e dettaglio.

const _weekdays = ['lunedì', 'martedì', 'mercoledì', 'giovedì', 'venerdì', 'sabato', 'domenica'];

/// "Ogni mese, il 5", "Ogni 2 settimane, il lunedì", "Ogni anno, il 15 marzo", "Ogni 3 giorni".
String describeSchedule(RecurrenceRule rule) {
  final n = rule.interval;
  final start = rule.startDate;
  String day(int value) => value == 1 ? '1°' : '$value';

  switch (rule.frequency) {
    case RecurrenceFrequency.daily:
      return n == 1 ? 'Ogni giorno' : 'Ogni $n giorni';
    case RecurrenceFrequency.weekly:
      final weekday = rule.byWeekday ?? start.weekday;
      final article = weekday == DateTime.sunday ? 'la' : 'il';
      return '${n == 1 ? 'Ogni settimana' : 'Ogni $n settimane'}, $article ${_weekdays[weekday - 1]}';
    case RecurrenceFrequency.monthly:
      return '${n == 1 ? 'Ogni mese' : 'Ogni $n mesi'}, il ${day(rule.byMonthDay ?? start.day)}';
    case RecurrenceFrequency.yearly:
      final month = DateFormat.MMMM('it_IT').format(DateTime(2000, rule.byMonth ?? start.month));
      return '${n == 1 ? 'Ogni anno' : 'Ogni $n anni'}, il ${day(rule.byMonthDay ?? start.day)} $month';
  }
}

/// Fine della regola: "fino al 5 mar 2027", "12 volte", oppure null se non finisce.
String? describeEnd(RecurrenceRule rule) {
  if (rule.endDate case final end?) return 'fino al ${DateFormat('d MMM y', 'it_IT').format(end.toDateTime())}';
  if (rule.maxCount case final count?) return count == 1 ? '1 volta' : '$count volte';
  return null;
}

/// "5 ott", oppure "5 ott 2027" se non è nell'anno di [today].
String shortDate(LocalDate date, LocalDate today) =>
    DateFormat(date.year == today.year ? 'd MMM' : 'd MMM y', 'it_IT').format(date.toDateTime());

/// "lun 5 ott" (con l'anno se diverso da quello di [today]).
String weekdayDate(LocalDate date, LocalDate today) =>
    DateFormat(date.year == today.year ? 'EEE d MMM' : 'EEE d MMM y', 'it_IT').format(date.toDateTime());

/// "lunedì 5 ottobre 2026".
String longDate(LocalDate date) => DateFormat('EEEE d MMMM y', 'it_IT').format(date.toDateTime());
