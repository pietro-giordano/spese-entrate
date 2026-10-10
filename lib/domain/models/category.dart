import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'category.freezed.dart';

@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required CategoryKind kind,

    /// Colore ARGB (es. 0xFF15803D).
    required int color,
    @Default(0) int sortOrder,
    DateTime? archivedAt,
  }) = _Category;

  const Category._();

  bool get isArchived => archivedAt != null;
}
