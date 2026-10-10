// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_form_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionFormSeed {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormSeed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'TransactionFormSeed()';
}


}

/// @nodoc
class $TransactionFormSeedCopyWith<$Res>  {
$TransactionFormSeedCopyWith(TransactionFormSeed _, $Res Function(TransactionFormSeed) __);
}


/// Adds pattern-matching-related methods to [TransactionFormSeed].
extension TransactionFormSeedPatterns on TransactionFormSeed {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CreateTransactionSeed value)?  create,TResult Function( EditTransactionSeed value)?  edit,TResult Function( ConfirmTransactionSeed value)?  confirm,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CreateTransactionSeed() when create != null:
return create(_that);case EditTransactionSeed() when edit != null:
return edit(_that);case ConfirmTransactionSeed() when confirm != null:
return confirm(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CreateTransactionSeed value)  create,required TResult Function( EditTransactionSeed value)  edit,required TResult Function( ConfirmTransactionSeed value)  confirm,}){
final _that = this;
switch (_that) {
case CreateTransactionSeed():
return create(_that);case EditTransactionSeed():
return edit(_that);case ConfirmTransactionSeed():
return confirm(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CreateTransactionSeed value)?  create,TResult? Function( EditTransactionSeed value)?  edit,TResult? Function( ConfirmTransactionSeed value)?  confirm,}){
final _that = this;
switch (_that) {
case CreateTransactionSeed() when create != null:
return create(_that);case EditTransactionSeed() when edit != null:
return edit(_that);case ConfirmTransactionSeed() when confirm != null:
return confirm(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TransactionType type)?  create,TResult Function( Transaction original,  List<Attachment> attachments)?  edit,TResult Function( Transaction pending)?  confirm,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CreateTransactionSeed() when create != null:
return create(_that.type);case EditTransactionSeed() when edit != null:
return edit(_that.original,_that.attachments);case ConfirmTransactionSeed() when confirm != null:
return confirm(_that.pending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TransactionType type)  create,required TResult Function( Transaction original,  List<Attachment> attachments)  edit,required TResult Function( Transaction pending)  confirm,}) {final _that = this;
switch (_that) {
case CreateTransactionSeed():
return create(_that.type);case EditTransactionSeed():
return edit(_that.original,_that.attachments);case ConfirmTransactionSeed():
return confirm(_that.pending);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TransactionType type)?  create,TResult? Function( Transaction original,  List<Attachment> attachments)?  edit,TResult? Function( Transaction pending)?  confirm,}) {final _that = this;
switch (_that) {
case CreateTransactionSeed() when create != null:
return create(_that.type);case EditTransactionSeed() when edit != null:
return edit(_that.original,_that.attachments);case ConfirmTransactionSeed() when confirm != null:
return confirm(_that.pending);case _:
  return null;

}
}

}

/// @nodoc


class CreateTransactionSeed implements TransactionFormSeed {
  const CreateTransactionSeed(this.type);
  

 final  TransactionType type;

/// Create a copy of TransactionFormSeed
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTransactionSeedCopyWith<CreateTransactionSeed> get copyWith => _$CreateTransactionSeedCopyWithImpl<CreateTransactionSeed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTransactionSeed&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type);
}

@override
String toString() {
    return 'TransactionFormSeed.create(type: $type)';
}


}

/// @nodoc
abstract mixin class $CreateTransactionSeedCopyWith<$Res> implements $TransactionFormSeedCopyWith<$Res> {
  factory $CreateTransactionSeedCopyWith(CreateTransactionSeed value, $Res Function(CreateTransactionSeed) _then) = _$CreateTransactionSeedCopyWithImpl;
@useResult
$Res call({
 TransactionType type
});




}
/// @nodoc
class _$CreateTransactionSeedCopyWithImpl<$Res>
    implements $CreateTransactionSeedCopyWith<$Res> {
  _$CreateTransactionSeedCopyWithImpl(this._self, this._then);

  final CreateTransactionSeed _self;
  final $Res Function(CreateTransactionSeed) _then;

/// Create a copy of TransactionFormSeed
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,}) {
  return _then(CreateTransactionSeed(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,
  ));
}


}

/// @nodoc


