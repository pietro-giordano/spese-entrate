// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurrence_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RecurrenceRule {

 String get id; String get name; TransactionType get type; int get amountCents; String get currency; String get walletId; String? get toWalletId; String? get categoryId; String? get note; List<String> get labelIds; RecurrenceFrequency get frequency; int get interval;/// 1 = lunedì … 7 = domenica.
 int? get byWeekday; int? get byMonthDay; int? get byMonth; LocalDate get startDate; LocalDate? get endDate; int? get maxCount; RecurrenceMode get mode; DateTime? get pausedAt;
/// Create a copy of RecurrenceRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurrenceRuleCopyWith<RecurrenceRule> get copyWith => _$RecurrenceRuleCopyWithImpl<RecurrenceRule>(this as RecurrenceRule, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RecurrenceRule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurrenceRule&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.amountCents, _this.amountCents) || other.amountCents == _this.amountCents)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.walletId, _this.walletId) || other.walletId == _this.walletId)&&(identical(other.toWalletId, _this.toWalletId) || other.toWalletId == _this.toWalletId)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.note, _this.note) || other.note == _this.note)&&const DeepCollectionEquality().equals(other.labelIds, _this.labelIds)&&(identical(other.frequency, _this.frequency) || other.frequency == _this.frequency)&&(identical(other.interval, _this.interval) || other.interval == _this.interval)&&(identical(other.byWeekday, _this.byWeekday) || other.byWeekday == _this.byWeekday)&&(identical(other.byMonthDay, _this.byMonthDay) || other.byMonthDay == _this.byMonthDay)&&(identical(other.byMonth, _this.byMonth) || other.byMonth == _this.byMonth)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.maxCount, _this.maxCount) || other.maxCount == _this.maxCount)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.pausedAt, _this.pausedAt) || other.pausedAt == _this.pausedAt));
}


@override
int get hashCode {
  final _this = this as RecurrenceRule;
  return Object.hashAll([runtimeType,_this.id,_this.name,_this.type,_this.amountCents,_this.currency,_this.walletId,_this.toWalletId,_this.categoryId,_this.note,const DeepCollectionEquality().hash(_this.labelIds),_this.frequency,_this.interval,_this.byWeekday,_this.byMonthDay,_this.byMonth,_this.startDate,_this.endDate,_this.maxCount,_this.mode,_this.pausedAt]);
}

@override
String toString() {
  final _this = this as RecurrenceRule;
  return 'RecurrenceRule(id: ${_this.id}, name: ${_this.name}, type: ${_this.type}, amountCents: ${_this.amountCents}, currency: ${_this.currency}, walletId: ${_this.walletId}, toWalletId: ${_this.toWalletId}, categoryId: ${_this.categoryId}, note: ${_this.note}, labelIds: ${_this.labelIds}, frequency: ${_this.frequency}, interval: ${_this.interval}, byWeekday: ${_this.byWeekday}, byMonthDay: ${_this.byMonthDay}, byMonth: ${_this.byMonth}, startDate: ${_this.startDate}, endDate: ${_this.endDate}, maxCount: ${_this.maxCount}, mode: ${_this.mode}, pausedAt: ${_this.pausedAt})';
}


}

