// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'compare_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CompareState {

 ComparePreset get preset;/// Periodi confrontati, il primo è quello di riferimento (di solito il più recente).
 List<Period> get periods; CompareMetric get metric; CompareChart get chart;
/// Create a copy of CompareState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompareStateCopyWith<CompareState> get copyWith => _$CompareStateCopyWithImpl<CompareState>(this as CompareState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CompareState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompareState&&(identical(other.preset, _this.preset) || other.preset == _this.preset)&&const DeepCollectionEquality().equals(other.periods, _this.periods)&&(identical(other.metric, _this.metric) || other.metric == _this.metric)&&(identical(other.chart, _this.chart) || other.chart == _this.chart));
}


@override
int get hashCode {
  final _this = this as CompareState;
  return Object.hash(runtimeType,_this.preset,const DeepCollectionEquality().hash(_this.periods),_this.metric,_this.chart);
}

@override
String toString() {
  final _this = this as CompareState;
  return 'CompareState(preset: ${_this.preset}, periods: ${_this.periods}, metric: ${_this.metric}, chart: ${_this.chart})';
}


}

/// @nodoc
abstract mixin class $CompareStateCopyWith<$Res>  {
  factory $CompareStateCopyWith(CompareState value, $Res Function(CompareState) _then) = _$CompareStateCopyWithImpl;
@useResult
$Res call({
 ComparePreset preset, List<Period> periods, CompareMetric metric, CompareChart chart
});




}
/// @nodoc
class _$CompareStateCopyWithImpl<$Res>
    implements $CompareStateCopyWith<$Res> {
  _$CompareStateCopyWithImpl(this._self, this._then);

  final CompareState _self;
  final $Res Function(CompareState) _then;

/// Create a copy of CompareState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? preset = null,Object? periods = null,Object? metric = null,Object? chart = null,}) {
  return _then(CompareState(
preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as ComparePreset,periods: null == periods ? _self.periods : periods // ignore: cast_nullable_to_non_nullable
as List<Period>,metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as CompareMetric,chart: null == chart ? _self.chart : chart // ignore: cast_nullable_to_non_nullable
as CompareChart,
  ));
}

}


/// Adds pattern-matching-related methods to [CompareState].
extension CompareStatePatterns on CompareState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompareState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompareState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompareState value)  $default,){
final _that = this;
switch (_that) {
case _CompareState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompareState value)?  $default,){
final _that = this;
switch (_that) {
case _CompareState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ComparePreset preset,  List<Period> periods,  CompareMetric metric,  CompareChart chart)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompareState() when $default != null:
return $default(_that.preset,_that.periods,_that.metric,_that.chart);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ComparePreset preset,  List<Period> periods,  CompareMetric metric,  CompareChart chart)  $default,) {final _that = this;
switch (_that) {
case _CompareState():
return $default(_that.preset,_that.periods,_that.metric,_that.chart);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ComparePreset preset,  List<Period> periods,  CompareMetric metric,  CompareChart chart)?  $default,) {final _that = this;
switch (_that) {
case _CompareState() when $default != null:
return $default(_that.preset,_that.periods,_that.metric,_that.chart);case _:
  return null;

}
}

}

/// @nodoc


class _CompareState extends CompareState {
  const _CompareState({required this.preset, required  List<Period> periods, this.metric = CompareMetric.expense, this.chart = CompareChart.bars}): _periods = periods,super._();
  

@override final  ComparePreset preset;
/// Periodi confrontati, il primo è quello di riferimento (di solito il più recente).
 final  List<Period> _periods;
/// Periodi confrontati, il primo è quello di riferimento (di solito il più recente).
@override List<Period> get periods {
  if (_periods is EqualUnmodifiableListView) return _periods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_periods);
}

@override@JsonKey() final  CompareMetric metric;
@override@JsonKey() final  CompareChart chart;

/// Create a copy of CompareState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompareStateCopyWith<_CompareState> get copyWith => __$CompareStateCopyWithImpl<_CompareState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompareState&&(identical(other.preset, preset) || other.preset == preset)&&const DeepCollectionEquality().equals(other.periods, _periods)&&(identical(other.metric, metric) || other.metric == metric)&&(identical(other.chart, chart) || other.chart == chart));
}


@override
int get hashCode {
    return Object.hash(runtimeType,preset,const DeepCollectionEquality().hash(_periods),metric,chart);
}

@override
String toString() {
    return 'CompareState(preset: $preset, periods: $periods, metric: $metric, chart: $chart)';
}


}

/// @nodoc
abstract mixin class _$CompareStateCopyWith<$Res> implements $CompareStateCopyWith<$Res> {
  factory _$CompareStateCopyWith(_CompareState value, $Res Function(_CompareState) _then) = __$CompareStateCopyWithImpl;
@override @useResult
$Res call({
 ComparePreset preset, List<Period> periods, CompareMetric metric, CompareChart chart
});




}
/// @nodoc
class __$CompareStateCopyWithImpl<$Res>
    implements _$CompareStateCopyWith<$Res> {
  __$CompareStateCopyWithImpl(this._self, this._then);

  final _CompareState _self;
  final $Res Function(_CompareState) _then;

/// Create a copy of CompareState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? preset = null,Object? periods = null,Object? metric = null,Object? chart = null,}) {
  return _then(_CompareState(
preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as ComparePreset,periods: null == periods ? _self._periods : periods // ignore: cast_nullable_to_non_nullable
as List<Period>,metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as CompareMetric,chart: null == chart ? _self.chart : chart // ignore: cast_nullable_to_non_nullable
as CompareChart,
  ));
}


}

// dart format on