class EditTransactionSeed implements TransactionFormSeed {
  const EditTransactionSeed(this.original,  List<Attachment> attachments): _attachments = attachments;
  

 final  Transaction original;
 final  List<Attachment> _attachments;
 List<Attachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}


/// Create a copy of TransactionFormSeed
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditTransactionSeedCopyWith<EditTransactionSeed> get copyWith => _$EditTransactionSeedCopyWithImpl<EditTransactionSeed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditTransactionSeed&&(identical(other.original, original) || other.original == original)&&const DeepCollectionEquality().equals(other.attachments, _attachments));
}


@override
int get hashCode {
    return Object.hash(runtimeType,original,const DeepCollectionEquality().hash(_attachments));
}

@override
String toString() {
    return 'TransactionFormSeed.edit(original: $original, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class $EditTransactionSeedCopyWith<$Res> implements $TransactionFormSeedCopyWith<$Res> {
  factory $EditTransactionSeedCopyWith(EditTransactionSeed value, $Res Function(EditTransactionSeed) _then) = _$EditTransactionSeedCopyWithImpl;
@useResult
$Res call({
 Transaction original, List<Attachment> attachments
});


$TransactionCopyWith<$Res> get original;

}
/// @nodoc
class _$EditTransactionSeedCopyWithImpl<$Res>
    implements $EditTransactionSeedCopyWith<$Res> {
  _$EditTransactionSeedCopyWithImpl(this._self, this._then);

  final EditTransactionSeed _self;
  final $Res Function(EditTransactionSeed) _then;

/// Create a copy of TransactionFormSeed
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? original = null,Object? attachments = null,}) {
  return _then(EditTransactionSeed(
null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as Transaction,null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,
  ));
}

/// Create a copy of TransactionFormSeed
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionCopyWith<$Res> get original {
  
  return $TransactionCopyWith<$Res>(_self.original, (value) {
    return _then(_self.copyWith(original: value));
  });
}
}

/// @nodoc


class ConfirmTransactionSeed implements TransactionFormSeed {
  const ConfirmTransactionSeed(this.pending);
  

 final  Transaction pending;

/// Create a copy of TransactionFormSeed
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConfirmTransactionSeedCopyWith<ConfirmTransactionSeed> get copyWith => _$ConfirmTransactionSeedCopyWithImpl<ConfirmTransactionSeed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConfirmTransactionSeed&&(identical(other.pending, pending) || other.pending == pending));
}


@override
int get hashCode {
    return Object.hash(runtimeType,pending);
}

@override
String toString() {
    return 'TransactionFormSeed.confirm(pending: $pending)';
}


}

/// @nodoc
abstract mixin class $ConfirmTransactionSeedCopyWith<$Res> implements $TransactionFormSeedCopyWith<$Res> {
  factory $ConfirmTransactionSeedCopyWith(ConfirmTransactionSeed value, $Res Function(ConfirmTransactionSeed) _then) = _$ConfirmTransactionSeedCopyWithImpl;
@useResult
$Res call({
 Transaction pending
});


$TransactionCopyWith<$Res> get pending;

}
/// @nodoc
class _$ConfirmTransactionSeedCopyWithImpl<$Res>
    implements $ConfirmTransactionSeedCopyWith<$Res> {
  _$ConfirmTransactionSeedCopyWithImpl(this._self, this._then);

  final ConfirmTransactionSeed _self;
  final $Res Function(ConfirmTransactionSeed) _then;

/// Create a copy of TransactionFormSeed
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pending = null,}) {
  return _then(ConfirmTransactionSeed(
null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as Transaction,
  ));
}

/// Create a copy of TransactionFormSeed
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionCopyWith<$Res> get pending {
  
  return $TransactionCopyWith<$Res>(_self.pending, (value) {
    return _then(_self.copyWith(pending: value));
  });
}
}

/// @nodoc
mixin _$RepeatSettings {

 RecurrenceFrequency get frequency; int get interval; LocalDate? get endDate; int? get maxCount; RecurrenceMode get mode;
/// Create a copy of RepeatSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepeatSettingsCopyWith<RepeatSettings> get copyWith => _$RepeatSettingsCopyWithImpl<RepeatSettings>(this as RepeatSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RepeatSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RepeatSettings&&(identical(other.frequency, _this.frequency) || other.frequency == _this.frequency)&&(identical(other.interval, _this.interval) || other.interval == _this.interval)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.maxCount, _this.maxCount) || other.maxCount == _this.maxCount)&&(identical(other.mode, _this.mode) || other.mode == _this.mode));
}


