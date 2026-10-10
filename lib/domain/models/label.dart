import 'package:freezed_annotation/freezed_annotation.dart';

part 'label.freezed.dart';

@freezed
abstract class Label with _$Label {
  const factory Label({required String id, required String name, required int color}) = _Label;
}
