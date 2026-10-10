import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/dates.dart';

/// Data di calendario ↔ `TEXT 'YYYY-MM-DD'`.
class LocalDateConverter extends TypeConverter<LocalDate, String> {
  const LocalDateConverter();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);

  @override
  String toSql(LocalDate value) => value.toString();
}

/// Lista di ID ↔ array JSON in una colonna `TEXT` (es. `label_ids`).
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) => (jsonDecode(fromDb) as List<dynamic>).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