@override
int get hashCode {
  final _this = this as RepeatSettings;
  return Object.hash(runtimeType,_this.frequency,_this.interval,_this.endDate,_this.maxCount,_this.mode);
}

@override
String toString() {
  final _this = this as RepeatSettings;
  return 'RepeatSettings(frequency: ${_this.frequency}, interval: ${_this.interval}, endDate: ${_this.endDate}, maxCount: ${_this.maxCount}, mode: ${_this.mode})';
}


}

/// @nodoc
abstract mixin class $RepeatSettingsCopyWith<$Res>  {
  factory $RepeatSettingsCopyWith(RepeatSettings value, $Res Function(RepeatSettings) _then) = _$RepeatSettingsCopyWithImpl;
@useResult
$Res call({
 RecurrenceFrequency frequency, int interval, LocalDate? endDate, int? maxCount, RecurrenceMode mode
});




}
/// @nodoc
class _$RepeatSettingsCopyWithImpl<$Res>
    implements $RepeatSettingsCopyWith<$Res> {
  _$RepeatSettingsCopyWithImpl(this._self, this._then);

  final RepeatSettings _self;
  final $Res Function(RepeatSettings) _then;

/// Create a copy of RepeatSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frequency = null,Object? interval = null,Object? endDate = freezed,Object? maxCount = freezed,Object? mode = null,}) {
  return _then(RepeatSettings(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,maxCount: freezed == maxCount ? _self.maxCount : maxCount // ignore: cast_nullable_to_non_nullable
as int?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RecurrenceMode,
  ));
}

}


/// Adds pattern-matching-related methods to [RepeatSettings].
extension RepeatSettingsPatterns on RepeatSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RepeatSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RepeatSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RepeatSettings value)  $default,){
final _that = this;
switch (_that) {
case _RepeatSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RepeatSettings value)?  $default,){
final _that = this;
switch (_that) {
case _RepeatSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RecurrenceFrequency frequency,  int interval,  LocalDate? endDate,  int? maxCount,  RecurrenceMode mode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RepeatSettings() when $default != null:
return $default(_that.frequency,_that.interval,_that.endDate,_that.maxCount,_that.mode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RecurrenceFrequency frequency,  int interval,  LocalDate? endDate,  int? maxCount,  RecurrenceMode mode)  $default,) {final _that = this;
switch (_that) {
case _RepeatSettings():
return $default(_that.frequency,_that.interval,_that.endDate,_that.maxCount,_that.mode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RecurrenceFrequency frequency,  int interval,  LocalDate? endDate,  int? maxCount,  RecurrenceMode mode)?  $default,) {final _that = this;
switch (_that) {
case _RepeatSettings() when $default != null:
return $default(_that.frequency,_that.interval,_that.endDate,_that.maxCount,_that.mode);case _:
  return null;

}
}

}

/// @nodoc


class _RepeatSettings implements RepeatSettings {
  const _RepeatSettings({required this.frequency, this.interval = 1, this.endDate, this.maxCount, this.mode = RecurrenceMode.auto});
  

@override final  RecurrenceFrequency frequency;
@override@JsonKey() final  int interval;
@override final  LocalDate? endDate;
@override final  int? maxCount;
@override@JsonKey() final  RecurrenceMode mode;

/// Create a copy of RepeatSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepeatSettingsCopyWith<_RepeatSettings> get copyWith => __$RepeatSettingsCopyWithImpl<_RepeatSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RepeatSettings&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.maxCount, maxCount) || other.maxCount == maxCount)&&(identical(other.mode, mode) || other.mode == mode));
}


@override
int get hashCode {
    return Object.hash(runtimeType,frequency,interval,endDate,maxCount,mode);
}

@override
String toString() {
    return 'RepeatSettings(frequency: $frequency, interval: $interval, endDate: $endDate, maxCount: $maxCount, mode: $mode)';
}


}

