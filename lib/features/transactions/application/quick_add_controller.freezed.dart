// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quick_add_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuickAddState {

 TransactionType get type; LocalDate get date; int get amountCents; String? get categoryId; Set<String> get labelIds;/// Portafogli scelti a mano, uno per tipo (null = usa il predefinito).
 String? get expenseWalletId; String? get incomeWalletId; String get note;/// Diventa true al primo tentativo di salvataggio: da lì si mostrano gli errori.
 bool get showErrors; bool get saving;
/// Create a copy of QuickAddState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuickAddStateCopyWith<QuickAddState> get copyWith => _$QuickAddStateCopyWithImpl<QuickAddState>(this as QuickAddState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as QuickAddState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickAddState&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.amountCents, _this.amountCents) || other.amountCents == _this.amountCents)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&const DeepCollectionEquality().equals(other.labelIds, _this.labelIds)&&(identical(other.expenseWalletId, _this.expenseWalletId) || other.expenseWalletId == _this.expenseWalletId)&&(identical(other.incomeWalletId, _this.incomeWalletId) || other.incomeWalletId == _this.incomeWalletId)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.showErrors, _this.showErrors) || other.showErrors == _this.showErrors)&&(identical(other.saving, _this.saving) || other.saving == _this.saving));
}


@override
int get hashCode {
  final _this = this as QuickAddState;
  return Object.hash(runtimeType,_this.type,_this.date,_this.amountCents,_this.categoryId,const DeepCollectionEquality().hash(_this.labelIds),_this.expenseWalletId,_this.incomeWalletId,_this.note,_this.showErrors,_this.saving);
}

@override
String toString() {
  final _this = this as QuickAddState;
  return 'QuickAddState(type: ${_this.type}, date: ${_this.date}, amountCents: ${_this.amountCents}, categoryId: ${_this.categoryId}, labelIds: ${_this.labelIds}, expenseWalletId: ${_this.expenseWalletId}, incomeWalletId: ${_this.incomeWalletId}, note: ${_this.note}, showErrors: ${_this.showErrors}, saving: ${_this.saving})';
}


}

/// @nodoc
abstract mixin class $QuickAddStateCopyWith<$Res>  {
  factory $QuickAddStateCopyWith(QuickAddState value, $Res Function(QuickAddState) _then) = _$QuickAddStateCopyWithImpl;
@useResult
$Res call({
 TransactionType type, LocalDate date, int amountCents, String? categoryId, Set<String> labelIds, String? expenseWalletId, String? incomeWalletId, String note, bool showErrors, bool saving
});




}
/// @nodoc
class _$QuickAddStateCopyWithImpl<$Res>
    implements $QuickAddStateCopyWith<$Res> {
  _$QuickAddStateCopyWithImpl(this._self, this._then);

  final QuickAddState _self;
  final $Res Function(QuickAddState) _then;

/// Create a copy of QuickAddState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? date = null,Object? amountCents = null,Object? categoryId = freezed,Object? labelIds = null,Object? expenseWalletId = freezed,Object? incomeWalletId = freezed,Object? note = null,Object? showErrors = null,Object? saving = null,}) {
  return _then(QuickAddState(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,labelIds: null == labelIds ? _self.labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as Set<String>,expenseWalletId: freezed == expenseWalletId ? _self.expenseWalletId : expenseWalletId // ignore: cast_nullable_to_non_nullable
as String?,incomeWalletId: freezed == incomeWalletId ? _self.incomeWalletId : incomeWalletId // ignore: cast_nullable_to_non_nullable
as String?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,showErrors: null == showErrors ? _self.showErrors : showErrors // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [QuickAddState].
extension QuickAddStatePatterns on QuickAddState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuickAddState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuickAddState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuickAddState value)  $default,){
final _that = this;
switch (_that) {
case _QuickAddState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuickAddState value)?  $default,){
final _that = this;
switch (_that) {
case _QuickAddState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TransactionType type,  LocalDate date,  int amountCents,  String? categoryId,  Set<String> labelIds,  String? expenseWalletId,  String? incomeWalletId,  String note,  bool showErrors,  bool saving)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuickAddState() when $default != null:
return $default(_that.type,_that.date,_that.amountCents,_that.categoryId,_that.labelIds,_that.expenseWalletId,_that.incomeWalletId,_that.note,_that.showErrors,_that.saving);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TransactionType type,  LocalDate date,  int amountCents,  String? categoryId,  Set<String> labelIds,  String? expenseWalletId,  String? incomeWalletId,  String note,  bool showErrors,  bool saving)  $default,) {final _that = this;
switch (_that) {
case _QuickAddState():
return $default(_that.type,_that.date,_that.amountCents,_that.categoryId,_that.labelIds,_that.expenseWalletId,_that.incomeWalletId,_that.note,_that.showErrors,_that.saving);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TransactionType type,  LocalDate date,  int amountCents,  String? categoryId,  Set<String> labelIds,  String? expenseWalletId,  String? incomeWalletId,  String note,  bool showErrors,  bool saving)?  $default,) {final _that = this;
switch (_that) {
case _QuickAddState() when $default != null:
return $default(_that.type,_that.date,_that.amountCents,_that.categoryId,_that.labelIds,_that.expenseWalletId,_that.incomeWalletId,_that.note,_that.showErrors,_that.saving);case _:
  return null;

}
}

}

