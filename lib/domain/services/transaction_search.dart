/// Ricerca nei movimenti: logica pura, su tutto lo storico.
library;

import '../../core/money.dart';
import '../models/transaction.dart';
import '../models/transaction_filters.dart';
import 'transaction_list.dart';

/// Lettere accentate → lettera semplice, per cercare senza distinzione di accenti.
const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', //
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n', 'ß': 'ss', 'œ': 'oe', 'æ': 'ae',
};

/// Testo per il confronto: minuscole e senza accenti ("Caffè" → "caffe").
String foldForSearch(String text) {
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}

/// Un numero, con o senza decimali: "64", "64,20", "64.2", "1.234,56".
final _amountToken = RegExp(r'^\d+([.,]\d+)*$');

/// Nomi da cercare oltre alla nota, per id.
class SearchNames {
  const SearchNames({this.wallets = const {}, this.categories = const {}, this.labels = const {}});

  final Map<String, String> wallets;
  final Map<String, String> categories;
  final Map<String, String> labels;
}

/// Una ricerca: le parole del testo cercato, già normalizzate. Vuota se il testo è vuoto.
class SearchQuery {
  SearchQuery(String text)
    : raw = text.trim(),
      _tokens = [
        for (final token in text.trim().split(RegExp(r'\s+')))
          if (token.isNotEmpty) token,
      ];

  final String raw;
  final List<String> _tokens;

  bool get isEmpty => _tokens.isEmpty;

  /// Il movimento contiene **tutte** le parole: ognuna nella nota, nella categoria, nelle label,
  /// nei portafogli o, se è un numero, nell'importo.
  bool matches(Transaction tx, SearchNames names) {
    if (isEmpty) return false;
    final haystack = foldForSearch(
      [
        tx.note ?? '',
        names.categories[tx.categoryId] ?? '',
        for (final id in tx.labelIds) names.labels[id] ?? '',
        names.wallets[tx.walletId] ?? '',
        if (tx.toWalletId != null) names.wallets[tx.toWalletId] ?? '',
      ].join('\n'),
    );
    return _tokens.every((token) => haystack.contains(foldForSearch(token)) || _amountMatches(tx.amountCents, token));
  }

  /// "64,20" → importo esatto; "64" → importi da 64,00 a 64,99. Il segno non conta (le spese
  /// sono positive, le rettifiche possono essere negative).
  static bool _amountMatches(int amountCents, String token) {
    if (!_amountToken.hasMatch(token)) return false;
    final amount = amountCents.abs();
    if (!token.contains(',') && !token.contains('.')) return amount ~/ 100 == int.parse(token);
    final cents = parseCents(token);
    return cents != null && amount == cents;
  }
}

/// Risultati della ricerca su tutto lo storico: solo movimenti confermati (come la lista) che
/// passano i [filters] attivi, nell'ordine di [transactions] (dal più recente).
List<Transaction> searchTransactions(
  Iterable<Transaction> transactions,
  SearchQuery query, {
  required SearchNames names,
  TransactionFilters filters = const TransactionFilters(),
}) {
  if (query.isEmpty) return const [];
  return [
    for (final tx in transactions)
      if (tx.isConfirmed && matchesFilters(tx, filters) && query.matches(tx, names)) tx,
  ];
}
