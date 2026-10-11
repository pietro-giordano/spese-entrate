// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'import_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImportFlowState {

 ImportStep get step; String? get fileName; String? get content; ImportPlan? get plan; ImportChoices get choices;/// Portafoglio per le righe con la colonna vuota (null = quelle righe sono errori).
 String? get fallbackWalletId; int get progressDone; int get progressTotal; ImportSummary? get summary;/// Messaggio per l'utente quando qualcosa va storto (file illeggibile, import fallito).
 String? get errorMessage; bool get busy;
/// Create a copy of ImportFlowState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportFlowStateCopyWith<ImportFlowState> get copyWith => _$ImportFlowStateCopyWithImpl<ImportFlowState>(this as ImportFlowState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ImportFlowState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportFlowState&&(identical(other.step, _this.step) || other.step == _this.step)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&(identical(other.choices, _this.choices) || other.choices == _this.choices)&&(identical(other.fallbackWalletId, _this.fallbackWalletId) || other.fallbackWalletId == _this.fallbackWalletId)&&(identical(other.progressDone, _this.progressDone) || other.progressDone == _this.progressDone)&&(identical(other.progressTotal, _this.progressTotal) || other.progressTotal == _this.progressTotal)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage)&&(identical(other.busy, _this.busy) || other.busy == _this.busy));
}


@override
int get hashCode {
  final _this = this as ImportFlowState;
  return Object.hash(runtimeType,_this.step,_this.fileName,_this.content,_this.plan,_this.choices,_this.fallbackWalletId,_this.progressDone,_this.progressTotal,_this.summary,_this.errorMessage,_this.busy);
}

@override
String toString() {
  final _this = this as ImportFlowState;
  return 'ImportFlowState(step: ${_this.step}, fileName: ${_this.fileName}, content: ${_this.content}, plan: ${_this.plan}, choices: ${_this.choices}, fallbackWalletId: ${_this.fallbackWalletId}, progressDone: ${_this.progressDone}, progressTotal: ${_this.progressTotal}, summary: ${_this.summary}, errorMessage: ${_this.errorMessage}, busy: ${_this.busy})';
}


}

