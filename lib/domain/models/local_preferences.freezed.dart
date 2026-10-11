// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'local_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocalPreferences {

 AppThemeMode get themeMode;/// Chiede la biometria all'apertura e al ritorno dopo 1 minuto in background.
 bool get biometricLock;/// Profilo facoltativo, solo locale.
 String? get profileName; String? get profileEmail;
/// Create a copy of LocalPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalPreferencesCopyWith<LocalPreferences> get copyWith => _$LocalPreferencesCopyWithImpl<LocalPreferences>(this as LocalPreferences, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LocalPreferences;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalPreferences&&(identical(other.themeMode, _this.themeMode) || other.themeMode == _this.themeMode)&&(identical(other.biometricLock, _this.biometricLock) || other.biometricLock == _this.biometricLock)&&(identical(other.profileName, _this.profileName) || other.profileName == _this.profileName)&&(identical(other.profileEmail, _this.profileEmail) || other.profileEmail == _this.profileEmail));
}


@override
int get hashCode {
  final _this = this as LocalPreferences;
  return Object.hash(runtimeType,_this.themeMode,_this.biometricLock,_this.profileName,_this.profileEmail);
}

@override
String toString() {
  final _this = this as LocalPreferences;
  return 'LocalPreferences(themeMode: ${_this.themeMode}, biometricLock: ${_this.biometricLock}, profileName: ${_this.profileName}, profileEmail: ${_this.profileEmail})';
}


}

/// @nodoc
abstract mixin class $LocalPreferencesCopyWith<$Res>  {
  factory $LocalPreferencesCopyWith(LocalPreferences value, $Res Function(LocalPreferences) _then) = _$LocalPreferencesCopyWithImpl;
@useResult
$Res call({
 AppThemeMode themeMode, bool biometricLock, String? profileName, String? profileEmail
});




}
/// @nodoc
class _$LocalPreferencesCopyWithImpl<$Res>
    implements $LocalPreferencesCopyWith<$Res> {
  _$LocalPreferencesCopyWithImpl(this._self, this._then);

  final LocalPreferences _self;
  final $Res Function(LocalPreferences) _then;

/// Create a copy of LocalPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? biometricLock = null,Object? profileName = freezed,Object? profileEmail = freezed,}) {
  return _then(LocalPreferences(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,biometricLock: null == biometricLock ? _self.biometricLock : biometricLock // ignore: cast_nullable_to_non_nullable
as bool,profileName: freezed == profileName ? _self.profileName : profileName // ignore: cast_nullable_to_non_nullable
as String?,profileEmail: freezed == profileEmail ? _self.profileEmail : profileEmail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalPreferences].
extension LocalPreferencesPatterns on LocalPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalPreferences value)  $default,){
final _that = this;
switch (_that) {
case _LocalPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _LocalPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppThemeMode themeMode,  bool biometricLock,  String? profileName,  String? profileEmail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalPreferences() when $default != null:
return $default(_that.themeMode,_that.biometricLock,_that.profileName,_that.profileEmail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppThemeMode themeMode,  bool biometricLock,  String? profileName,  String? profileEmail)  $default,) {final _that = this;
switch (_that) {
case _LocalPreferences():
return $default(_that.themeMode,_that.biometricLock,_that.profileName,_that.profileEmail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppThemeMode themeMode,  bool biometricLock,  String? profileName,  String? profileEmail)?  $default,) {final _that = this;
switch (_that) {
case _LocalPreferences() when $default != null:
return $default(_that.themeMode,_that.biometricLock,_that.profileName,_that.profileEmail);case _:
  return null;

}
}

}

/// @nodoc


class _LocalPreferences implements LocalPreferences {
  const _LocalPreferences({this.themeMode = AppThemeMode.system, this.biometricLock = false, this.profileName, this.profileEmail});
  

@override@JsonKey() final  AppThemeMode themeMode;
/// Chiede la biometria all'apertura e al ritorno dopo 1 minuto in background.
@override@JsonKey() final  bool biometricLock;
/// Profilo facoltativo, solo locale.
@override final  String? profileName;
@override final  String? profileEmail;

/// Create a copy of LocalPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalPreferencesCopyWith<_LocalPreferences> get copyWith => __$LocalPreferencesCopyWithImpl<_LocalPreferences>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalPreferences&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.biometricLock, biometricLock) || other.biometricLock == biometricLock)&&(identical(other.profileName, profileName) || other.profileName == profileName)&&(identical(other.profileEmail, profileEmail) || other.profileEmail == profileEmail));
}


@override
int get hashCode {
    return Object.hash(runtimeType,themeMode,biometricLock,profileName,profileEmail);
}

@override
String toString() {
    return 'LocalPreferences(themeMode: $themeMode, biometricLock: $biometricLock, profileName: $profileName, profileEmail: $profileEmail)';
}


}

/// @nodoc
abstract mixin class _$LocalPreferencesCopyWith<$Res> implements $LocalPreferencesCopyWith<$Res> {
  factory _$LocalPreferencesCopyWith(_LocalPreferences value, $Res Function(_LocalPreferences) _then) = __$LocalPreferencesCopyWithImpl;
@override @useResult
$Res call({
 AppThemeMode themeMode, bool biometricLock, String? profileName, String? profileEmail
});




}
/// @nodoc
class __$LocalPreferencesCopyWithImpl<$Res>
    implements _$LocalPreferencesCopyWith<$Res> {
  __$LocalPreferencesCopyWithImpl(this._self, this._then);

  final _LocalPreferences _self;
  final $Res Function(_LocalPreferences) _then;

/// Create a copy of LocalPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? biometricLock = null,Object? profileName = freezed,Object? profileEmail = freezed,}) {
  return _then(_LocalPreferences(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as AppThemeMode,biometricLock: null == biometricLock ? _self.biometricLock : biometricLock // ignore: cast_nullable_to_non_nullable
as bool,profileName: freezed == profileName ? _self.profileName : profileName // ignore: cast_nullable_to_non_nullable
as String?,profileEmail: freezed == profileEmail ? _self.profileEmail : profileEmail // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
