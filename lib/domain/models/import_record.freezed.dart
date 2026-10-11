// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'import_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImportRecord {

 String get id; String get fileName;/// Righe di dati lette dal file (valide e con errori).
 int get rowCount; int get insertedCount; int get updatedCount; DateTime get createdAt; DateTime? get undoneAt;
/// Create a copy of ImportRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportRecordCopyWith<ImportRecord> get copyWith => _$ImportRecordCopyWithImpl<ImportRecord>(this as ImportRecord, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ImportRecord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportRecord&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.rowCount, _this.rowCount) || other.rowCount == _this.rowCount)&&(identical(other.insertedCount, _this.insertedCount) || other.insertedCount == _this.insertedCount)&&(identical(other.updatedCount, _this.updatedCount) || other.updatedCount == _this.updatedCount)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.undoneAt, _this.undoneAt) || other.undoneAt == _this.undoneAt));
}


@override
int get hashCode {
  final _this = this as ImportRecord;
  return Object.hash(runtimeType,_this.id,_this.fileName,_this.rowCount,_this.insertedCount,_this.updatedCount,_this.createdAt,_this.undoneAt);
}

@override
String toString() {
  final _this = this as ImportRecord;
  return 'ImportRecord(id: ${_this.id}, fileName: ${_this.fileName}, rowCount: ${_this.rowCount}, insertedCount: ${_this.insertedCount}, updatedCount: ${_this.updatedCount}, createdAt: ${_this.createdAt}, undoneAt: ${_this.undoneAt})';
}


}

/// @nodoc
abstract mixin class $ImportRecordCopyWith<$Res>  {
  factory $ImportRecordCopyWith(ImportRecord value, $Res Function(ImportRecord) _then) = _$ImportRecordCopyWithImpl;
@useResult
$Res call({
 String id, String fileName, int rowCount, int insertedCount, int updatedCount, DateTime createdAt, DateTime? undoneAt
});




}
/// @nodoc
class _$ImportRecordCopyWithImpl<$Res>
    implements $ImportRecordCopyWith<$Res> {
  _$ImportRecordCopyWithImpl(this._self, this._then);

  final ImportRecord _self;
  final $Res Function(ImportRecord) _then;

/// Create a copy of ImportRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fileName = null,Object? rowCount = null,Object? insertedCount = null,Object? updatedCount = null,Object? createdAt = null,Object? undoneAt = freezed,}) {
  return _then(ImportRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,rowCount: null == rowCount ? _self.rowCount : rowCount // ignore: cast_nullable_to_non_nullable
as int,insertedCount: null == insertedCount ? _self.insertedCount : insertedCount // ignore: cast_nullable_to_non_nullable
as int,updatedCount: null == updatedCount ? _self.updatedCount : updatedCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,undoneAt: freezed == undoneAt ? _self.undoneAt : undoneAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ImportRecord].
extension ImportRecordPatterns on ImportRecord {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImportRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImportRecord() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImportRecord value)  $default,){
final _that = this;
switch (_that) {
case _ImportRecord():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImportRecord value)?  $default,){
final _that = this;
switch (_that) {
case _ImportRecord() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fileName,  int rowCount,  int insertedCount,  int updatedCount,  DateTime createdAt,  DateTime? undoneAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImportRecord() when $default != null:
return $default(_that.id,_that.fileName,_that.rowCount,_that.insertedCount,_that.updatedCount,_that.createdAt,_that.undoneAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fileName,  int rowCount,  int insertedCount,  int updatedCount,  DateTime createdAt,  DateTime? undoneAt)  $default,) {final _that = this;
switch (_that) {
case _ImportRecord():
return $default(_that.id,_that.fileName,_that.rowCount,_that.insertedCount,_that.updatedCount,_that.createdAt,_that.undoneAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fileName,  int rowCount,  int insertedCount,  int updatedCount,  DateTime createdAt,  DateTime? undoneAt)?  $default,) {final _that = this;
switch (_that) {
case _ImportRecord() when $default != null:
return $default(_that.id,_that.fileName,_that.rowCount,_that.insertedCount,_that.updatedCount,_that.createdAt,_that.undoneAt);case _:
  return null;

}
}

}

/// @nodoc


class _ImportRecord extends ImportRecord {
  const _ImportRecord({required this.id, required this.fileName, required this.rowCount, required this.insertedCount, required this.updatedCount, required this.createdAt, this.undoneAt}): super._();
  

@override final  String id;
@override final  String fileName;
/// Righe di dati lette dal file (valide e con errori).
@override final  int rowCount;
@override final  int insertedCount;
@override final  int updatedCount;
@override final  DateTime createdAt;
@override final  DateTime? undoneAt;

/// Create a copy of ImportRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImportRecordCopyWith<_ImportRecord> get copyWith => __$ImportRecordCopyWithImpl<_ImportRecord>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImportRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.rowCount, rowCount) || other.rowCount == rowCount)&&(identical(other.insertedCount, insertedCount) || other.insertedCount == insertedCount)&&(identical(other.updatedCount, updatedCount) || other.updatedCount == updatedCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.undoneAt, undoneAt) || other.undoneAt == undoneAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,fileName,rowCount,insertedCount,updatedCount,createdAt,undoneAt);
}

@override
String toString() {
    return 'ImportRecord(id: $id, fileName: $fileName, rowCount: $rowCount, insertedCount: $insertedCount, updatedCount: $updatedCount, createdAt: $createdAt, undoneAt: $undoneAt)';
}


}

/// @nodoc
abstract mixin class _$ImportRecordCopyWith<$Res> implements $ImportRecordCopyWith<$Res> {
  factory _$ImportRecordCopyWith(_ImportRecord value, $Res Function(_ImportRecord) _then) = __$ImportRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String fileName, int rowCount, int insertedCount, int updatedCount, DateTime createdAt, DateTime? undoneAt
});




}
/// @nodoc
class __$ImportRecordCopyWithImpl<$Res>
    implements _$ImportRecordCopyWith<$Res> {
  __$ImportRecordCopyWithImpl(this._self, this._then);

  final _ImportRecord _self;
  final $Res Function(_ImportRecord) _then;

/// Create a copy of ImportRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fileName = null,Object? rowCount = null,Object? insertedCount = null,Object? updatedCount = null,Object? createdAt = null,Object? undoneAt = freezed,}) {
  return _then(_ImportRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,rowCount: null == rowCount ? _self.rowCount : rowCount // ignore: cast_nullable_to_non_nullable
as int,insertedCount: null == insertedCount ? _self.insertedCount : insertedCount // ignore: cast_nullable_to_non_nullable
as int,updatedCount: null == updatedCount ? _self.updatedCount : updatedCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,undoneAt: freezed == undoneAt ? _self.undoneAt : undoneAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
