// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_filters.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionFilters {

 TypeFilter get type; Set<String> get walletIds; Set<String> get categoryIds; Set<String> get labelIds;/// Esclusioni: un movimento con uno di questi portafogli, categorie o label non compare mai,
/// anche se è incluso da un altro filtro (l'esclusione vince).
 Set<String> get excludedWalletIds; Set<String> get excludedCategoryIds; Set<String> get excludedLabelIds;/// "Senza label" incluso: aggiunge le spese e le entrate senza nessuna label. È una condizione
/// sull'assenza di label, non una label nel database: [labelMatch] vale solo per [labelIds].
 bool get withoutLabels;/// "Senza label" escluso: toglie le spese e le entrate senza nessuna label.
 bool get excludeWithoutLabels; LabelMatch get labelMatch; bool get showTransfers;
/// Create a copy of TransactionFilters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFiltersCopyWith<TransactionFilters> get copyWith => _$TransactionFiltersCopyWithImpl<TransactionFilters>(this as TransactionFilters, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TransactionFilters;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFilters&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.walletIds, _this.walletIds)&&const DeepCollectionEquality().equals(other.categoryIds, _this.categoryIds)&&const DeepCollectionEquality().equals(other.labelIds, _this.labelIds)&&const DeepCollectionEquality().equals(other.excludedWalletIds, _this.excludedWalletIds)&&const DeepCollectionEquality().equals(other.excludedCategoryIds, _this.excludedCategoryIds)&&const DeepCollectionEquality().equals(other.excludedLabelIds, _this.excludedLabelIds)&&(identical(other.withoutLabels, _this.withoutLabels) || other.withoutLabels == _this.withoutLabels)&&(identical(other.excludeWithoutLabels, _this.excludeWithoutLabels) || other.excludeWithoutLabels == _this.excludeWithoutLabels)&&(identical(other.labelMatch, _this.labelMatch) || other.labelMatch == _this.labelMatch)&&(identical(other.showTransfers, _this.showTransfers) || other.showTransfers == _this.showTransfers));
}


@override
int get hashCode {
  final _this = this as TransactionFilters;
  return Object.hash(runtimeType,_this.type,const DeepCollectionEquality().hash(_this.walletIds),const DeepCollectionEquality().hash(_this.categoryIds),const DeepCollectionEquality().hash(_this.labelIds),const DeepCollectionEquality().hash(_this.excludedWalletIds),const DeepCollectionEquality().hash(_this.excludedCategoryIds),const DeepCollectionEquality().hash(_this.excludedLabelIds),_this.withoutLabels,_this.excludeWithoutLabels,_this.labelMatch,_this.showTransfers);
}

@override
String toString() {
  final _this = this as TransactionFilters;
  return 'TransactionFilters(type: ${_this.type}, walletIds: ${_this.walletIds}, categoryIds: ${_this.categoryIds}, labelIds: ${_this.labelIds}, excludedWalletIds: ${_this.excludedWalletIds}, excludedCategoryIds: ${_this.excludedCategoryIds}, excludedLabelIds: ${_this.excludedLabelIds}, withoutLabels: ${_this.withoutLabels}, excludeWithoutLabels: ${_this.excludeWithoutLabels}, labelMatch: ${_this.labelMatch}, showTransfers: ${_this.showTransfers})';
}


}

