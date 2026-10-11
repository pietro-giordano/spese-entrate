// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PeriodSummary {

 int get incomeCents; int get expenseCents;
/// Create a copy of PeriodSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodSummaryCopyWith<PeriodSummary> get copyWith => _$PeriodSummaryCopyWithImpl<PeriodSummary>(this as PeriodSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PeriodSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodSummary&&(identical(other.incomeCents, _this.incomeCents) || other.incomeCents == _this.incomeCents)&&(identical(other.expenseCents, _this.expenseCents) || other.expenseCents == _this.expenseCents));
}


@override
int get hashCode {
  final _this = this as PeriodSummary;
  return Object.hash(runtimeType,_this.incomeCents,_this.expenseCents);
}

@override
String toString() {
  final _this = this as PeriodSummary;
  return 'PeriodSummary(incomeCents: ${_this.incomeCents}, expenseCents: ${_this.expenseCents})';
}


}

/// @nodoc
abstract mixin class $PeriodSummaryCopyWith<$Res>  {
  factory $PeriodSummaryCopyWith(PeriodSummary value, $Res Function(PeriodSummary) _then) = _$PeriodSummaryCopyWithImpl;
@useResult
$Res call({
 int incomeCents, int expenseCents
});




}
/// @nodoc
class _$PeriodSummaryCopyWithImpl<$Res>
    implements $PeriodSummaryCopyWith<$Res> {
  _$PeriodSummaryCopyWithImpl(this._self, this._then);

  final PeriodSummary _self;
  final $Res Function(PeriodSummary) _then;

/// Create a copy of PeriodSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? incomeCents = null,Object? expenseCents = null,}) {
  return _then(PeriodSummary(
incomeCents: null == incomeCents ? _self.incomeCents : incomeCents // ignore: cast_nullable_to_non_nullable
as int,expenseCents: null == expenseCents ? _self.expenseCents : expenseCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodSummary].
extension PeriodSummaryPatterns on PeriodSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodSummary value)  $default,){
final _that = this;
switch (_that) {
case _PeriodSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int incomeCents,  int expenseCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodSummary() when $default != null:
return $default(_that.incomeCents,_that.expenseCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int incomeCents,  int expenseCents)  $default,) {final _that = this;
switch (_that) {
case _PeriodSummary():
return $default(_that.incomeCents,_that.expenseCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int incomeCents,  int expenseCents)?  $default,) {final _that = this;
switch (_that) {
case _PeriodSummary() when $default != null:
return $default(_that.incomeCents,_that.expenseCents);case _:
  return null;

}
}

}

/// @nodoc


class _PeriodSummary extends PeriodSummary {
  const _PeriodSummary({required this.incomeCents, required this.expenseCents}): super._();
  

@override final  int incomeCents;
@override final  int expenseCents;

/// Create a copy of PeriodSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodSummaryCopyWith<_PeriodSummary> get copyWith => __$PeriodSummaryCopyWithImpl<_PeriodSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodSummary&&(identical(other.incomeCents, incomeCents) || other.incomeCents == incomeCents)&&(identical(other.expenseCents, expenseCents) || other.expenseCents == expenseCents));
}


@override
int get hashCode {
    return Object.hash(runtimeType,incomeCents,expenseCents);
}

@override
String toString() {
    return 'PeriodSummary(incomeCents: $incomeCents, expenseCents: $expenseCents)';
}


}

