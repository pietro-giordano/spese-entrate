/// Date di calendario e intervalli di periodo.
///
/// I movimenti hanno una data di calendario (`'YYYY-MM-DD'`), senza ora né fuso orario,
/// separata dai timestamp tecnici. [LocalDate] la rappresenta; i calcoli interni usano
/// DateTime UTC, così il cambio dell'ora legale non sposta mai un giorno.
library;

/// Data di calendario senza ora (es. 2026-10-31).
class LocalDate implements Comparable<LocalDate> {
  /// Crea una data validando che esista (es. 2026-02-30 lancia [ArgumentError]).
  factory LocalDate(int year, int month, int day) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'deve essere tra 1 e 12');
    }
    if (day < 1 || day > daysInMonth(year, month)) {
      throw ArgumentError.value(day, 'day', 'non esiste in $year-$month');
    }
    return LocalDate._(year, month, day);
  }

  const LocalDate._(this.year, this.month, this.day);

  /// Giorno di calendario locale di [dateTime] (l'ora viene ignorata).
  factory LocalDate.fromDateTime(DateTime dateTime) => LocalDate._(dateTime.year, dateTime.month, dateTime.day);

  /// Oggi secondo l'orologio del dispositivo. [now] serve ai test.
  factory LocalDate.today({DateTime? now}) => LocalDate.fromDateTime(now ?? DateTime.now());

  /// Legge il formato del database `YYYY-MM-DD`. Lancia [FormatException] se non è valido.
  factory LocalDate.parse(String value) {
    final match = _isoPattern.firstMatch(value);
    if (match == null) throw FormatException('Data non valida, atteso YYYY-MM-DD', value);
    try {
      return LocalDate(int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
    } on ArgumentError {
      throw FormatException('Data inesistente', value);
    }
  }

  static final _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  /// Giorno della settimana: 1 = lunedì … 7 = domenica (come [DateTime.weekday]).
  int get weekday => _utc.weekday;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// Numero di giorni di un mese, considerando i bisestili.
  static int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

  LocalDate addDays(int days) => LocalDate.fromDateTime(DateTime.utc(year, month, day + days));

  /// Aggiunge mesi; se il giorno non esiste nel mese d'arrivo usa l'ultimo
  /// (31 gennaio + 1 mese = 28 o 29 febbraio).
  LocalDate addMonths(int months) {
    final monthIndex = year * 12 + (month - 1) + months;
    final newYear = monthIndex ~/ 12;
    final newMonth = monthIndex % 12 + 1;
    final lastDay = daysInMonth(newYear, newMonth);
    return LocalDate._(newYear, newMonth, day > lastDay ? lastDay : day);
  }

  /// Aggiunge anni; il 29 febbraio diventa 28 negli anni non bisestili.
  LocalDate addYears(int years) => addMonths(years * 12);

  /// Giorni da questa data a [other] (positivo se [other] è dopo).
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  /// Mezzanotte locale di questo giorno, per i widget che vogliono un [DateTime].
  DateTime toDateTime() => DateTime(year, month, day);

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// Formato del database: `YYYY-MM-DD`.
  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// Intervallo di date con estremi inclusi.
class DateRange {
  DateRange(this.start, this.end) {
    if (end.isBefore(start)) {
      throw ArgumentError('La fine ($end) è prima dell\'inizio ($start)');
    }
  }

  final LocalDate start;
  final LocalDate end;

  /// Numero di giorni, estremi inclusi (un solo giorno = 1).
  int get dayCount => start.daysUntil(end) + 1;

  bool contains(LocalDate date) => !date.isBefore(start) && !date.isAfter(end);

  @override
  bool operator ==(Object other) => other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start…$end';
}

/// Tipi di periodo del selettore Giorno/Sett./Mese/Anno/Periodo.
enum PeriodType { day, week, month, year, custom }

/// Un periodo selezionato: tipo + intervallo. Le frecce usano [previous] e [next].
class Period {
  const Period._(this.type, this.range);

  /// Periodo di tipo [type] che contiene [date].
  ///
  /// [weekStart] è il primo giorno della settimana: 1 = lunedì (default) … 7 = domenica.
  /// Per [PeriodType.custom] usa [Period.custom].
  factory Period.containing(PeriodType type, LocalDate date, {int weekStart = DateTime.monday}) {
    final range = switch (type) {
      PeriodType.day => DateRange(date, date),
      PeriodType.week => _weekContaining(date, weekStart),
      PeriodType.month => DateRange(
        LocalDate(date.year, date.month, 1),
        LocalDate(date.year, date.month, LocalDate.daysInMonth(date.year, date.month)),
      ),
      PeriodType.year => DateRange(LocalDate(date.year, 1, 1), LocalDate(date.year, 12, 31)),
      PeriodType.custom => throw ArgumentError('Per un periodo personalizzato usa Period.custom'),
    };
    return Period._(type, range);
  }

  /// Periodo libero "Dal … Al …", estremi inclusi.
  factory Period.custom(LocalDate start, LocalDate end) => Period._(PeriodType.custom, DateRange(start, end));

  final PeriodType type;
  final DateRange range;

  LocalDate get start => range.start;
  LocalDate get end => range.end;

  /// Sposta il periodo di [steps] unità del suo tipo (negativo = indietro).
  /// Un periodo personalizzato si sposta della sua stessa durata.
  Period shift(int steps) {
    return switch (type) {
      PeriodType.day || PeriodType.week || PeriodType.custom => Period._(
        type,
        DateRange(start.addDays(range.dayCount * steps), end.addDays(range.dayCount * steps)),
      ),
      PeriodType.month => Period.containing(type, start.addMonths(steps)),
      PeriodType.year => Period.containing(type, start.addYears(steps)),
    };
  }

  Period get previous => shift(-1);
  Period get next => shift(1);

  @override
  bool operator ==(Object other) => other is Period && other.type == type && other.range == range;

  @override
  int get hashCode => Object.hash(type, range);

  @override
  String toString() => 'Period(${type.name}, $range)';

  static DateRange _weekContaining(LocalDate date, int weekStart) {
    if (weekStart < DateTime.monday || weekStart > DateTime.sunday) {
      throw ArgumentError.value(weekStart, 'weekStart', 'deve essere tra 1 (lunedì) e 7 (domenica)');
    }
    final offset = (date.weekday - weekStart + 7) % 7;
    final start = date.addDays(-offset);
    return DateRange(start, start.addDays(6));
  }
}