/// @nodoc
abstract mixin class $ImportFlowStateCopyWith<$Res>  {
  factory $ImportFlowStateCopyWith(ImportFlowState value, $Res Function(ImportFlowState) _then) = _$ImportFlowStateCopyWithImpl;
@useResult
$Res call({
 ImportStep step, String? fileName, String? content, ImportPlan? plan, ImportChoices choices, String? fallbackWalletId, int progressDone, int progressTotal, ImportSummary? summary, String? errorMessage, bool busy
});




}
/// @nodoc
class _$ImportFlowStateCopyWithImpl<$Res>
    implements $ImportFlowStateCopyWith<$Res> {
  _$ImportFlowStateCopyWithImpl(this._self, this._then);

  final ImportFlowState _self;
  final $Res Function(ImportFlowState) _then;

/// Create a copy of ImportFlowState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? fileName = freezed,Object? content = freezed,Object? plan = freezed,Object? choices = null,Object? fallbackWalletId = freezed,Object? progressDone = null,Object? progressTotal = null,Object? summary = freezed,Object? errorMessage = freezed,Object? busy = null,}) {
  return _then(ImportFlowState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as ImportStep,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as ImportPlan?,choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as ImportChoices,fallbackWalletId: freezed == fallbackWalletId ? _self.fallbackWalletId : fallbackWalletId // ignore: cast_nullable_to_non_nullable
as String?,progressDone: null == progressDone ? _self.progressDone : progressDone // ignore: cast_nullable_to_non_nullable
as int,progressTotal: null == progressTotal ? _self.progressTotal : progressTotal // ignore: cast_nullable_to_non_nullable
as int,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as ImportSummary?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ImportFlowState].
extension ImportFlowStatePatterns on ImportFlowState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImportFlowState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImportFlowState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImportFlowState value)  $default,){
final _that = this;
switch (_that) {
case _ImportFlowState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImportFlowState value)?  $default,){
final _that = this;
switch (_that) {
case _ImportFlowState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ImportStep step,  String? fileName,  String? content,  ImportPlan? plan,  ImportChoices choices,  String? fallbackWalletId,  int progressDone,  int progressTotal,  ImportSummary? summary,  String? errorMessage,  bool busy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImportFlowState() when $default != null:
return $default(_that.step,_that.fileName,_that.content,_that.plan,_that.choices,_that.fallbackWalletId,_that.progressDone,_that.progressTotal,_that.summary,_that.errorMessage,_that.busy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ImportStep step,  String? fileName,  String? content,  ImportPlan? plan,  ImportChoices choices,  String? fallbackWalletId,  int progressDone,  int progressTotal,  ImportSummary? summary,  String? errorMessage,  bool busy)  $default,) {final _that = this;
switch (_that) {
case _ImportFlowState():
return $default(_that.step,_that.fileName,_that.content,_that.plan,_that.choices,_that.fallbackWalletId,_that.progressDone,_that.progressTotal,_that.summary,_that.errorMessage,_that.busy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ImportStep step,  String? fileName,  String? content,  ImportPlan? plan,  ImportChoices choices,  String? fallbackWalletId,  int progressDone,  int progressTotal,  ImportSummary? summary,  String? errorMessage,  bool busy)?  $default,) {final _that = this;
switch (_that) {
case _ImportFlowState() when $default != null:
return $default(_that.step,_that.fileName,_that.content,_that.plan,_that.choices,_that.fallbackWalletId,_that.progressDone,_that.progressTotal,_that.summary,_that.errorMessage,_that.busy);case _:
  return null;

}
}

}

/// @nodoc


class _ImportFlowState extends ImportFlowState {
  const _ImportFlowState({this.step = ImportStep.intro, this.fileName, this.content, this.plan, this.choices = const ImportChoices(), this.fallbackWalletId, this.progressDone = 0, this.progressTotal = 0, this.summary, this.errorMessage, this.busy = false}): super._();
  

@override@JsonKey() final  ImportStep step;
@override final  String? fileName;
@override final  String? content;
@override final  ImportPlan? plan;
@override@JsonKey() final  ImportChoices choices;
/// Portafoglio per le righe con la colonna vuota (null = quelle righe sono errori).
@override final  String? fallbackWalletId;
@override@JsonKey() final  int progressDone;
@override@JsonKey() final  int progressTotal;
@override final  ImportSummary? summary;
/// Messaggio per l'utente quando qualcosa va storto (file illeggibile, import fallito).
@override final  String? errorMessage;
@override@JsonKey() final  bool busy;

/// Create a copy of ImportFlowState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImportFlowStateCopyWith<_ImportFlowState> get copyWith => __$ImportFlowStateCopyWithImpl<_ImportFlowState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImportFlowState&&(identical(other.step, step) || other.step == step)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.content, content) || other.content == content)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.choices, choices) || other.choices == choices)&&(identical(other.fallbackWalletId, fallbackWalletId) || other.fallbackWalletId == fallbackWalletId)&&(identical(other.progressDone, progressDone) || other.progressDone == progressDone)&&(identical(other.progressTotal, progressTotal) || other.progressTotal == progressTotal)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.busy, busy) || other.busy == busy));
}


@override
int get hashCode {
    return Object.hash(runtimeType,step,fileName,content,plan,choices,fallbackWalletId,progressDone,progressTotal,summary,errorMessage,busy);
}

@override
String toString() {
    return 'ImportFlowState(step: $step, fileName: $fileName, content: $content, plan: $plan, choices: $choices, fallbackWalletId: $fallbackWalletId, progressDone: $progressDone, progressTotal: $progressTotal, summary: $summary, errorMessage: $errorMessage, busy: $busy)';
}


}

/// @nodoc
abstract mixin class _$ImportFlowStateCopyWith<$Res> implements $ImportFlowStateCopyWith<$Res> {
  factory _$ImportFlowStateCopyWith(_ImportFlowState value, $Res Function(_ImportFlowState) _then) = __$ImportFlowStateCopyWithImpl;
@override @useResult
$Res call({
 ImportStep step, String? fileName, String? content, ImportPlan? plan, ImportChoices choices, String? fallbackWalletId, int progressDone, int progressTotal, ImportSummary? summary, String? errorMessage, bool busy
});




}
/// @nodoc
class __$ImportFlowStateCopyWithImpl<$Res>
    implements _$ImportFlowStateCopyWith<$Res> {
  __$ImportFlowStateCopyWithImpl(this._self, this._then);

  final _ImportFlowState _self;
  final $Res Function(_ImportFlowState) _then;

/// Create a copy of ImportFlowState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? fileName = freezed,Object? content = freezed,Object? plan = freezed,Object? choices = null,Object? fallbackWalletId = freezed,Object? progressDone = null,Object? progressTotal = null,Object? summary = freezed,Object? errorMessage = freezed,Object? busy = null,}) {
  return _then(_ImportFlowState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as ImportStep,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as ImportPlan?,choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as ImportChoices,fallbackWalletId: freezed == fallbackWalletId ? _self.fallbackWalletId : fallbackWalletId // ignore: cast_nullable_to_non_nullable
as String?,progressDone: null == progressDone ? _self.progressDone : progressDone // ignore: cast_nullable_to_non_nullable
as int,progressTotal: null == progressTotal ? _self.progressTotal : progressTotal // ignore: cast_nullable_to_non_nullable
as int,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as ImportSummary?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,busy: null == busy ? _self.busy : busy // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