/// @nodoc
abstract mixin class $RecurrenceRuleCopyWith<$Res>  {
  factory $RecurrenceRuleCopyWith(RecurrenceRule value, $Res Function(RecurrenceRule) _then) = _$RecurrenceRuleCopyWithImpl;
@useResult
$Res call({
 String id, String name, TransactionType type, int amountCents, String currency, String walletId, String? toWalletId, String? categoryId, String? note, List<String> labelIds, RecurrenceFrequency frequency, int interval, int? byWeekday, int? byMonthDay, int? byMonth, LocalDate startDate, LocalDate? endDate, int? maxCount, RecurrenceMode mode, DateTime? pausedAt
});




}
/// @nodoc
class _$RecurrenceRuleCopyWithImpl<$Res>
    implements $RecurrenceRuleCopyWith<$Res> {
  _$RecurrenceRuleCopyWithImpl(this._self, this._then);

  final RecurrenceRule _self;
  final $Res Function(RecurrenceRule) _then;

/// Create a copy of RecurrenceRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? amountCents = null,Object? currency = null,Object? walletId = null,Object? toWalletId = freezed,Object? categoryId = freezed,Object? note = freezed,Object? labelIds = null,Object? frequency = null,Object? interval = null,Object? byWeekday = freezed,Object? byMonthDay = freezed,Object? byMonth = freezed,Object? startDate = null,Object? endDate = freezed,Object? maxCount = freezed,Object? mode = null,Object? pausedAt = freezed,}) {
  return _then(RecurrenceRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,walletId: null == walletId ? _self.walletId : walletId // ignore: cast_nullable_to_non_nullable
as String,toWalletId: freezed == toWalletId ? _self.toWalletId : toWalletId // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,labelIds: null == labelIds ? _self.labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as List<String>,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,byWeekday: freezed == byWeekday ? _self.byWeekday : byWeekday // ignore: cast_nullable_to_non_nullable
as int?,byMonthDay: freezed == byMonthDay ? _self.byMonthDay : byMonthDay // ignore: cast_nullable_to_non_nullable
as int?,byMonth: freezed == byMonth ? _self.byMonth : byMonth // ignore: cast_nullable_to_non_nullable
as int?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as LocalDate,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,maxCount: freezed == maxCount ? _self.maxCount : maxCount // ignore: cast_nullable_to_non_nullable
as int?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RecurrenceMode,pausedAt: freezed == pausedAt ? _self.pausedAt : pausedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurrenceRule].
extension RecurrenceRulePatterns on RecurrenceRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurrenceRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurrenceRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurrenceRule value)  $default,){
final _that = this;
switch (_that) {
case _RecurrenceRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurrenceRule value)?  $default,){
final _that = this;
switch (_that) {
case _RecurrenceRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  TransactionType type,  int amountCents,  String currency,  String walletId,  String? toWalletId,  String? categoryId,  String? note,  List<String> labelIds,  RecurrenceFrequency frequency,  int interval,  int? byWeekday,  int? byMonthDay,  int? byMonth,  LocalDate startDate,  LocalDate? endDate,  int? maxCount,  RecurrenceMode mode,  DateTime? pausedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurrenceRule() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.amountCents,_that.currency,_that.walletId,_that.toWalletId,_that.categoryId,_that.note,_that.labelIds,_that.frequency,_that.interval,_that.byWeekday,_that.byMonthDay,_that.byMonth,_that.startDate,_that.endDate,_that.maxCount,_that.mode,_that.pausedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  TransactionType type,  int amountCents,  String currency,  String walletId,  String? toWalletId,  String? categoryId,  String? note,  List<String> labelIds,  RecurrenceFrequency frequency,  int interval,  int? byWeekday,  int? byMonthDay,  int? byMonth,  LocalDate startDate,  LocalDate? endDate,  int? maxCount,  RecurrenceMode mode,  DateTime? pausedAt)  $default,) {final _that = this;
switch (_that) {
case _RecurrenceRule():
return $default(_that.id,_that.name,_that.type,_that.amountCents,_that.currency,_that.walletId,_that.toWalletId,_that.categoryId,_that.note,_that.labelIds,_that.frequency,_that.interval,_that.byWeekday,_that.byMonthDay,_that.byMonth,_that.startDate,_that.endDate,_that.maxCount,_that.mode,_that.pausedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  TransactionType type,  int amountCents,  String currency,  String walletId,  String? toWalletId,  String? categoryId,  String? note,  List<String> labelIds,  RecurrenceFrequency frequency,  int interval,  int? byWeekday,  int? byMonthDay,  int? byMonth,  LocalDate startDate,  LocalDate? endDate,  int? maxCount,  RecurrenceMode mode,  DateTime? pausedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecurrenceRule() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.amountCents,_that.currency,_that.walletId,_that.toWalletId,_that.categoryId,_that.note,_that.labelIds,_that.frequency,_that.interval,_that.byWeekday,_that.byMonthDay,_that.byMonth,_that.startDate,_that.endDate,_that.maxCount,_that.mode,_that.pausedAt);case _:
  return null;

}
}

}

/// @nodoc


class _RecurrenceRule extends RecurrenceRule {
  const _RecurrenceRule({required this.id, required this.name, required this.type, required this.amountCents, this.currency = 'EUR', required this.walletId, this.toWalletId, this.categoryId, this.note,  List<String> labelIds = const [], required this.frequency, this.interval = 1, this.byWeekday, this.byMonthDay, this.byMonth, required this.startDate, this.endDate, this.maxCount, required this.mode, this.pausedAt}): _labelIds = labelIds,super._();
  

@override final  String id;
@override final  String name;
@override final  TransactionType type;
@override final  int amountCents;
@override@JsonKey() final  String currency;
@override final  String walletId;
@override final  String? toWalletId;
@override final  String? categoryId;
@override final  String? note;
 final  List<String> _labelIds;
@override@JsonKey() List<String> get labelIds {
  if (_labelIds is EqualUnmodifiableListView) return _labelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_labelIds);
}