/// @nodoc
abstract mixin class _$RepeatSettingsCopyWith<$Res> implements $RepeatSettingsCopyWith<$Res> {
  factory _$RepeatSettingsCopyWith(_RepeatSettings value, $Res Function(_RepeatSettings) _then) = __$RepeatSettingsCopyWithImpl;
@override @useResult
$Res call({
 RecurrenceFrequency frequency, int interval, LocalDate? endDate, int? maxCount, RecurrenceMode mode
});




}
/// @nodoc
class __$RepeatSettingsCopyWithImpl<$Res>
    implements _$RepeatSettingsCopyWith<$Res> {
  __$RepeatSettingsCopyWithImpl(this._self, this._then);

  final _RepeatSettings _self;
  final $Res Function(_RepeatSettings) _then;

/// Create a copy of RepeatSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frequency = null,Object? interval = null,Object? endDate = freezed,Object? maxCount = freezed,Object? mode = null,}) {
  return _then(_RepeatSettings(
frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,maxCount: freezed == maxCount ? _self.maxCount : maxCount // ignore: cast_nullable_to_non_nullable
as int?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RecurrenceMode,
  ));
}


}

/// @nodoc
mixin _$TransactionFormState {

 TransactionType get type; LocalDate get date; int get amountCents; String? get categoryId; Set<String> get labelIds;/// Portafogli scelti a mano, uno per tipo (null = usa il predefinito).
 String? get expenseWalletId; String? get incomeWalletId;/// Portafogli scelti a mano per il trasferimento.
 String? get fromWalletId; String? get toWalletId; String get note;/// Allegati già salvati (solo in modifica), esclusi quelli tolti.
 List<Attachment> get savedAttachments;/// Allegati salvati che l'utente ha tolto: al salvataggio vengono cancellati logicamente.
 List<Attachment> get removedAttachments;/// Allegati nuovi, copiati nella cartella dell'app solo al salvataggio.
 List<PickedAttachment> get newAttachments;/// Movimento di partenza in modifica; null per un movimento nuovo.
 Transaction? get original;/// Ripetizione del movimento nuovo (null = non si ripete).
 RepeatSettings? get repeat;/// True quando si conferma un `pending`: il salvataggio lo porta a `confirmed`.
 bool get confirming;/// True finché l'importo è quello proposto (conferma): il primo tasto lo sostituisce.
 bool get amountIsSuggestion;/// Diventa true al primo tentativo di salvataggio: da lì si mostrano gli errori.
 bool get showErrors; bool get saving;
/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFormStateCopyWith<TransactionFormState> get copyWith => _$TransactionFormStateCopyWithImpl<TransactionFormState>(this as TransactionFormState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TransactionFormState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFormState&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.amountCents, _this.amountCents) || other.amountCents == _this.amountCents)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&const DeepCollectionEquality().equals(other.labelIds, _this.labelIds)&&(identical(other.expenseWalletId, _this.expenseWalletId) || other.expenseWalletId == _this.expenseWalletId)&&(identical(other.incomeWalletId, _this.incomeWalletId) || other.incomeWalletId == _this.incomeWalletId)&&(identical(other.fromWalletId, _this.fromWalletId) || other.fromWalletId == _this.fromWalletId)&&(identical(other.toWalletId, _this.toWalletId) || other.toWalletId == _this.toWalletId)&&(identical(other.note, _this.note) || other.note == _this.note)&&const DeepCollectionEquality().equals(other.savedAttachments, _this.savedAttachments)&&const DeepCollectionEquality().equals(other.removedAttachments, _this.removedAttachments)&&const DeepCollectionEquality().equals(other.newAttachments, _this.newAttachments)&&(identical(other.original, _this.original) || other.original == _this.original)&&(identical(other.repeat, _this.repeat) || other.repeat == _this.repeat)&&(identical(other.confirming, _this.confirming) || other.confirming == _this.confirming)&&(identical(other.amountIsSuggestion, _this.amountIsSuggestion) || other.amountIsSuggestion == _this.amountIsSuggestion)&&(identical(other.showErrors, _this.showErrors) || other.showErrors == _this.showErrors)&&(identical(other.saving, _this.saving) || other.saving == _this.saving));
}


