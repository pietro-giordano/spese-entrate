// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Wallet {

 String get id; String get name; WalletType get type; String get currency; int get initialBalanceCents; LocalDate get initialBalanceDate; bool get includeInTotal; int get sortOrder; DateTime? get archivedAt;/// Ultima volta che l'utente ha verificato il saldo con "Aggiorna saldo" (anche senza differenze).
 LocalDate? get lastBalanceVerifiedDate;
/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletCopyWith<Wallet> get copyWith => _$WalletCopyWithImpl<Wallet>(this as Wallet, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Wallet;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Wallet&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.initialBalanceCents, _this.initialBalanceCents) || other.initialBalanceCents == _this.initialBalanceCents)&&(identical(other.initialBalanceDate, _this.initialBalanceDate) || other.initialBalanceDate == _this.initialBalanceDate)&&(identical(other.includeInTotal, _this.includeInTotal) || other.includeInTotal == _this.includeInTotal)&&(identical(other.sortOrder, _this.sortOrder) || other.sortOrder == _this.sortOrder)&&(identical(other.archivedAt, _this.archivedAt) || other.archivedAt == _this.archivedAt)&&(identical(other.lastBalanceVerifiedDate, _this.lastBalanceVerifiedDate) || other.lastBalanceVerifiedDate == _this.lastBalanceVerifiedDate));
}


@override
int get hashCode {
  final _this = this as Wallet;
  return Object.hash(runtimeType,_this.id,_this.name,_this.type,_this.currency,_this.initialBalanceCents,_this.initialBalanceDate,_this.includeInTotal,_this.sortOrder,_this.archivedAt,_this.lastBalanceVerifiedDate);
}

@override
String toString() {
  final _this = this as Wallet;
  return 'Wallet(id: ${_this.id}, name: ${_this.name}, type: ${_this.type}, currency: ${_this.currency}, initialBalanceCents: ${_this.initialBalanceCents}, initialBalanceDate: ${_this.initialBalanceDate}, includeInTotal: ${_this.includeInTotal}, sortOrder: ${_this.sortOrder}, archivedAt: ${_this.archivedAt}, lastBalanceVerifiedDate: ${_this.lastBalanceVerifiedDate})';
}


}

/// @nodoc
abstract mixin class $WalletCopyWith<$Res>  {
  factory $WalletCopyWith(Wallet value, $Res Function(Wallet) _then) = _$WalletCopyWithImpl;
@useResult
$Res call({
 String id, String name, WalletType type, String currency, int initialBalanceCents, LocalDate initialBalanceDate, bool includeInTotal, int sortOrder, DateTime? archivedAt, LocalDate? lastBalanceVerifiedDate
});




}
/// @nodoc
class _$WalletCopyWithImpl<$Res>
    implements $WalletCopyWith<$Res> {
  _$WalletCopyWithImpl(this._self, this._then);

  final Wallet _self;
  final $Res Function(Wallet) _then;

/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? currency = null,Object? initialBalanceCents = null,Object? initialBalanceDate = null,Object? includeInTotal = null,Object? sortOrder = null,Object? archivedAt = freezed,Object? lastBalanceVerifiedDate = freezed,}) {
  return _then(Wallet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WalletType,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,initialBalanceCents: null == initialBalanceCents ? _self.initialBalanceCents : initialBalanceCents // ignore: cast_nullable_to_non_nullable
as int,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as LocalDate,includeInTotal: null == includeInTotal ? _self.includeInTotal : includeInTotal // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastBalanceVerifiedDate: freezed == lastBalanceVerifiedDate ? _self.lastBalanceVerifiedDate : lastBalanceVerifiedDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,
  ));
}

}