/// @nodoc
abstract mixin class $TransactionFiltersCopyWith<$Res>  {
  factory $TransactionFiltersCopyWith(TransactionFilters value, $Res Function(TransactionFilters) _then) = _$TransactionFiltersCopyWithImpl;
@useResult
$Res call({
 TypeFilter type, Set<String> walletIds, Set<String> categoryIds, Set<String> labelIds, Set<String> excludedWalletIds, Set<String> excludedCategoryIds, Set<String> excludedLabelIds, bool withoutLabels, bool excludeWithoutLabels, LabelMatch labelMatch, bool showTransfers
});




}
/// @nodoc
class _$TransactionFiltersCopyWithImpl<$Res>
    implements $TransactionFiltersCopyWith<$Res> {
  _$TransactionFiltersCopyWithImpl(this._self, this._then);

  final TransactionFilters _self;
  final $Res Function(TransactionFilters) _then;

/// Create a copy of TransactionFilters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? walletIds = null,Object? categoryIds = null,Object? labelIds = null,Object? excludedWalletIds = null,Object? excludedCategoryIds = null,Object? excludedLabelIds = null,Object? withoutLabels = null,Object? excludeWithoutLabels = null,Object? labelMatch = null,Object? showTransfers = null,}) {
  return _then(TransactionFilters(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeFilter,walletIds: null == walletIds ? _self.walletIds : walletIds // ignore: cast_nullable_to_non_nullable
as Set<String>,categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>,labelIds: null == labelIds ? _self.labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as Set<String>,excludedWalletIds: null == excludedWalletIds ? _self.excludedWalletIds : excludedWalletIds // ignore: cast_nullable_to_non_nullable
as Set<String>,excludedCategoryIds: null == excludedCategoryIds ? _self.excludedCategoryIds : excludedCategoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>,excludedLabelIds: null == excludedLabelIds ? _self.excludedLabelIds : excludedLabelIds // ignore: cast_nullable_to_non_nullable
as Set<String>,withoutLabels: null == withoutLabels ? _self.withoutLabels : withoutLabels // ignore: cast_nullable_to_non_nullable
as bool,excludeWithoutLabels: null == excludeWithoutLabels ? _self.excludeWithoutLabels : excludeWithoutLabels // ignore: cast_nullable_to_non_nullable
as bool,labelMatch: null == labelMatch ? _self.labelMatch : labelMatch // ignore: cast_nullable_to_non_nullable
as LabelMatch,showTransfers: null == showTransfers ? _self.showTransfers : showTransfers // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionFilters].
extension TransactionFiltersPatterns on TransactionFilters {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionFilters value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionFilters() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionFilters value)  $default,){
final _that = this;
switch (_that) {
case _TransactionFilters():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionFilters value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionFilters() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TypeFilter type,  Set<String> walletIds,  Set<String> categoryIds,  Set<String> labelIds,  Set<String> excludedWalletIds,  Set<String> excludedCategoryIds,  Set<String> excludedLabelIds,  bool withoutLabels,  bool excludeWithoutLabels,  LabelMatch labelMatch,  bool showTransfers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionFilters() when $default != null:
return $default(_that.type,_that.walletIds,_that.categoryIds,_that.labelIds,_that.excludedWalletIds,_that.excludedCategoryIds,_that.excludedLabelIds,_that.withoutLabels,_that.excludeWithoutLabels,_that.labelMatch,_that.showTransfers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TypeFilter type,  Set<String> walletIds,  Set<String> categoryIds,  Set<String> labelIds,  Set<String> excludedWalletIds,  Set<String> excludedCategoryIds,  Set<String> excludedLabelIds,  bool withoutLabels,  bool excludeWithoutLabels,  LabelMatch labelMatch,  bool showTransfers)  $default,) {final _that = this;
switch (_that) {
case _TransactionFilters():
return $default(_that.type,_that.walletIds,_that.categoryIds,_that.labelIds,_that.excludedWalletIds,_that.excludedCategoryIds,_that.excludedLabelIds,_that.withoutLabels,_that.excludeWithoutLabels,_that.labelMatch,_that.showTransfers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TypeFilter type,  Set<String> walletIds,  Set<String> categoryIds,  Set<String> labelIds,  Set<String> excludedWalletIds,  Set<String> excludedCategoryIds,  Set<String> excludedLabelIds,  bool withoutLabels,  bool excludeWithoutLabels,  LabelMatch labelMatch,  bool showTransfers)?  $default,) {final _that = this;
switch (_that) {
case _TransactionFilters() when $default != null:
return $default(_that.type,_that.walletIds,_that.categoryIds,_that.labelIds,_that.excludedWalletIds,_that.excludedCategoryIds,_that.excludedLabelIds,_that.withoutLabels,_that.excludeWithoutLabels,_that.labelMatch,_that.showTransfers);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionFilters extends TransactionFilters {
  const _TransactionFilters({this.type = TypeFilter.all,  Set<String> walletIds = const <String>{},  Set<String> categoryIds = const <String>{},  Set<String> labelIds = const <String>{},  Set<String> excludedWalletIds = const <String>{},  Set<String> excludedCategoryIds = const <String>{},  Set<String> excludedLabelIds = const <String>{}, this.withoutLabels = false, this.excludeWithoutLabels = false, this.labelMatch = LabelMatch.any, this.showTransfers = true}): _walletIds = walletIds,_categoryIds = categoryIds,_labelIds = labelIds,_excludedWalletIds = excludedWalletIds,_excludedCategoryIds = excludedCategoryIds,_excludedLabelIds = excludedLabelIds,super._();
  

@override@JsonKey() final  TypeFilter type;
 final  Set<String> _walletIds;
@override@JsonKey() Set<String> get walletIds {
  if (_walletIds is EqualUnmodifiableSetView) return _walletIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_walletIds);
}

 final  Set<String> _categoryIds;
@override@JsonKey() Set<String> get categoryIds {
  if (_categoryIds is EqualUnmodifiableSetView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_categoryIds);
}

 final  Set<String> _labelIds;
@override@JsonKey() Set<String> get labelIds {
  if (_labelIds is EqualUnmodifiableSetView) return _labelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_labelIds);
}

/// Esclusioni: un movimento con uno di questi portafogli, categorie o label non compare mai,
/// anche se è incluso da un altro filtro (l'esclusione vince).
 final  Set<String> _excludedWalletIds;
/// Esclusioni: un movimento con uno di questi portafogli, categorie o label non compare mai,
/// anche se è incluso da un altro filtro (l'esclusione vince).
@override@JsonKey() Set<String> get excludedWalletIds {
  if (_excludedWalletIds is EqualUnmodifiableSetView) return _excludedWalletIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_excludedWalletIds);
}

 final  Set<String> _excludedCategoryIds;
@override@JsonKey() Set<String> get excludedCategoryIds {
  if (_excludedCategoryIds is EqualUnmodifiableSetView) return _excludedCategoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_excludedCategoryIds);
}

 final  Set<String> _excludedLabelIds;
@override@JsonKey() Set<String> get excludedLabelIds {
  if (_excludedLabelIds is EqualUnmodifiableSetView) return _excludedLabelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_excludedLabelIds);
}

/// "Senza label" incluso: aggiunge le spese e le entrate senza nessuna label. È una condizione
/// sull'assenza di label, non una label nel database: [labelMatch] vale solo per [labelIds].
@override@JsonKey() final  bool withoutLabels;
/// "Senza label" escluso: toglie le spese e le entrate senza nessuna label.
@override@JsonKey() final  bool excludeWithoutLabels;
@override@JsonKey() final  LabelMatch labelMatch;
@override@JsonKey() final  bool showTransfers;

/// Create a copy of TransactionFilters
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionFiltersCopyWith<_TransactionFilters> get copyWith => __$TransactionFiltersCopyWithImpl<_TransactionFilters>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionFilters&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.walletIds, _walletIds)&&const DeepCollectionEquality().equals(other.categoryIds, _categoryIds)&&const DeepCollectionEquality().equals(other.labelIds, _labelIds)&&const DeepCollectionEquality().equals(other.excludedWalletIds, _excludedWalletIds)&&const DeepCollectionEquality().equals(other.excludedCategoryIds, _excludedCategoryIds)&&const DeepCollectionEquality().equals(other.excludedLabelIds, _excludedLabelIds)&&(identical(other.withoutLabels, withoutLabels) || other.withoutLabels == withoutLabels)&&(identical(other.excludeWithoutLabels, excludeWithoutLabels) || other.excludeWithoutLabels == excludeWithoutLabels)&&(identical(other.labelMatch, labelMatch) || other.labelMatch == labelMatch)&&(identical(other.showTransfers, showTransfers) || other.showTransfers == showTransfers));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_walletIds),const DeepCollectionEquality().hash(_categoryIds),const DeepCollectionEquality().hash(_labelIds),const DeepCollectionEquality().hash(_excludedWalletIds),const DeepCollectionEquality().hash(_excludedCategoryIds),const DeepCollectionEquality().hash(_excludedLabelIds),withoutLabels,excludeWithoutLabels,labelMatch,showTransfers);
}

