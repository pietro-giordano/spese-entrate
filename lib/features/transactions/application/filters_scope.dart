/// Da quale tab si apre la schermata Filtri: decide quale stato modificare e quali sezioni
/// mostrare. In Grafici e Confronta contano solo portafogli, categorie e label.
enum FiltersScope {
  transactions,
  charts,
  compare;

  /// Tipo, periodo e "Mostra trasferimenti" hanno senso solo nella lista Movimenti.
  bool get isAnalytics => this != FiltersScope.transactions;

  /// Valore del parametro `scope` della rotta; sconosciuto o assente = Movimenti.
  static FiltersScope fromQuery(String? value) =>
      FiltersScope.values.firstWhere((s) => s.name == value, orElse: () => FiltersScope.transactions);
}
