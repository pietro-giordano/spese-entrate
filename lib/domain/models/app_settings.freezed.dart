// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppSettings {

 String? get defaultExpenseWalletId; String? get defaultIncomeWalletId;/// 1 = lunedì … 7 = domenica.
 int get weekStart; PeriodType get defaultPeriod; String get currency;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.defaultExpenseWalletId, _this.defaultExpenseWalletId) || other.defaultExpenseWalletId == _this.defaultExpenseWalletId)&&(identical(other.defaultIncomeWalletId, _this.defaultIncomeWalletId) || other.defaultIncomeWalletId == _this.defaultIncomeWalletId)&&(identical(other.weekStart, _this.weekStart) || other.weekStart == _this.weekStart)&&(identical(other.defaultPeriod, _this.defaultPeriod) || other.defaultPeriod == _this.defaultPeriod)&&(identical(other.currency, _this.currency) || other.currency == _this.currency));
}


@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hash(runtimeType,_this.defaultExpenseWalletId,_this.defaultIncomeWalletId,_this.weekStart,_this.defaultPeriod,_this.currency);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(defaultExpenseWalletId: ${_this.defaultExpenseWalletId}, defaultIncomeWalletId: ${_this.defaultIncomeWalletId}, weekStart: ${_this.weekStart}, defaultPeriod: ${_this.defaultPeriod}, currency: ${_this.currency})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 String? defaultExpenseWalletId, String? defaultIncomeWalletId, int weekStart, PeriodType defaultPeriod, String currency
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? defaultExpenseWalletId = freezed,Object? defaultIncomeWalletId = freezed,Object? weekStart = null,Object? defaultPeriod = null,Object? currency = null,}) {
  return _then(AppSettings(
defaultExpenseWalletId: freezed == defaultExpenseWalletId ? _self.defaultExpenseWalletId : defaultExpenseWalletId // ignore: cast_nullable_to_non_nullable
as String?,defaultIncomeWalletId: freezed == defaultIncomeWalletId ? _self.defaultIncomeWalletId : defaultIncomeWalletId // ignore: cast_nullable_to_non_nullable
as String?,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as int,defaultPeriod: null == defaultPeriod ? _self.defaultPeriod : defaultPeriod // ignore: cast_nullable_to_non_nullable
as PeriodType,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? defaultExpenseWalletId,  String? defaultIncomeWalletId,  int weekStart,  PeriodType defaultPeriod,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.defaultExpenseWalletId,_that.defaultIncomeWalletId,_that.weekStart,_that.defaultPeriod,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? defaultExpenseWalletId,  String? defaultIncomeWalletId,  int weekStart,  PeriodType defaultPeriod,  String currency)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.defaultExpenseWalletId,_that.defaultIncomeWalletId,_that.weekStart,_that.defaultPeriod,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? defaultExpenseWalletId,  String? defaultIncomeWalletId,  int weekStart,  PeriodType defaultPeriod,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.defaultExpenseWalletId,_that.defaultIncomeWalletId,_that.weekStart,_that.defaultPeriod,_that.currency);case _:
  return null;

}
}

}

/// @nodoc


class _AppSettings implements AppSettings {
  const _AppSettings({this.defaultExpenseWalletId, this.defaultIncomeWalletId, this.weekStart = DateTime.monday, this.defaultPeriod = PeriodType.month, this.currency = 'EUR'});
  

@override final  String? defaultExpenseWalletId;
@override final  String? defaultIncomeWalletId;
/// 1 = lunedì … 7 = domenica.
@override@JsonKey() final  int weekStart;
@override@JsonKey() final  PeriodType defaultPeriod;
@override@JsonKey() final  String currency;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.defaultExpenseWalletId, defaultExpenseWalletId) || other.defaultExpenseWalletId == defaultExpenseWalletId)&&(identical(other.defaultIncomeWalletId, defaultIncomeWalletId) || other.defaultIncomeWalletId == defaultIncomeWalletId)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.defaultPeriod, defaultPeriod) || other.defaultPeriod == defaultPeriod)&&(identical(other.currency, currency) || other.currency == currency));
}


@override
int get hashCode {
    return Object.hash(runtimeType,defaultExpenseWalletId,defaultIncomeWalletId,weekStart,defaultPeriod,currency);
}

@override
String toString() {
    return 'AppSettings(defaultExpenseWalletId: $defaultExpenseWalletId, defaultIncomeWalletId: $defaultIncomeWalletId, weekStart: $weekStart, defaultPeriod: $defaultPeriod, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 String? defaultExpenseWalletId, String? defaultIncomeWalletId, int weekStart, PeriodType defaultPeriod, String currency
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? defaultExpenseWalletId = freezed,Object? defaultIncomeWalletId = freezed,Object? weekStart = null,Object? defaultPeriod = null,Object? currency = null,}) {
  return _then(_AppSettings(
defaultExpenseWalletId: freezed == defaultExpenseWalletId ? _self.defaultExpenseWalletId : defaultExpenseWalletId // ignore: cast_nullable_to_non_nullable
as String?,defaultIncomeWalletId: freezed == defaultIncomeWalletId ? _self.defaultIncomeWalletId : defaultIncomeWalletId // ignore: cast_nullable_to_non_nullable
as String?,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as int,defaultPeriod: null == defaultPeriod ? _self.defaultPeriod : defaultPeriod // ignore: cast_nullable_to_non_nullable
as PeriodType,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
