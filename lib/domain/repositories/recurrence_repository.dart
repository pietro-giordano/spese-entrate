import '../../core/dates.dart';
import '../models/recurrence_exception.dart';
import '../models/recurrence_rule.dart';
import '../models/transaction.dart';

/// Regole ricorrenti, eccezioni e generazione delle occorrenze.
/// Ogni metodo che scrive è un'unica transazione, outbox compreso.
abstract interface class RecurrenceRepository {
  /// Regole non cancellate, per nome.
  Stream<List<RecurrenceRule>> watchAll();

  Future<RecurrenceRule?> getById(String id);

  /// Eccezioni (date saltate) non cancellate di tutte le regole.
  Stream<List<RecurrenceException>> watchExceptions();

  /// Date delle occorrenze di [ruleId] il cui movimento è stato eliminato: occupano la data,
  /// quindi non si rigenerano, ma vanno mostrate come eliminate.
  Stream<Set<LocalDate>> watchDeletedOccurrences(String ruleId);

  /// Crea o aggiorna la regola. [skippedDates] diventano eccezioni: servono per le occorrenze
  /// arretrate che l'utente non vuole registrare.
  Future<void> save(RecurrenceRule rule, {List<LocalDate> skippedDates = const []});

  /// Mette in pausa: il generatore la ignora finché non riprende.
  Future<void> pause(String ruleId);

  /// Riprende una regola in pausa. Le occorrenze dal giorno della pausa a ieri non si recuperano:
  /// diventano eccezioni, e i `pending` di quelle date si cancellano. Così vale anche dopo un riavvio.
  Future<void> resume(String ruleId, {required LocalDate today});

  /// Salta un'occorrenza: eccezione + cancellazione logica del suo `pending`, se esiste.
  /// Un movimento già confermato resta.
  Future<void> skip(String ruleId, LocalDate occurrenceDate);

  /// Cancella la regola e i suoi `pending`; i movimenti confermati restano.
  Future<void> delete(String ruleId);

  /// Movimento dell'occorrenza [occurrenceDate]: quello esistente, oppure uno nuovo `pending`
  /// con l'ID deterministico (per "Modifica" su un'occorrenza non ancora generata).
  /// Null se l'occorrenza è stata eliminata o saltata.
  Future<Transaction?> occurrenceTransaction(String ruleId, LocalDate occurrenceDate);

  /// "Questa e le successive": termina la regola prima di [boundary] (data originale
  /// dell'occorrenza) e salva [next], che parte dalla data scelta nel form.
  /// I `pending` successivi della vecchia regola si cancellano; quelli confermati, eliminati
  /// o saltati restano e la loro controparte nella nuova regola viene saltata.
  /// Restituisce la regola nuova come salvata. Lancia `SplitDateException` se le date si sovrappongono.
  Future<RecurrenceRule> split(String ruleId, {required LocalDate boundary, required RecurrenceRule next});

  /// Crea le occorrenze mancanti delle regole attive: `auto` fino a [today] come confermate
  /// (con la data dell'occorrenza), `confirm` fino a [today] + 7 come `pending`.
  /// Le occorrenze già presenti (anche cancellate) o saltate non si ricreano: è idempotente.
  /// I `pending` delle regole `auto` arrivati a [today] diventano confermati.
  /// Restituisce quanti movimenti ha creato o confermato.
  Future<int> generate({required LocalDate today});
}
