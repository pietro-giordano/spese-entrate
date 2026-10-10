/// Esegue più scritture, anche su repository diversi, come un'unica operazione:
/// o riescono tutte, o in caso di errore non ne resta nessuna.
abstract interface class AtomicWrites {
  Future<T> run<T>(Future<T> Function() action);
}
