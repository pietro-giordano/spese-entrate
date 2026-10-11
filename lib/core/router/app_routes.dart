/// Indirizzi dell'app in un solo posto, per evitare stringhe sparse e refusi.
abstract final class AppRoutes {
  // Tab
  static const transactions = '/';
  static const wallets = '/wallets';
  static const charts = '/charts';
  static const compare = '/compare';

  // Altre schermate
  static const filters = '/filters';
  static const newWallet = '/wallets/new';
  static const settings = '/settings';
  static const categories = '/settings/categories';
  static const recurring = '/settings/recurring';
  static const backup = '/settings/backup';
  static const import = '/settings/import';
  static const imports = '/settings/imports';

  /// Solo in debug.
  static const componentCatalog = '/debug/catalog';

  /// Inserimento rapido; [type] è `expense`, `income` o `transfer`.
  /// Con [repeat] si apre subito il pannello "Data e ripetizione" (Nuova ricorrenza).
  static String add(String type, {bool repeat = false}) =>
      Uri(path: '/add', queryParameters: {'type': type, if (repeat) 'repeat': '1'}).toString();

  /// Inserimento rapido già compilato con il movimento da confermare [id].
  static String confirm(String id) => Uri(path: '/add', queryParameters: {'confirm': id}).toString();

  /// Filtri di una tab con filtri propri: [scope] è `charts` o `compare` (vedi `FiltersScope`).
  static String filtersOf(String scope) => Uri(path: filters, queryParameters: {'scope': scope}).toString();

  static String transaction(String id) => '/transactions/$id';

  /// Modifica movimento che al salvataggio applica "questa e le successive".
  static String transactionFollowing(String id) => '/transactions/$id?scope=following';
  static String wallet(String id) => '/wallets/$id';
  static String editWallet(String id) => '/wallets/$id/edit';
  static String recurrence(String id) => '/settings/recurring/$id';
}
