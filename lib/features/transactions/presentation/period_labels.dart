import 'package:intl/intl.dart';

import '../../../core/dates.dart';

String _capitalize(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

String _format(String pattern, LocalDate date) => DateFormat(pattern, 'it_IT').format(date.toDateTime());

/// Intervallo compatto: "28 set – 4 ott 2026", oppure con entrambi gli anni se diversi.
String rangeLabel(LocalDate start, LocalDate end) {
  if (start == end) return _format('d MMM y', start);
  final startPattern = start.year == end.year ? 'd MMM' : 'd MMM y';
  return '${_format(startPattern, start)} – ${_format('d MMM y', end)}';
}

/// Titolo del periodo tra le frecce: "Sabato 3 ottobre", "28 set – 4 ott 2026",
/// "Ottobre 2026", "2026", "1 ago – 3 ott 2026".
String periodTitle(Period period, LocalDate today) {
  return switch (period.type) {
    PeriodType.day => _capitalize(
      _format(period.start.year == today.year ? 'EEEE d MMMM' : 'EEEE d MMMM y', period.start),
    ),
    PeriodType.week || PeriodType.custom => rangeLabel(period.start, period.end),
    PeriodType.month => _capitalize(_format('MMMM y', period.start)),
    PeriodType.year => '${period.start.year}',
  };
}

/// Titolo di una giornata nella lista: "Oggi · sab 3 ottobre", "Ieri · ven 2 ottobre", "Gio 1 ottobre".
String dayTitle(LocalDate date, LocalDate today) {
  final label = _format(date.year == today.year ? 'EEE d MMMM' : 'EEE d MMMM y', date);
  if (date == today) return 'Oggi · $label';
  if (date == today.addDays(-1)) return 'Ieri · $label';
  return _capitalize(label);
}