@override
int get hashCode {
  final _this = this as TransactionFormState;
  return Object.hashAll([runtimeType,_this.type,_this.date,_this.amountCents,_this.categoryId,const DeepCollectionEquality().hash(_this.labelIds),_this.expenseWalletId,_this.incomeWalletId,_this.fromWalletId,_this.toWalletId,_this.note,const DeepCollectionEquality().hash(_this.savedAttachments),const DeepCollectionEquality().hash(_this.removedAttachments),const DeepCollectionEquality().hash(_this.newAttachments),_this.original,_this.repeat,_this.confirming,_this.amountIsSuggestion,_this.showErrors,_this.saving]);
}

@override
String toString() {
  final _this = this as TransactionFormState;
  return 'TransactionFormState(type: ${_this.type}, date: ${_this.date}, amountCents: ${_this.amountCents}, categoryId: ${_this.categoryId}, labelIds: ${_this.labelIds}, expenseWalletId: ${_this.expenseWalletId}, incomeWalletId: ${_this.incomeWalletId}, fromWalletId: ${_this.fromWalletId}, toWalletId: ${_this.toWalletId}, note: ${_this.note}, savedAttachments: ${_this.savedAttachments}, removedAttachments: ${_this.removedAttachments}, newAttachments: ${_this.newAttachments}, original: ${_this.original}, repeat: ${_this.repeat}, confirming: ${_this.confirming}, amountIsSuggestion: ${_this.amountIsSuggestion}, showErrors: ${_this.showErrors}, saving: ${_this.saving})';
}


}