@override final  RecurrenceFrequency frequency;
@override@JsonKey() final  int interval;
/// 1 = lunedì … 7 = domenica.
@override final  int? byWeekday;
@override final  int? byMonthDay;
@override final  int? byMonth;
@override final  LocalDate startDate;
@override final  LocalDate? endDate;
@override final  int? maxCount;
@override final  RecurrenceMode mode;
@override final  DateTime? pausedAt;

/// Create a copy of RecurrenceRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurrenceRuleCopyWith<_RecurrenceRule> get copyWith => __$RecurrenceRuleCopyWithImpl<_RecurrenceRule>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurrenceRule&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.walletId, walletId) || other.walletId == walletId)&&(identical(other.toWalletId, toWalletId) || other.toWalletId == toWalletId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.labelIds, _labelIds)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.byWeekday, byWeekday) || other.byWeekday == byWeekday)&&(identical(other.byMonthDay, byMonthDay) || other.byMonthDay == byMonthDay)&&(identical(other.byMonth, byMonth) || other.byMonth == byMonth)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.maxCount, maxCount) || other.maxCount == maxCount)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.pausedAt, pausedAt) || other.pausedAt == pausedAt));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,name,type,amountCents,currency,walletId,toWalletId,categoryId,note,const DeepCollectionEquality().hash(_labelIds),frequency,interval,byWeekday,byMonthDay,byMonth,startDate,endDate,maxCount,mode,pausedAt]);
}

@override
String toString() {
    return 'RecurrenceRule(id: $id, name: $name, type: $type, amountCents: $amountCents, currency: $currency, walletId: $walletId, toWalletId: $toWalletId, categoryId: $categoryId, note: $note, labelIds: $labelIds, frequency: $frequency, interval: $interval, byWeekday: $byWeekday, byMonthDay: $byMonthDay, byMonth: $byMonth, startDate: $startDate, endDate: $endDate, maxCount: $maxCount, mode: $mode, pausedAt: $pausedAt)';
}


}

/// @nodoc
abstract mixin class _$RecurrenceRuleCopyWith<$Res> implements $RecurrenceRuleCopyWith<$Res> {
  factory _$RecurrenceRuleCopyWith(_RecurrenceRule value, $Res Function(_RecurrenceRule) _then) = __$RecurrenceRuleCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, TransactionType type, int amountCents, String currency, String walletId, String? toWalletId, String? categoryId, String? note, List<String> labelIds, RecurrenceFrequency frequency, int interval, int? byWeekday, int? byMonthDay, int? byMonth, LocalDate startDate, LocalDate? endDate, int? maxCount, RecurrenceMode mode, DateTime? pausedAt
});




}
/// @nodoc
class __$RecurrenceRuleCopyWithImpl<$Res>
    implements _$RecurrenceRuleCopyWith<$Res> {
  __$RecurrenceRuleCopyWithImpl(this._self, this._then);

  final _RecurrenceRule _self;
  final $Res Function(_RecurrenceRule) _then;

/// Create a copy of RecurrenceRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? amountCents = null,Object? currency = null,Object? walletId = null,Object? toWalletId = freezed,Object? categoryId = freezed,Object? note = freezed,Object? labelIds = null,Object? frequency = null,Object? interval = null,Object? byWeekday = freezed,Object? byMonthDay = freezed,Object? byMonth = freezed,Object? startDate = null,Object? endDate = freezed,Object? maxCount = freezed,Object? mode = null,Object? pausedAt = freezed,}) {
  return _then(_RecurrenceRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,walletId: null == walletId ? _self.walletId : walletId // ignore: cast_nullable_to_non_nullable
as String,toWalletId: freezed == toWalletId ? _self.toWalletId : toWalletId // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,labelIds: null == labelIds ? _self._labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as List<String>,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,byWeekday: freezed == byWeekday ? _self.byWeekday : byWeekday // ignore: cast_nullable_to_non_nullable
as int?,byMonthDay: freezed == byMonthDay ? _self.byMonthDay : byMonthDay // ignore: cast_nullable_to_non_nullable
as int?,byMonth: freezed == byMonth ? _self.byMonth : byMonth // ignore: cast_nullable_to_non_nullable
as int?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as LocalDate,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,maxCount: freezed == maxCount ? _self.maxCount : maxCount // ignore: cast_nullable_to_non_nullable
as int?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RecurrenceMode,pausedAt: freezed == pausedAt ? _self.pausedAt : pausedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