/// Adds pattern-matching-related methods to [Wallet].
extension WalletPatterns on Wallet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Wallet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Wallet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Wallet value)  $default,){
final _that = this;
switch (_that) {
case _Wallet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Wallet value)?  $default,){
final _that = this;
switch (_that) {
case _Wallet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  WalletType type,  String currency,  int initialBalanceCents,  LocalDate initialBalanceDate,  bool includeInTotal,  int sortOrder,  DateTime? archivedAt,  LocalDate? lastBalanceVerifiedDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Wallet() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.currency,_that.initialBalanceCents,_that.initialBalanceDate,_that.includeInTotal,_that.sortOrder,_that.archivedAt,_that.lastBalanceVerifiedDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  WalletType type,  String currency,  int initialBalanceCents,  LocalDate initialBalanceDate,  bool includeInTotal,  int sortOrder,  DateTime? archivedAt,  LocalDate? lastBalanceVerifiedDate)  $default,) {final _that = this;
switch (_that) {
case _Wallet():
return $default(_that.id,_that.name,_that.type,_that.currency,_that.initialBalanceCents,_that.initialBalanceDate,_that.includeInTotal,_that.sortOrder,_that.archivedAt,_that.lastBalanceVerifiedDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  WalletType type,  String currency,  int initialBalanceCents,  LocalDate initialBalanceDate,  bool includeInTotal,  int sortOrder,  DateTime? archivedAt,  LocalDate? lastBalanceVerifiedDate)?  $default,) {final _that = this;
switch (_that) {
case _Wallet() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.currency,_that.initialBalanceCents,_that.initialBalanceDate,_that.includeInTotal,_that.sortOrder,_that.archivedAt,_that.lastBalanceVerifiedDate);case _:
  return null;

}
}

}

/// @nodoc


class _Wallet extends Wallet {
  const _Wallet({required this.id, required this.name, required this.type, this.currency = 'EUR', this.initialBalanceCents = 0, required this.initialBalanceDate, this.includeInTotal = true, this.sortOrder = 0, this.archivedAt, this.lastBalanceVerifiedDate}): super._();
  

@override final  String id;
@override final  String name;
@override final  WalletType type;
@override@JsonKey() final  String currency;
@override@JsonKey() final  int initialBalanceCents;
@override final  LocalDate initialBalanceDate;
@override@JsonKey() final  bool includeInTotal;
@override@JsonKey() final  int sortOrder;
@override final  DateTime? archivedAt;
/// Ultima volta che l'utente ha verificato il saldo con "Aggiorna saldo" (anche senza differenze).
@override final  LocalDate? lastBalanceVerifiedDate;

/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletCopyWith<_Wallet> get copyWith => __$WalletCopyWithImpl<_Wallet>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Wallet&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.initialBalanceCents, initialBalanceCents) || other.initialBalanceCents == initialBalanceCents)&&(identical(other.initialBalanceDate, initialBalanceDate) || other.initialBalanceDate == initialBalanceDate)&&(identical(other.includeInTotal, includeInTotal) || other.includeInTotal == includeInTotal)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.lastBalanceVerifiedDate, lastBalanceVerifiedDate) || other.lastBalanceVerifiedDate == lastBalanceVerifiedDate));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,type,currency,initialBalanceCents,initialBalanceDate,includeInTotal,sortOrder,archivedAt,lastBalanceVerifiedDate);
}

@override
String toString() {
    return 'Wallet(id: $id, name: $name, type: $type, currency: $currency, initialBalanceCents: $initialBalanceCents, initialBalanceDate: $initialBalanceDate, includeInTotal: $includeInTotal, sortOrder: $sortOrder, archivedAt: $archivedAt, lastBalanceVerifiedDate: $lastBalanceVerifiedDate)';
}


}

/// @nodoc
abstract mixin class _$WalletCopyWith<$Res> implements $WalletCopyWith<$Res> {
  factory _$WalletCopyWith(_Wallet value, $Res Function(_Wallet) _then) = __$WalletCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, WalletType type, String currency, int initialBalanceCents, LocalDate initialBalanceDate, bool includeInTotal, int sortOrder, DateTime? archivedAt, LocalDate? lastBalanceVerifiedDate
});




}
/// @nodoc
class __$WalletCopyWithImpl<$Res>
    implements _$WalletCopyWith<$Res> {
  __$WalletCopyWithImpl(this._self, this._then);

  final _Wallet _self;
  final $Res Function(_Wallet) _then;

/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? currency = null,Object? initialBalanceCents = null,Object? initialBalanceDate = null,Object? includeInTotal = null,Object? sortOrder = null,Object? archivedAt = freezed,Object? lastBalanceVerifiedDate = freezed,}) {
  return _then(_Wallet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WalletType,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,initialBalanceCents: null == initialBalanceCents ? _self.initialBalanceCents : initialBalanceCents // ignore: cast_nullable_to_non_nullable
as int,initialBalanceDate: null == initialBalanceDate ? _self.initialBalanceDate : initialBalanceDate // ignore: cast_nullable_to_non_nullable
as LocalDate,includeInTotal: null == includeInTotal ? _self.includeInTotal : includeInTotal // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastBalanceVerifiedDate: freezed == lastBalanceVerifiedDate ? _self.lastBalanceVerifiedDate : lastBalanceVerifiedDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,
  ));
}


}

// dart format on