/// @nodoc
abstract mixin class $TransactionFormStateCopyWith<$Res>  {
  factory $TransactionFormStateCopyWith(TransactionFormState value, $Res Function(TransactionFormState) _then) = _$TransactionFormStateCopyWithImpl;
@useResult
$Res call({
 TransactionType type, LocalDate date, int amountCents, String? categoryId, Set<String> labelIds, String? expenseWalletId, String? incomeWalletId, String? fromWalletId, String? toWalletId, String note, List<Attachment> savedAttachments, List<Attachment> removedAttachments, List<PickedAttachment> newAttachments, Transaction? original, RepeatSettings? repeat, bool confirming, bool amountIsSuggestion, bool showErrors, bool saving
});


$TransactionCopyWith<$Res>? get original;$RepeatSettingsCopyWith<$Res>? get repeat;

}
/// @nodoc
class _$TransactionFormStateCopyWithImpl<$Res>
    implements $TransactionFormStateCopyWith<$Res> {
  _$TransactionFormStateCopyWithImpl(this._self, this._then);

  final TransactionFormState _self;
  final $Res Function(TransactionFormState) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? date = null,Object? amountCents = null,Object? categoryId = freezed,Object? labelIds = null,Object? expenseWalletId = freezed,Object? incomeWalletId = freezed,Object? fromWalletId = freezed,Object? toWalletId = freezed,Object? note = null,Object? savedAttachments = null,Object? removedAttachments = null,Object? newAttachments = null,Object? original = freezed,Object? repeat = freezed,Object? confirming = null,Object? amountIsSuggestion = null,Object? showErrors = null,Object? saving = null,}) {
  return _then(TransactionFormState(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,labelIds: null == labelIds ? _self.labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as Set<String>,expenseWalletId: freezed == expenseWalletId ? _self.expenseWalletId : expenseWalletId // ignore: cast_nullable_to_non_nullable
as String?,incomeWalletId: freezed == incomeWalletId ? _self.incomeWalletId : incomeWalletId // ignore: cast_nullable_to_non_nullable
as String?,fromWalletId: freezed == fromWalletId ? _self.fromWalletId : fromWalletId // ignore: cast_nullable_to_non_nullable
as String?,toWalletId: freezed == toWalletId ? _self.toWalletId : toWalletId // ignore: cast_nullable_to_non_nullable
as String?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,savedAttachments: null == savedAttachments ? _self.savedAttachments : savedAttachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,removedAttachments: null == removedAttachments ? _self.removedAttachments : removedAttachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,newAttachments: null == newAttachments ? _self.newAttachments : newAttachments // ignore: cast_nullable_to_non_nullable
as List<PickedAttachment>,original: freezed == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as Transaction?,repeat: freezed == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as RepeatSettings?,confirming: null == confirming ? _self.confirming : confirming // ignore: cast_nullable_to_non_nullable
as bool,amountIsSuggestion: null == amountIsSuggestion ? _self.amountIsSuggestion : amountIsSuggestion // ignore: cast_nullable_to_non_nullable
as bool,showErrors: null == showErrors ? _self.showErrors : showErrors // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionCopyWith<$Res>? get original {
    if (_self.original == null) {
    return null;
  }

  return $TransactionCopyWith<$Res>(_self.original!, (value) {
    return _then(_self.copyWith(original: value));
  });
}/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepeatSettingsCopyWith<$Res>? get repeat {
    if (_self.repeat == null) {
    return null;
  }

  return $RepeatSettingsCopyWith<$Res>(_self.repeat!, (value) {
    return _then(_self.copyWith(repeat: value));
  });
}
}


/// Adds pattern-matching-related methods to [TransactionFormState].
extension TransactionFormStatePatterns on TransactionFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionFormState value)  $default,){
final _that = this;
switch (_that) {
case _TransactionFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionFormState value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TransactionType type,  LocalDate date,  int amountCents,  String? categoryId,  Set<String> labelIds,  String? expenseWalletId,  String? incomeWalletId,  String? fromWalletId,  String? toWalletId,  String note,  List<Attachment> savedAttachments,  List<Attachment> removedAttachments,  List<PickedAttachment> newAttachments,  Transaction? original,  RepeatSettings? repeat,  bool confirming,  bool amountIsSuggestion,  bool showErrors,  bool saving)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
return $default(_that.type,_that.date,_that.amountCents,_that.categoryId,_that.labelIds,_that.expenseWalletId,_that.incomeWalletId,_that.fromWalletId,_that.toWalletId,_that.note,_that.savedAttachments,_that.removedAttachments,_that.newAttachments,_that.original,_that.repeat,_that.confirming,_that.amountIsSuggestion,_that.showErrors,_that.saving);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TransactionType type,  LocalDate date,  int amountCents,  String? categoryId,  Set<String> labelIds,  String? expenseWalletId,  String? incomeWalletId,  String? fromWalletId,  String? toWalletId,  String note,  List<Attachment> savedAttachments,  List<Attachment> removedAttachments,  List<PickedAttachment> newAttachments,  Transaction? original,  RepeatSettings? repeat,  bool confirming,  bool amountIsSuggestion,  bool showErrors,  bool saving)  $default,) {final _that = this;
switch (_that) {
case _TransactionFormState():
return $default(_that.type,_that.date,_that.amountCents,_that.categoryId,_that.labelIds,_that.expenseWalletId,_that.incomeWalletId,_that.fromWalletId,_that.toWalletId,_that.note,_that.savedAttachments,_that.removedAttachments,_that.newAttachments,_that.original,_that.repeat,_that.confirming,_that.amountIsSuggestion,_that.showErrors,_that.saving);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TransactionType type,  LocalDate date,  int amountCents,  String? categoryId,  Set<String> labelIds,  String? expenseWalletId,  String? incomeWalletId,  String? fromWalletId,  String? toWalletId,  String note,  List<Attachment> savedAttachments,  List<Attachment> removedAttachments,  List<PickedAttachment> newAttachments,  Transaction? original,  RepeatSettings? repeat,  bool confirming,  bool amountIsSuggestion,  bool showErrors,  bool saving)?  $default,) {final _that = this;
switch (_that) {
case _TransactionFormState() when $default != null:
return $default(_that.type,_that.date,_that.amountCents,_that.categoryId,_that.labelIds,_that.expenseWalletId,_that.incomeWalletId,_that.fromWalletId,_that.toWalletId,_that.note,_that.savedAttachments,_that.removedAttachments,_that.newAttachments,_that.original,_that.repeat,_that.confirming,_that.amountIsSuggestion,_that.showErrors,_that.saving);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionFormState extends TransactionFormState {
  const _TransactionFormState({required this.type, required this.date, this.amountCents = 0, this.categoryId,  Set<String> labelIds = const <String>{}, this.expenseWalletId, this.incomeWalletId, this.fromWalletId, this.toWalletId, this.note = '',  List<Attachment> savedAttachments = const <Attachment>[],  List<Attachment> removedAttachments = const <Attachment>[],  List<PickedAttachment> newAttachments = const <PickedAttachment>[], this.original, this.repeat, this.confirming = false, this.amountIsSuggestion = false, this.showErrors = false, this.saving = false}): _labelIds = labelIds,_savedAttachments = savedAttachments,_removedAttachments = removedAttachments,_newAttachments = newAttachments,super._();
  

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
/// Portafogli scelti a mano per il trasferimento.
@override final  String? fromWalletId;
@override final  String? toWalletId;
@override@JsonKey() final  String note;
/// Allegati già salvati (solo in modifica), esclusi quelli tolti.
 final  List<Attachment> _savedAttachments;
/// Allegati già salvati (solo in modifica), esclusi quelli tolti.
@override@JsonKey() List<Attachment> get savedAttachments {
  if (_savedAttachments is EqualUnmodifiableListView) return _savedAttachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_savedAttachments);
}

/// Allegati salvati che l'utente ha tolto: al salvataggio vengono cancellati logicamente.
 final  List<Attachment> _removedAttachments;
/// Allegati salvati che l'utente ha tolto: al salvataggio vengono cancellati logicamente.
@override@JsonKey() List<Attachment> get removedAttachments {
  if (_removedAttachments is EqualUnmodifiableListView) return _removedAttachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_removedAttachments);
}

/// Allegati nuovi, copiati nella cartella dell'app solo al salvataggio.
 final  List<PickedAttachment> _newAttachments;
/// Allegati nuovi, copiati nella cartella dell'app solo al salvataggio.
@override@JsonKey() List<PickedAttachment> get newAttachments {
  if (_newAttachments is EqualUnmodifiableListView) return _newAttachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_newAttachments);
}

