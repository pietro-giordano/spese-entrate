// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurrence_exception.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecurrenceException {

 String get id; String get ruleId; LocalDate get occurrenceDate; RecurrenceExceptionKind get kind;
/// Create a copy of RecurrenceException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurrenceExceptionCopyWith<RecurrenceException> get copyWith => _$RecurrenceExceptionCopyWithImpl<RecurrenceException>(this as RecurrenceException, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RecurrenceException;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurrenceException&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.ruleId, _this.ruleId) || other.ruleId == _this.ruleId)&&(identical(other.occurrenceDate, _this.occurrenceDate) || other.occurrenceDate == _this.occurrenceDate)&&(identical(other.kind, _this.kind) || other.kind == _this.kind));
}


@override
int get hashCode {
  final _this = this as RecurrenceException;
  return Object.hash(runtimeType,_this.id,_this.ruleId,_this.occurrenceDate,_this.kind);
}

@override
String toString() {
  final _this = this as RecurrenceException;
  return 'RecurrenceException(id: ${_this.id}, ruleId: ${_this.ruleId}, occurrenceDate: ${_this.occurrenceDate}, kind: ${_this.kind})';
}


}

/// @nodoc
abstract mixin class $RecurrenceExceptionCopyWith<$Res>  {
  factory $RecurrenceExceptionCopyWith(RecurrenceException value, $Res Function(RecurrenceException) _then) = _$RecurrenceExceptionCopyWithImpl;
@useResult
$Res call({
 String id, String ruleId, LocalDate occurrenceDate, RecurrenceExceptionKind kind
});




}
/// @nodoc
class _$RecurrenceExceptionCopyWithImpl<$Res>
    implements $RecurrenceExceptionCopyWith<$Res> {
  _$RecurrenceExceptionCopyWithImpl(this._self, this._then);

  final RecurrenceException _self;
  final $Res Function(RecurrenceException) _then;

/// Create a copy of RecurrenceException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ruleId = null,Object? occurrenceDate = null,Object? kind = null,}) {
  return _then(RecurrenceException(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ruleId: null == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as String,occurrenceDate: null == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as LocalDate,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RecurrenceExceptionKind,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurrenceException].
extension RecurrenceExceptionPatterns on RecurrenceException {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurrenceException value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurrenceException() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurrenceException value)  $default,){
final _that = this;
switch (_that) {
case _RecurrenceException():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurrenceException value)?  $default,){
final _that = this;
switch (_that) {
case _RecurrenceException() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ruleId,  LocalDate occurrenceDate,  RecurrenceExceptionKind kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurrenceException() when $default != null:
return $default(_that.id,_that.ruleId,_that.occurrenceDate,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ruleId,  LocalDate occurrenceDate,  RecurrenceExceptionKind kind)  $default,) {final _that = this;
switch (_that) {
case _RecurrenceException():
return $default(_that.id,_that.ruleId,_that.occurrenceDate,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ruleId,  LocalDate occurrenceDate,  RecurrenceExceptionKind kind)?  $default,) {final _that = this;
switch (_that) {
case _RecurrenceException() when $default != null:
return $default(_that.id,_that.ruleId,_that.occurrenceDate,_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class _RecurrenceException implements RecurrenceException {
  const _RecurrenceException({required this.id, required this.ruleId, required this.occurrenceDate, this.kind = RecurrenceExceptionKind.skip});
  

@override final  String id;
@override final  String ruleId;
@override final  LocalDate occurrenceDate;
@override@JsonKey() final  RecurrenceExceptionKind kind;

/// Create a copy of RecurrenceException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurrenceExceptionCopyWith<_RecurrenceException> get copyWith => __$RecurrenceExceptionCopyWithImpl<_RecurrenceException>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurrenceException&&(identical(other.id, id) || other.id == id)&&(identical(other.ruleId, ruleId) || other.ruleId == ruleId)&&(identical(other.occurrenceDate, occurrenceDate) || other.occurrenceDate == occurrenceDate)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,ruleId,occurrenceDate,kind);
}

@override
String toString() {
    return 'RecurrenceException(id: $id, ruleId: $ruleId, occurrenceDate: $occurrenceDate, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$RecurrenceExceptionCopyWith<$Res> implements $RecurrenceExceptionCopyWith<$Res> {
  factory _$RecurrenceExceptionCopyWith(_RecurrenceException value, $Res Function(_RecurrenceException) _then) = __$RecurrenceExceptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String ruleId, LocalDate occurrenceDate, RecurrenceExceptionKind kind
});




}
/// @nodoc
class __$RecurrenceExceptionCopyWithImpl<$Res>
    implements _$RecurrenceExceptionCopyWith<$Res> {
  __$RecurrenceExceptionCopyWithImpl(this._self, this._then);

  final _RecurrenceException _self;
  final $Res Function(_RecurrenceException) _then;

/// Create a copy of RecurrenceException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ruleId = null,Object? occurrenceDate = null,Object? kind = null,}) {
  return _then(_RecurrenceException(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ruleId: null == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as String,occurrenceDate: null == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as LocalDate,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RecurrenceExceptionKind,
  ));
}


}

// dart format on
