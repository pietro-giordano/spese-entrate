import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/dates.dart';
import 'enums.dart';

part 'recurrence_exception.freezed.dart';

@freezed
abstract class RecurrenceException with _$RecurrenceException {
  const factory RecurrenceException({
    required String id,
    required String ruleId,
    required LocalDate occurrenceDate,
    @Default(RecurrenceExceptionKind.skip) RecurrenceExceptionKind kind,
  }) = _RecurrenceException;
}