/// Movimento di partenza in modifica; null per un movimento nuovo.
@override final  Transaction? original;
/// Ripetizione del movimento nuovo (null = non si ripete).
@override final  RepeatSettings? repeat;
/// True quando si conferma un `pending`: il salvataggio lo porta a `confirmed`.
@override@JsonKey() final  bool confirming;
/// True finché l'importo è quello proposto (conferma): il primo tasto lo sostituisce.
@override@JsonKey() final  bool amountIsSuggestion;
/// Diventa true al primo tentativo di salvataggio: da lì si mostrano gli errori.
@override@JsonKey() final  bool showErrors;
@override@JsonKey() final  bool saving;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionFormStateCopyWith<_TransactionFormState> get copyWith => __$TransactionFormStateCopyWithImpl<_TransactionFormState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionFormState&&(identical(other.type, type) || other.type == type)&&(identical(other.date, date) || other.date == date)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&const DeepCollectionEquality().equals(other.labelIds, _labelIds)&&(identical(other.expenseWalletId, expenseWalletId) || other.expenseWalletId == expenseWalletId)&&(identical(other.incomeWalletId, incomeWalletId) || other.incomeWalletId == incomeWalletId)&&(identical(other.fromWalletId, fromWalletId) || other.fromWalletId == fromWalletId)&&(identical(other.toWalletId, toWalletId) || other.toWalletId == toWalletId)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.savedAttachments, _savedAttachments)&&const DeepCollectionEquality().equals(other.removedAttachments, _removedAttachments)&&const DeepCollectionEquality().equals(other.newAttachments, _newAttachments)&&(identical(other.original, original) || other.original == original)&&(identical(other.repeat, repeat) || other.repeat == repeat)&&(identical(other.confirming, confirming) || other.confirming == confirming)&&(identical(other.amountIsSuggestion, amountIsSuggestion) || other.amountIsSuggestion == amountIsSuggestion)&&(identical(other.showErrors, showErrors) || other.showErrors == showErrors)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,type,date,amountCents,categoryId,const DeepCollectionEquality().hash(_labelIds),expenseWalletId,incomeWalletId,fromWalletId,toWalletId,note,const DeepCollectionEquality().hash(_savedAttachments),const DeepCollectionEquality().hash(_removedAttachments),const DeepCollectionEquality().hash(_newAttachments),original,repeat,confirming,amountIsSuggestion,showErrors,saving]);
}

