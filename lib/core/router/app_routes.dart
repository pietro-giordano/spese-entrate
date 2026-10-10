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

  /// Solo in debug.
  static const componentCatalog = '/debug/catalog';

  /// Inserimento rapido; [type] è `expense`, `income` o `transfer`.
  static String add(String type) => Uri(path: '/add', queryParameters: {'type': type}).toString();

  static String transaction(String id) => '/transactions/$id';
  static String wallet(String id) => '/wallets/$id';
  static String editWallet(String id) => '/wallets/$id/edit';
  static String recurrence(String id) => '/settings/recurring/$id';
}