@override
String toString() {
    return 'TransactionFilters(type: $type, walletIds: $walletIds, categoryIds: $categoryIds, labelIds: $labelIds, excludedWalletIds: $excludedWalletIds, excludedCategoryIds: $excludedCategoryIds, excludedLabelIds: $excludedLabelIds, withoutLabels: $withoutLabels, excludeWithoutLabels: $excludeWithoutLabels, labelMatch: $labelMatch, showTransfers: $showTransfers)';
}


}

/// @nodoc
abstract mixin class _$TransactionFiltersCopyWith<$Res> implements $TransactionFiltersCopyWith<$Res> {
  factory _$TransactionFiltersCopyWith(_TransactionFilters value, $Res Function(_TransactionFilters) _then) = __$TransactionFiltersCopyWithImpl;
@override @useResult
$Res call({
 TypeFilter type, Set<String> walletIds, Set<String> categoryIds, Set<String> labelIds, Set<String> excludedWalletIds, Set<String> excludedCategoryIds, Set<String> excludedLabelIds, bool withoutLabels, bool excludeWithoutLabels, LabelMatch labelMatch, bool showTransfers
});




}
/// @nodoc
class __$TransactionFiltersCopyWithImpl<$Res>
    implements _$TransactionFiltersCopyWith<$Res> {
  __$TransactionFiltersCopyWithImpl(this._self, this._then);

  final _TransactionFilters _self;
  final $Res Function(_TransactionFilters) _then;

/// Create a copy of TransactionFilters
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? walletIds = null,Object? categoryIds = null,Object? labelIds = null,Object? excludedWalletIds = null,Object? excludedCategoryIds = null,Object? excludedLabelIds = null,Object? withoutLabels = null,Object? excludeWithoutLabels = null,Object? labelMatch = null,Object? showTransfers = null,}) {
  return _then(_TransactionFilters(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeFilter,walletIds: null == walletIds ? _self._walletIds : walletIds // ignore: cast_nullable_to_non_nullable
as Set<String>,categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>,labelIds: null == labelIds ? _self._labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as Set<String>,excludedWalletIds: null == excludedWalletIds ? _self._excludedWalletIds : excludedWalletIds // ignore: cast_nullable_to_non_nullable
as Set<String>,excludedCategoryIds: null == excludedCategoryIds ? _self._excludedCategoryIds : excludedCategoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>,excludedLabelIds: null == excludedLabelIds ? _self._excludedLabelIds : excludedLabelIds // ignore: cast_nullable_to_non_nullable
as Set<String>,withoutLabels: null == withoutLabels ? _self.withoutLabels : withoutLabels // ignore: cast_nullable_to_non_nullable
as bool,excludeWithoutLabels: null == excludeWithoutLabels ? _self.excludeWithoutLabels : excludeWithoutLabels // ignore: cast_nullable_to_non_nullable
as bool,labelMatch: null == labelMatch ? _self.labelMatch : labelMatch // ignore: cast_nullable_to_non_nullable
as LabelMatch,showTransfers: null == showTransfers ? _self.showTransfers : showTransfers // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