@override
String toString() {
    return 'TransactionFormState(type: $type, date: $date, amountCents: $amountCents, categoryId: $categoryId, labelIds: $labelIds, expenseWalletId: $expenseWalletId, incomeWalletId: $incomeWalletId, fromWalletId: $fromWalletId, toWalletId: $toWalletId, note: $note, savedAttachments: $savedAttachments, removedAttachments: $removedAttachments, newAttachments: $newAttachments, original: $original, repeat: $repeat, confirming: $confirming, amountIsSuggestion: $amountIsSuggestion, showErrors: $showErrors, saving: $saving)';
}


}

/// @nodoc
abstract mixin class _$TransactionFormStateCopyWith<$Res> implements $TransactionFormStateCopyWith<$Res> {
  factory _$TransactionFormStateCopyWith(_TransactionFormState value, $Res Function(_TransactionFormState) _then) = __$TransactionFormStateCopyWithImpl;
@override @useResult
$Res call({
 TransactionType type, LocalDate date, int amountCents, String? categoryId, Set<String> labelIds, String? expenseWalletId, String? incomeWalletId, String? fromWalletId, String? toWalletId, String note, List<Attachment> savedAttachments, List<Attachment> removedAttachments, List<PickedAttachment> newAttachments, Transaction? original, RepeatSettings? repeat, bool confirming, bool amountIsSuggestion, bool showErrors, bool saving
});


@override $TransactionCopyWith<$Res>? get original;@override $RepeatSettingsCopyWith<$Res>? get repeat;

}
/// @nodoc
class __$TransactionFormStateCopyWithImpl<$Res>
    implements _$TransactionFormStateCopyWith<$Res> {
  __$TransactionFormStateCopyWithImpl(this._self, this._then);

  final _TransactionFormState _self;
  final $Res Function(_TransactionFormState) _then;

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? date = null,Object? amountCents = null,Object? categoryId = freezed,Object? labelIds = null,Object? expenseWalletId = freezed,Object? incomeWalletId = freezed,Object? fromWalletId = freezed,Object? toWalletId = freezed,Object? note = null,Object? savedAttachments = null,Object? removedAttachments = null,Object? newAttachments = null,Object? original = freezed,Object? repeat = freezed,Object? confirming = null,Object? amountIsSuggestion = null,Object? showErrors = null,Object? saving = null,}) {
  return _then(_TransactionFormState(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,labelIds: null == labelIds ? _self._labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as Set<String>,expenseWalletId: freezed == expenseWalletId ? _self.expenseWalletId : expenseWalletId // ignore: cast_nullable_to_non_nullable
as String?,incomeWalletId: freezed == incomeWalletId ? _self.incomeWalletId : incomeWalletId // ignore: cast_nullable_to_non_nullable
as String?,fromWalletId: freezed == fromWalletId ? _self.fromWalletId : fromWalletId // ignore: cast_nullable_to_non_nullable
as String?,toWalletId: freezed == toWalletId ? _self.toWalletId : toWalletId // ignore: cast_nullable_to_non_nullable
as String?,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,savedAttachments: null == savedAttachments ? _self._savedAttachments : savedAttachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,removedAttachments: null == removedAttachments ? _self._removedAttachments : removedAttachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,newAttachments: null == newAttachments ? _self._newAttachments : newAttachments // ignore: cast_nullable_to_non_nullable
as List<PickedAttachment>,original: freezed == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as Transaction?,repeat: freezed == repeat ? _self.repeat : repeat // ignore: cast_nullable_to_non_nullable
as RepeatSettings?,confirming: null == confirming ? _self.confirming : confirming // ignore: cast_nullable_to_non_nullable
as bool,amountIsSuggestion: null == amountIsSuggestion ? _self.amountIsSuggestion : amountIsSuggestion // ignore: cast_nullable_to_non_nullable
as bool,showErrors: null == showErrors ? _self.showErrors : showErrors // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionCopyWith<$Res>? get original {
    if (_self.original == null) {
    return null;
  }

  return $TransactionCopyWith<$Res>(_self.original!, (value) {
    return _then(_self.copyWith(original: value));
  });
}/// Create a copy of TransactionFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepeatSettingsCopyWith<$Res>? get repeat {
    if (_self.repeat == null) {
    return null;
  }

  return $RepeatSettingsCopyWith<$Res>(_self.repeat!, (value) {
    return _then(_self.copyWith(repeat: value));
  });
}
}

// dart format on