/// @nodoc


class _QuickAddState extends QuickAddState {
  const _QuickAddState({required this.type, required this.date, this.amountCents = 0, this.categoryId,  Set<String> labelIds = const <String>{}, this.expenseWalletId, this.incomeWalletId, this.note = '', this.showErrors = false, this.saving = false}): _labelIds = labelIds,super._();
  

@override final  TransactionType type;
@override final  LocalDate date;
@override@JsonKey() final  int amountCents;
@override final  String? categoryId;
 final  Set<String> _labelIds;
@override@JsonKey() Set<String> get labelIds {
  if (_labelIds is EqualUnmodifiableSetView) return _labelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_labelIds);
}

/// Portafogli scelti a mano, uno per tipo (null = usa il predefinito).
@override final  String? expenseWalletId;
@override final  String? incomeWalletId;
@override@JsonKey() final  String note;
/// Diventa true al primo tentativo di salvataggio: da lì si mostrano gli errori.
@override@JsonKey() final  bool showErrors;
@override@JsonKey() final  bool saving;

/// Create a copy of QuickAddState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuickAddStateCopyWith<_QuickAddState> get copyWith => __$QuickAddStateCopyWithImpl<_QuickAddState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuickAddState&&(identical(other.type, type) || other.type == type)&&(identical(other.date, date) || other.date == date)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other.labelIds, _labelIds)&&(identical(other.expenseWalletId, expenseWalletId) || other.expenseWalletId == expenseWalletId)&&(identical(other.incomeWalletId, incomeWalletId) || other.incomeWalletId == incomeWalletId)&&(identical(other.note, note) || other.note == note)&&(identical(other.showErrors, showErrors) || other.showErrors == showErrors)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,date,amountCents,categoryId,const DeepCollectionEquality().hash(_labelIds),expenseWalletId,incomeWalletId,note,showErrors,saving);
}

@override
String toString() {
    return 'QuickAddState(type: $type, date: $date, amountCents: $amountCents, categoryId: $categoryId, labelIds: $labelIds, expenseWalletId: $expenseWalletId, incomeWalletId: $incomeWalletId, note: $note, showErrors: $showErrors, saving: $saving)';
}


}

/// @nodoc
abstract mixin class _$QuickAddStateCopyWith<$Res> implements $QuickAddStateCopyWith<$Res> {
  factory _$QuickAddStateCopyWith(_QuickAddState value, $Res Function(_QuickAddState) _then) = __$QuickAddStateCopyWithImpl;
@override @useResult
$Res call({
 TransactionType type, LocalDate date, int amountCents, String? categoryId, Set<String> labelIds, String? expenseWalletId, String? incomeWalletId, String note, bool showErrors, bool saving
});




}
/// @nodoc
class __$QuickAddStateCopyWithImpl<$Res>
    implements _$QuickAddStateCopyWith<$Res> {
  __$QuickAddStateCopyWithImpl(this._self, this._then);

  final _QuickAddState _self;
  final $Res Function(_QuickAddState) _then;

/// Create a copy of QuickAddState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? date = null,Object? amountCents = null,Object? categoryId = freezed,Object? labelIds = null,Object? expenseWalletId = freezed,Object? incomeWalletId = freezed,Object? note = null,Object? showErrors = null,Object? saving = null,}) {
  return _then(_QuickAddState(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,labelIds: null == labelIds ? _self._labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as Set<String>,expenseWalletId: freezed == expenseWalletId ? _self.expenseWalletId : expenseWalletId // ignore: cast_nullable_to_non_nullable
as String?,incomeWalletId: freezed == incomeWalletId ? _self.incomeWalletId : incomeWalletId // ignore: cast_nullable_to_non_nullable
as String?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,showErrors: null == showErrors ? _self.showErrors : showErrors // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
