// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Transaction {

 String get id; TransactionType get type; TransactionStatus get status;/// Sempre > 0, tranne le rettifiche che hanno segno.
 int get amountCents; String get currency; LocalDate get date;/// Portafoglio del movimento; per i trasferimenti è quello di origine.
 String get walletId;/// Solo per i trasferimenti.
 String? get toWalletId;/// Obbligatoria per spese ed entrate.
 String? get categoryId; String? get note; List<String> get labelIds; String? get recurrenceId; LocalDate? get occurrenceDate;/// Import da CSV che ha creato il movimento; null se inserito nell'app. Annullare l'import
/// cancella i movimenti con questo id (non quelli che l'import ha solo aggiornato).
 String? get importBatchId;
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCopyWith<Transaction> get copyWith => _$TransactionCopyWithImpl<Transaction>(this as Transaction, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Transaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transaction&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.amountCents, _this.amountCents) || other.amountCents == _this.amountCents)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.walletId, _this.walletId) || other.walletId == _this.walletId)&&(identical(other.toWalletId, _this.toWalletId) || other.toWalletId == _this.toWalletId)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.note, _this.note) || other.note == _this.note)&&const DeepCollectionEquality().equals(other.labelIds, _this.labelIds)&&(identical(other.recurrenceId, _this.recurrenceId) || other.recurrenceId == _this.recurrenceId)&&(identical(other.occurrenceDate, _this.occurrenceDate) || other.occurrenceDate == _this.occurrenceDate)&&(identical(other.importBatchId, _this.importBatchId) || other.importBatchId == _this.importBatchId));
}


@override
int get hashCode {
  final _this = this as Transaction;
  return Object.hash(runtimeType,_this.id,_this.type,_this.status,_this.amountCents,_this.currency,_this.date,_this.walletId,_this.toWalletId,_this.categoryId,_this.note,const DeepCollectionEquality().hash(_this.labelIds),_this.recurrenceId,_this.occurrenceDate,_this.importBatchId);
}

@override
String toString() {
  final _this = this as Transaction;
  return 'Transaction(id: ${_this.id}, type: ${_this.type}, status: ${_this.status}, amountCents: ${_this.amountCents}, currency: ${_this.currency}, date: ${_this.date}, walletId: ${_this.walletId}, toWalletId: ${_this.toWalletId}, categoryId: ${_this.categoryId}, note: ${_this.note}, labelIds: ${_this.labelIds}, recurrenceId: ${_this.recurrenceId}, occurrenceDate: ${_this.occurrenceDate}, importBatchId: ${_this.importBatchId})';
}


}

/// @nodoc
abstract mixin class $TransactionCopyWith<$Res>  {
  factory $TransactionCopyWith(Transaction value, $Res Function(Transaction) _then) = _$TransactionCopyWithImpl;
@useResult
$Res call({
 String id, TransactionType type, TransactionStatus status, int amountCents, String currency, LocalDate date, String walletId, String? toWalletId, String? categoryId, String? note, List<String> labelIds, String? recurrenceId, LocalDate? occurrenceDate, String? importBatchId
});




}
/// @nodoc
class _$TransactionCopyWithImpl<$Res>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._self, this._then);

  final Transaction _self;
  final $Res Function(Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? status = null,Object? amountCents = null,Object? currency = null,Object? date = null,Object? walletId = null,Object? toWalletId = freezed,Object? categoryId = freezed,Object? note = freezed,Object? labelIds = null,Object? recurrenceId = freezed,Object? occurrenceDate = freezed,Object? importBatchId = freezed,}) {
  return _then(Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransactionStatus,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,walletId: null == walletId ? _self.walletId : walletId // ignore: cast_nullable_to_non_nullable
as String,toWalletId: freezed == toWalletId ? _self.toWalletId : toWalletId // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,labelIds: null == labelIds ? _self.labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as List<String>,recurrenceId: freezed == recurrenceId ? _self.recurrenceId : recurrenceId // ignore: cast_nullable_to_non_nullable
as String?,occurrenceDate: freezed == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,importBatchId: freezed == importBatchId ? _self.importBatchId : importBatchId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Transaction].
extension TransactionPatterns on Transaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transaction value)  $default,){
final _that = this;
switch (_that) {
case _Transaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transaction value)?  $default,){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  TransactionType type,  TransactionStatus status,  int amountCents,  String currency,  LocalDate date,  String walletId,  String? toWalletId,  String? categoryId,  String? note,  List<String> labelIds,  String? recurrenceId,  LocalDate? occurrenceDate,  String? importBatchId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.type,_that.status,_that.amountCents,_that.currency,_that.date,_that.walletId,_that.toWalletId,_that.categoryId,_that.note,_that.labelIds,_that.recurrenceId,_that.occurrenceDate,_that.importBatchId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  TransactionType type,  TransactionStatus status,  int amountCents,  String currency,  LocalDate date,  String walletId,  String? toWalletId,  String? categoryId,  String? note,  List<String> labelIds,  String? recurrenceId,  LocalDate? occurrenceDate,  String? importBatchId)  $default,) {final _that = this;
switch (_that) {
case _Transaction():
return $default(_that.id,_that.type,_that.status,_that.amountCents,_that.currency,_that.date,_that.walletId,_that.toWalletId,_that.categoryId,_that.note,_that.labelIds,_that.recurrenceId,_that.occurrenceDate,_that.importBatchId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  TransactionType type,  TransactionStatus status,  int amountCents,  String currency,  LocalDate date,  String walletId,  String? toWalletId,  String? categoryId,  String? note,  List<String> labelIds,  String? recurrenceId,  LocalDate? occurrenceDate,  String? importBatchId)?  $default,) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.type,_that.status,_that.amountCents,_that.currency,_that.date,_that.walletId,_that.toWalletId,_that.categoryId,_that.note,_that.labelIds,_that.recurrenceId,_that.occurrenceDate,_that.importBatchId);case _:
  return null;

}
}

}

