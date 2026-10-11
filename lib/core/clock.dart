import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'dates.dart';

part 'clock.g.dart';

/// Orologio dell'app. Nei test si sostituisce con `clockProvider.overrideWithValue(() => DateTime(...))`.
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;

/// Data di calendario di oggi secondo [clockProvider].
@riverpod
LocalDate today(Ref ref) => LocalDate.fromDateTime(ref.watch(clockProvider)());