/// @nodoc
abstract mixin class _$PeriodSummaryCopyWith<$Res> implements $PeriodSummaryCopyWith<$Res> {
  factory _$PeriodSummaryCopyWith(_PeriodSummary value, $Res Function(_PeriodSummary) _then) = __$PeriodSummaryCopyWithImpl;
@override @useResult
$Res call({
 int incomeCents, int expenseCents
});




}
/// @nodoc
class __$PeriodSummaryCopyWithImpl<$Res>
    implements _$PeriodSummaryCopyWith<$Res> {
  __$PeriodSummaryCopyWithImpl(this._self, this._then);

  final _PeriodSummary _self;
  final $Res Function(_PeriodSummary) _then;

/// Create a copy of PeriodSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? incomeCents = null,Object? expenseCents = null,}) {
  return _then(_PeriodSummary(
incomeCents: null == incomeCents ? _self.incomeCents : incomeCents // ignore: cast_nullable_to_non_nullable
as int,expenseCents: null == expenseCents ? _self.expenseCents : expenseCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$BreakdownItem {

/// ID della categoria o della label; null = "Senza label".
 String? get id; int get totalCents;/// Quota sul totale del grafico, tra 0 e 1.
 double get share;
/// Create a copy of BreakdownItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreakdownItemCopyWith<BreakdownItem> get copyWith => _$BreakdownItemCopyWithImpl<BreakdownItem>(this as BreakdownItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BreakdownItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BreakdownItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.totalCents, _this.totalCents) || other.totalCents == _this.totalCents)&&(identical(other.share, _this.share) || other.share == _this.share));
}


@override
int get hashCode {
  final _this = this as BreakdownItem;
  return Object.hash(runtimeType,_this.id,_this.totalCents,_this.share);
}

@override
String toString() {
  final _this = this as BreakdownItem;
  return 'BreakdownItem(id: ${_this.id}, totalCents: ${_this.totalCents}, share: ${_this.share})';
}


}

/// @nodoc
abstract mixin class $BreakdownItemCopyWith<$Res>  {
  factory $BreakdownItemCopyWith(BreakdownItem value, $Res Function(BreakdownItem) _then) = _$BreakdownItemCopyWithImpl;
@useResult
$Res call({
 String? id, int totalCents, double share
});




}
/// @nodoc
class _$BreakdownItemCopyWithImpl<$Res>
    implements $BreakdownItemCopyWith<$Res> {
  _$BreakdownItemCopyWithImpl(this._self, this._then);

  final BreakdownItem _self;
  final $Res Function(BreakdownItem) _then;

/// Create a copy of BreakdownItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? totalCents = null,Object? share = null,}) {
  return _then(BreakdownItem(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,totalCents: null == totalCents ? _self.totalCents : totalCents // ignore: cast_nullable_to_non_nullable
as int,share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BreakdownItem].
extension BreakdownItemPatterns on BreakdownItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BreakdownItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BreakdownItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BreakdownItem value)  $default,){
final _that = this;
switch (_that) {
case _BreakdownItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BreakdownItem value)?  $default,){
final _that = this;
switch (_that) {
case _BreakdownItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  int totalCents,  double share)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BreakdownItem() when $default != null:
return $default(_that.id,_that.totalCents,_that.share);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  int totalCents,  double share)  $default,) {final _that = this;
switch (_that) {
case _BreakdownItem():
return $default(_that.id,_that.totalCents,_that.share);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  int totalCents,  double share)?  $default,) {final _that = this;
switch (_that) {
case _BreakdownItem() when $default != null:
return $default(_that.id,_that.totalCents,_that.share);case _:
  return null;

}
}

}

/// @nodoc


class _BreakdownItem implements BreakdownItem {
  const _BreakdownItem({required this.id, required this.totalCents, required this.share});
  

/// ID della categoria o della label; null = "Senza label".
@override final  String? id;
@override final  int totalCents;
/// Quota sul totale del grafico, tra 0 e 1.
@override final  double share;

/// Create a copy of BreakdownItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BreakdownItemCopyWith<_BreakdownItem> get copyWith => __$BreakdownItemCopyWithImpl<_BreakdownItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BreakdownItem&&(identical(other.id, id) || other.id == id)&&(identical(other.totalCents, totalCents) || other.totalCents == totalCents)&&(identical(other.share, share) || other.share == share));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,totalCents,share);
}

@override
String toString() {
    return 'BreakdownItem(id: $id, totalCents: $totalCents, share: $share)';
}


}

/// @nodoc
abstract mixin class _$BreakdownItemCopyWith<$Res> implements $BreakdownItemCopyWith<$Res> {
  factory _$BreakdownItemCopyWith(_BreakdownItem value, $Res Function(_BreakdownItem) _then) = __$BreakdownItemCopyWithImpl;
@override @useResult
$Res call({
 String? id, int totalCents, double share
});




}
/// @nodoc
class __$BreakdownItemCopyWithImpl<$Res>
    implements _$BreakdownItemCopyWith<$Res> {
  __$BreakdownItemCopyWithImpl(this._self, this._then);

  final _BreakdownItem _self;
  final $Res Function(_BreakdownItem) _then;

/// Create a copy of BreakdownItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? totalCents = null,Object? share = null,}) {
  return _then(_BreakdownItem(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,totalCents: null == totalCents ? _self.totalCents : totalCents // ignore: cast_nullable_to_non_nullable
as int,share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