/// @nodoc


class _Transaction extends Transaction {
  const _Transaction({required this.id, required this.type, this.status = TransactionStatus.confirmed, required this.amountCents, this.currency = 'EUR', required this.date, required this.walletId, this.toWalletId, this.categoryId, this.note,  List<String> labelIds = const [], this.recurrenceId, this.occurrenceDate, this.importBatchId}): _labelIds = labelIds,super._();
  

@override final  String id;
@override final  TransactionType type;
@override@JsonKey() final  TransactionStatus status;
/// Sempre > 0, tranne le rettifiche che hanno segno.
@override final  int amountCents;
@override@JsonKey() final  String currency;
@override final  LocalDate date;
/// Portafoglio del movimento; per i trasferimenti è quello di origine.
@override final  String walletId;
/// Solo per i trasferimenti.
@override final  String? toWalletId;
/// Obbligatoria per spese ed entrate.
@override final  String? categoryId;
@override final  String? note;
 final  List<String> _labelIds;
@override@JsonKey() List<String> get labelIds {
  if (_labelIds is EqualUnmodifiableListView) return _labelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_labelIds);
}

@override final  String? recurrenceId;
@override final  LocalDate? occurrenceDate;
/// Import da CSV che ha creato il movimento; null se inserito nell'app. Annullare l'import
/// cancella i movimenti con questo id (non quelli che l'import ha solo aggiornato).
@override final  String? importBatchId;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionCopyWith<_Transaction> get copyWith => __$TransactionCopyWithImpl<_Transaction>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.date, date) || other.date == date)&&(identical(other.walletId, walletId) || other.walletId == walletId)&&(identical(other.toWalletId, toWalletId) || other.toWalletId == toWalletId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.note, note) || other.note == note)&&const DeepCollectionEquality().equals(other.labelIds, _labelIds)&&(identical(other.recurrenceId, recurrenceId) || other.recurrenceId == recurrenceId)&&(identical(other.occurrenceDate, occurrenceDate) || other.occurrenceDate == occurrenceDate)&&(identical(other.importBatchId, importBatchId) || other.importBatchId == importBatchId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,type,status,amountCents,currency,date,walletId,toWalletId,categoryId,note,const DeepCollectionEquality().hash(_labelIds),recurrenceId,occurrenceDate,importBatchId);
}

@override
String toString() {
    return 'Transaction(id: $id, type: $type, status: $status, amountCents: $amountCents, currency: $currency, date: $date, walletId: $walletId, toWalletId: $toWalletId, categoryId: $categoryId, note: $note, labelIds: $labelIds, recurrenceId: $recurrenceId, occurrenceDate: $occurrenceDate, importBatchId: $importBatchId)';
}


}

/// @nodoc
abstract mixin class _$TransactionCopyWith<$Res> implements $TransactionCopyWith<$Res> {
  factory _$TransactionCopyWith(_Transaction value, $Res Function(_Transaction) _then) = __$TransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, TransactionType type, TransactionStatus status, int amountCents, String currency, LocalDate date, String walletId, String? toWalletId, String? categoryId, String? note, List<String> labelIds, String? recurrenceId, LocalDate? occurrenceDate, String? importBatchId
});




}
/// @nodoc
class __$TransactionCopyWithImpl<$Res>
    implements _$TransactionCopyWith<$Res> {
  __$TransactionCopyWithImpl(this._self, this._then);

  final _Transaction _self;
  final $Res Function(_Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? status = null,Object? amountCents = null,Object? currency = null,Object? date = null,Object? walletId = null,Object? toWalletId = freezed,Object? categoryId = freezed,Object? note = freezed,Object? labelIds = null,Object? recurrenceId = freezed,Object? occurrenceDate = freezed,Object? importBatchId = freezed,}) {
  return _then(_Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransactionStatus,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,walletId: null == walletId ? _self.walletId : walletId // ignore: cast_nullable_to_non_nullable
as String,toWalletId: freezed == toWalletId ? _self.toWalletId : toWalletId // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,labelIds: null == labelIds ? _self._labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as List<String>,recurrenceId: freezed == recurrenceId ? _self.recurrenceId : recurrenceId // ignore: cast_nullable_to_non_nullable
as String?,occurrenceDate: freezed == occurrenceDate ? _self.occurrenceDate : occurrenceDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,importBatchId: freezed == importBatchId ? _self.importBatchId : importBatchId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
