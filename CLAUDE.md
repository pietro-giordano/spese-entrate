# CLAUDE.md — App Spese & Entrate

App mobile Flutter per gestire spese, entrate, trasferimenti e portafogli personali.
Local-first: funziona offline e senza account, ma dati e architettura sono pronti
per una futura sincronizzazione con un server Laravel.

## Modo di lavorare

- Lo sviluppatore (Pietro) conosce bene Laravel/PHP e Vue, ma sta **imparando Flutter e Dart**.
  Scrivi codice idiomatico e leggibile, senza astrazioni premature.
- Lavora **solo sul passo richiesto** dal prompt. Non anticipare funzionalità dei passi successivi.
- Non aggiungere pacchetti fuori dalla sezione Stack senza chiedere.
- Prima di un refactor che tocca più di 3 file, descrivi il piano e chiedi conferma.
- Se un requisito è ambiguo, fai una sola domanda precisa invece di inventare.
- Identificatori del codice in inglese; testi dell'interfaccia in italiano.

### Fine di ogni passo

Alla fine di ogni passo, sempre, in quest'ordine:

1. Se hai toccato file con annotazioni: `dart run build_runner build --delete-conflicting-outputs`.
2. `flutter analyze` senza errori né warning.
3. `flutter test` tutto verde.
4. Elenco dei file creati o modificati.
5. **Spiegazione per imparare** (max 10 righe): i concetti Flutter/Dart introdotti nel passo,
   con un parallelo a Laravel/Vue quando aiuta.
6. Un messaggio di commit proposto (stile Conventional Commits, in inglese).

## Stack

- Flutter stable, Dart 3, solo iOS e Android.
- Stato: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` (dev).
- Navigazione: `go_router`.
- Database: `drift`, `drift_flutter`, `drift_dev` (dev), `build_runner` (dev).
- Modelli: `freezed`, `freezed_annotation`, `json_annotation`, `json_serializable` (dev).
- ID e hash: `uuid`, `crypto`.
- Grafici: `fl_chart`.
- File e media: `image_picker`, `file_picker`, `path_provider`, `path`, `open_filex` (PDF con un'app esterna).
- Sistema: `local_auth`, `share_plus`, `package_info_plus` (versione e build nelle Impostazioni).
- Formati: `intl`, `flutter_localizations` (sdk), `csv`, `collection`.
- Lint: `flutter_lints`.
- Solo al passo 16: `flutter_launcher_icons`, `flutter_native_splash` (dev).

Usa le ultime versioni stabili compatibili tra loro.

## Architettura

Flusso: interfaccia → stato (Riverpod) → repository astratti → sorgente dati.
Oggi l'unica sorgente è Drift; in futuro si aggiungono sorgente remota e servizio di sync
senza modificare le schermate.

```
lib/
  main.dart                 # bootstrap: ProviderScope, apertura DB, generatore ricorrenze
  app.dart                  # MaterialApp.router, temi, localizzazione
  core/
    ids.dart                # UUID v7 / v5
    money.dart              # centesimi, formattazione, parsing
    dates.dart              # LocalDate, intervalli di periodo
    theme/                  # token, ThemeData, ThemeExtension
    router/                 # go_router
    widgets/                # componenti riusabili del design system
  domain/
    models/                 # modelli freezed (Transaction, Wallet, Category, ...)
    repositories/           # interfacce astratte
    services/               # logica pura: saldi, statistiche, ricorrenze
  data/
    db/                     # AppDatabase, tabelle, DAO, migrazioni, seed
    repositories/           # implementazioni Drift delle interfacce
  features/
    transactions/           # lista, inserimento rapido, modifica, filtri
    wallets/
    analytics/              # grafici e confronto
    recurring/
    settings/               # impostazioni, categorie e label, export
```

Ogni feature ha `presentation/` (schermate e widget) e `application/` (provider e controller).
La logica di dominio sta in `domain/services/` come funzioni pure, testabili senza Flutter.

## Regole dati (predisposizione alla sync)

- **ID**: UUID v7 generati sul dispositivo con generatore crittografico (`CryptoRNG` del pacchetto
  `uuid`). Mai interi autoincrementali, tranne nella tabella locale `outbox`.
- **ID deterministici**: le occorrenze delle ricorrenze usano UUID v5 con un namespace costante
  dell'app e nome `"<recurrence_id>|<occurrence_date>"`.
- **Campi comuni** su ogni tabella sincronizzabile: `id`, `created_at`, `updated_at`,
  `deleted_at` (nullable), `device_id`. Timestamp = millisecondi UTC (int).
- **Cancellazione logica**: si imposta `deleted_at`; le query normali escludono i cancellati.
- **Outbox**: ogni scrittura su una tabella sincronizzabile inserisce una riga in `outbox`
  nella stessa transazione.
- **Importi**: interi in centesimi + codice valuta (`EUR`). Mai `double` per i soldi.
- **Date dei movimenti**: data di calendario `TEXT 'YYYY-MM-DD'`, separata dai timestamp.
- **Valori derivati non salvati**: saldi e totali si calcolano sempre dalle righe.
- **Duplica** crea sempre un nuovo ID. Un futuro **ripristino** aggiorna i record esistenti per ID,
  non li ricrea.
- `device_id` generato al primo avvio e salvato in `app_meta`.
- **Lapidi definitive**: un record cancellato (`deleted_at`) non torna mai attivo con un salvataggio
  o un collegamento (es. `save` di una label cancellata → `DeletedLabelException`; i movimenti
  non si ricollegano a label cancellate; non si unisce verso/da record cancellati). Per riusare
  un nome si crea un record nuovo con un nuovo ID.
- **Operazioni composte** (unisci, elimina con collegamenti, aggiorna saldo): una sola transazione
  Drift nel repository, outbox compreso. Se servono più repository si usa `AtomicWrites`.
  I test di rollback simulano l'errore con un trigger SQLite `RAISE(ABORT)`.

## Schema

Colonne in snake_case. "Comuni" = `id TEXT PK, created_at INT, updated_at INT, deleted_at INT NULL, device_id TEXT`.

**wallets** — comuni +
`name TEXT`, `type TEXT` (cash | checking | card | savings | investment | other),
`currency TEXT DEFAULT 'EUR'`, `initial_balance_cents INT`, `initial_balance_date TEXT`,
`include_in_total BOOL DEFAULT true`, `sort_order INT`, `archived_at INT NULL`,
`last_balance_verified_date TEXT NULL` (data dell'ultima verifica con "Aggiorna saldo", dalla versione 2 dello schema).

**categories** — comuni +
`name TEXT`, `kind TEXT` (expense | income), `color INT`, `sort_order INT`, `archived_at INT NULL`.
Nome unico **per tipo** tra le categorie non cancellate (anche archiviate), senza distinzione di
maiuscole e spazi: "Regali" di spesa e "Regali" di entrata sono ammesse (controllo nel repository,
`DuplicateCategoryNameException`).

**labels** — comuni + `name TEXT`, `color INT`.
Nome unico tra le label non cancellate (controllo nel repository).

**transactions** — comuni +
`type TEXT` (expense | income | transfer | adjustment),
`status TEXT DEFAULT 'confirmed'` (confirmed | pending),
`amount_cents INT` (sempre > 0, tranne `adjustment` che ha segno),
`currency TEXT`, `date TEXT`, `wallet_id TEXT` (origine per i trasferimenti),
`to_wallet_id TEXT NULL` (solo transfer), `category_id TEXT NULL` (obbligatoria per expense/income),
`note TEXT NULL`, `recurrence_id TEXT NULL`, `occurrence_date TEXT NULL`.
`import_batch_id TEXT NULL` (import da cui viene il movimento, dalla v3).
Indici: `date`, `wallet_id`, `category_id`, `import_batch_id`. Vincolo unico: `(recurrence_id, occurrence_date)`.

**transaction_labels** — comuni + `transaction_id TEXT`, `label_id TEXT`.
Vincolo unico: `(transaction_id, label_id)`.

**attachments** — comuni +
`transaction_id TEXT`, `local_path TEXT` (relativo alla cartella documenti),
`mime_type TEXT`, `size_bytes INT`, `sha256 TEXT`, `remote_url TEXT NULL`.

**recurrence_rules** — comuni +
`name TEXT`, `type TEXT` (expense | income | transfer), `amount_cents INT`, `currency TEXT`,
`wallet_id TEXT`, `to_wallet_id TEXT NULL`, `category_id TEXT NULL`, `note TEXT NULL`,
`label_ids TEXT` (array JSON), `frequency TEXT` (daily | weekly | monthly | yearly),
`interval INT DEFAULT 1`, `by_weekday INT NULL` (1 = lunedì), `by_month_day INT NULL`,
`by_month INT NULL`, `start_date TEXT`, `end_date TEXT NULL`, `max_count INT NULL`,
`mode TEXT` (auto | confirm), `paused_at INT NULL`.

**recurrence_exceptions** — comuni + `rule_id TEXT`, `occurrence_date TEXT`, `kind TEXT` (skip).
Vincolo unico: `(rule_id, occurrence_date)`.

**imports** (dalla v3) — comuni +
`file_name TEXT`, `row_count INT`, `inserted_count INT`, `updated_count INT` (conteggi ≥ 0),
`undone_at INT NULL` (quando l'import è stato annullato).

**settings** (sincronizzabile) — comuni + `key TEXT UNIQUE`, `value TEXT`.
Chiavi: `default_expense_wallet_id`, `default_income_wallet_id`, `week_start` (1 = lunedì),
`default_period` (month), `currency` (EUR).

**app_meta** (solo locale, non sincronizzata) — `key TEXT PK`, `value TEXT`.
Chiavi: `device_id`, `theme_mode` (system | light | dark), `biometric_lock` (bool),
`balances_on_open` (visible | hidden | remember), `balances_hidden` (bool, ultima scelta dell'occhio),
`profile_name`, `profile_email`.

**outbox** (solo locale) — `id INT PK AUTOINCREMENT`, `entity TEXT`, `entity_id TEXT`,
`op TEXT` (upsert | delete), `changed_at INT`.

## Migrazioni dello schema

Versione attuale: **4**. Storico: v1 schema iniziale; v2 `wallets.last_balance_verified_date`;
v3 tabella `imports` e `transactions.import_batch_id` (con indice); v4 solo dati, tabelle invariate:
le regole con nome vuoto o uguale alla categoria (senza distinzione di maiuscole e spazi), non
cancellate e con la nota compilata prendono la nota come nome (con `updated_at`, `device_id` e outbox).

Ogni modifica dello schema (tabelle, colonne, indici, vincoli) segue sempre questi passi:

1. Modifica le tabelle in `lib/data/db/tables.dart` (e l'elenco in `@DriftDatabase` se la tabella
   è nuova). Le colonne nuove su tabelle esistenti sono `nullable` o hanno un default.
2. Incrementa `schemaVersion` in `AppDatabase`.
3. `dart run build_runner build --delete-conflicting-outputs`.
4. `dart run drift_dev make-migrations`: salva `drift_schemas/app_database/drift_schema_vN.json`,
   rigenera `lib/data/db/app_database.steps.dart` e `test/drift/app_database/generated/` (schema_vN).
5. In `migration` aggiungi il passo `fromXToY` a `stepByStep` (`createTable`, `addColumn`,
   `createIndex`, …; le trasformazioni di dati con `customStatement` nello stesso passo).
6. Di nuovo `build_runner`, poi `dart format lib test`.
7. In `test/drift/app_database/migration_test.dart` aggiungi un test con dati (`testWithDataIntegrity`)
   dalla versione precedente alla nuova: righe esistenti identiche, colonne nuove al valore atteso.
   I test "simple" verificano già lo schema per ogni coppia di versioni.
8. `flutter test test/drift` e tutti gli altri test; aggiorna la sezione Schema e lo storico qui sopra.

Regole: gli schemi salvati in `drift_schemas/` e i passi già rilasciati non si modificano mai (si
aggiunge sempre una versione nuova); `drift_schemas/` e i file generati dei test si committano;
rinominare un valore di un enum salvato come testo richiede una migrazione dei dati.

## Dati iniziali

Al primo avvio, se il database è vuoto:

- Portafogli: "Conto corrente" (checking) e "Contanti" (cash), saldo iniziale 0 alla data di oggi.
  "Conto corrente" è predefinito per spese ed entrate.
- Categorie spesa: Spesa alimentare, Casa, Trasporti, Ristoranti, Svago, Salute, Abbonamenti, Altro.
- Categorie entrata: Stipendio, Freelance, Rimborsi, Regali, Altro.
- Label: nessuna.
- Settings con i valori di default sopra.

## Regole di dominio

- **Saldo di un portafoglio** = `initial_balance_cents`
  \+ entrate confermate nel portafoglio − spese confermate
  − trasferimenti in uscita + trasferimenti in entrata (`to_wallet_id`)
  \+ rettifiche (con segno). Esclusi cancellati e `pending`.
- **Statistiche** (riepiloghi, grafici, confronti): solo `expense` e `income` con `status = confirmed`.
  Trasferimenti e rettifiche **non contano mai** come spese o entrate.
- **Patrimonio totale**: somma dei saldi dei portafogli con `include_in_total` e non archiviati.
- **Ultimo aggiornamento** di un portafoglio = la data più recente tra `initial_balance_date`,
  `last_balance_verified_date` e l'ultima rettifica. Badge "Da aggiornare" se è più vecchia di 30 giorni.
- **Aggiorna saldo**: l'utente inserisce il nuovo saldo e la data; la differenza si registra come
  `adjustment` (default, consigliato per investimenti) oppure come `expense`/`income` con categoria.
  Con differenza zero non si crea nessun movimento. In ogni caso si aggiorna
  `last_balance_verified_date` (mai all'indietro), nella stessa transazione del movimento.
- **Predefiniti**: un solo portafoglio predefinito per le spese e uno per le entrate.
- **Grafico per label**: un movimento con più label conta in ciascuna; le percentuali sono sulla
  somma delle label. I movimenti senza label finiscono in "Senza label".
- **Filtro label**: modalità "almeno una" (default) o "tutte", che vale solo per le label incluse.
- **Inclusioni ed esclusioni nei filtri** (portafogli, categorie, label e "Senza label"): ogni chip
  ha tre stati, neutro → incluso → escluso → neutro (`cycleWallet`, `cycleCategory`, `cycleLabel`,
  `cycleWithoutLabels`; campi `excludedWalletIds`, `excludedCategoryIds`, `excludedLabelIds`,
  `excludeWithoutLabels`). Regole (`matchesFilters`):
  - l'esclusione vince sempre sull'inclusione;
  - **portafoglio escluso**: toglie ogni movimento che lo coinvolge (spese, entrate, rettifiche,
    trasferimenti in origine o in destinazione), anche se l'altro portafoglio del trasferimento è incluso;
  - **categoria esclusa** e **label esclusa**: tolgono i movimenti con quella categoria o con
    **almeno una** label esclusa, a prescindere da "almeno una/tutte"; non nascondono trasferimenti e
    rettifiche (le inclusioni di categorie e label invece sì, perché non hanno categoria né label);
  - **"Senza label"** è una condizione sull'assenza di label, separata dalle label effettive.
    Incluso: aggiunge (in OR) le spese e le entrate senza label alle label incluse, in entrambe le
    modalità ("tutte le label incluse **oppure** nessuna label"); da solo mostra solo quelle senza
    label e, come ogni inclusione, nasconde trasferimenti e rettifiche. Escluso: toglie le spese e le
    entrate senza label (restano solo movimenti con label), non trasferimenti e rettifiche;
  - il **conteggio** dei filtri attivi è per dimensione (tipo, portafogli, categorie, label compreso
    "Senza label", trasferimenti), non per chip: inclusioni ed esclusioni della stessa dimensione
    contano 1;
  - **tutto escluso** (es. tutti i portafogli o tutte le categorie): risultato vuoto ma filtri attivi,
    con badge, chip e stati vuoti che parlano dei filtri ("… con questi filtri"), mai del solo periodo;
  - valgono in Movimenti, ricerca, Grafici e Confronta; il tap su una fetta (`sliceFilters`) mantiene
    tutte le esclusioni del grafico.
- **Filtri di Grafici e Confronta**: ogni tab ha il proprio stato (`activeFiltersProvider` per Movimenti,
  `analyticsFiltersProvider(AnalyticsTab.charts|compare)` per le altre due), indipendente dagli altri.
  In Grafici e Confronta contano solo portafogli, categorie e label (almeno una/tutte): tipo e
  trasferimenti si ignorano (`analyticsScope`). I filtri si applicano prima di ogni calcolo
  (`filterForAnalytics`): torte, totale al centro, barre, linee cumulate e tabella delle variazioni.
- **Ricerca** (Movimenti, `transaction_search.dart`, logica pura): su tutto lo storico (non solo il
  periodo), solo movimenti confermati, con i filtri attivi applicati. Cerca in nota, nome della
  categoria, label e portafogli (anche la destinazione), senza distinzione di maiuscole e accenti
  (`foldForSearch`); con più parole devono esserci tutte. Un numero cerca l'importo: con decimali
  (`64,20`) l'importo esatto, intero (`64`) gli importi da 64,00 a 64,99; il segno non conta.
  Filtro in memoria sui movimenti già caricati: ~25 ms su 10.000 movimenti, quindi niente FTS5 (da
  rivalutare con una tabella FTS e una migrazione se lo storico crescesse di molto).
- **Tap su una fetta** (Grafici): apre Movimenti con il periodo del grafico, il tipo (Spese/Entrate),
  la voce toccata e i filtri del grafico (`sliceFilters`): la voce sostituisce i filtri della sua
  dimensione (una categoria toccata sostituisce le categorie, una label le label, in modalità
  "almeno una"). La lista mostra così gli stessi movimenti della fetta.

## Ricorrenze

- Il **generatore** gira all'avvio e quando l'app torna in primo piano (`AppLifecycleListener`).
- Per ogni regola attiva (non in pausa, non cancellata):
  - `mode = auto` → crea movimenti `confirmed` per le occorrenze fino a oggi incluso.
  - `mode = confirm` → crea movimenti `pending` per le occorrenze fino a oggi + 7 giorni.
- Recupera tutte le occorrenze mancate (app chiusa per settimane).
- Salta le date presenti in `recurrence_exceptions`.
- ID con UUID v5 deterministico; insert che ignora i conflitti sul vincolo unico → idempotente.
- Mensile/annuale con giorno inesistente (31, 29 febbraio) → ultimo giorno del mese.
- Rispetta `end_date` e `max_count`.
- Il calcolo delle occorrenze è una **funzione pura** in `domain/services/` con test dedicati.
- Creare una ricorrenza da "Ripeti" salva la regola e il movimento corrente come prima occorrenza
  (`recurrence_id` + `occurrence_date` = data scelta).
- Modifica "solo questa": si modifica il movimento (`occurrence_date` resta quella originale).
  "Questa e le successive": la regola esistente termina il giorno prima della data **originale**
  dell'occorrenza (o della nuova data, se è precedente) e se ne crea una nuova dalla data scelta nel form,
  con giorno fisso ricavato da quella data e `max_count` ridotto delle occorrenze già passate.
  La nuova data deve venire dopo l'occorrenza precedente (`SplitDateException`), così le regole
  non si sovrappongono. Tutto in una transazione con il salvataggio del movimento (`AtomicWrites`).
- **Storico intoccabile**: dividere una regola non modifica i movimenti successivi già confermati
  (né quelli eliminati o le date saltate). La n-esima occorrenza dopo il confine corrisponde
  alla n-esima della regola nuova, che viene saltata; i soli `pending` successivi si cancellano
  e si rigenerano con i valori nuovi.
- **Arretrati**: se una regola nuova parte nel passato, l'inserimento rapido chiede se registrare
  le occorrenze passate; se no, diventano eccezioni `skip`. Ogni movimento generato ha la data
  dell'occorrenza, mai quella del giorno in cui gira il generatore.
- **Pausa**: `paused_at` ferma il generatore e nasconde i `pending` da "In arrivo". Alla ripresa
  tutte le occorrenze dal giorno della pausa a ieri diventano eccezioni `skip`, comprese quelle già
  generate come `pending` prima della pausa (che si cancellano); i confermati restano. Quelle dal
  giorno della ripresa in poi restano valide. Vale anche dopo un riavvio.
- **Salta**: eccezione `skip` + cancellazione logica del `pending` di quella data.
  **Elimina regola**: regola e `pending` cancellati, i confermati restano.
- Un'occorrenza futura non è mai `confirmed` prima della sua data: sia la prima occorrenza di una
  regola nuova con data futura, sia un'occorrenza modificata prima del tempo (creata con l'ID
  deterministico) restano `pending`, fuori da saldi e statistiche. Per le regole `auto` il generatore
  le conferma quando arriva la data; per quelle `confirm` serve l'utente. (I movimenti non ricorrenti
  con data futura, per ora, restano confermati.)
- **Conferma manuale** solo per i `pending` delle regole `confirm` (`canConfirmManually`). Le occorrenze
  automatiche future compaiono in "In arrivo" come "Automatica · <data>", senza pulsante; la rotta di
  conferma e il form le rifiutano (`AutomaticOccurrenceException`). Le conferma solo il generatore.
- Nel dettaglio, le occorrenze il cui movimento è stato eliminato appaiono come "Eliminata"
  (barrate, senza azioni) e non si rigenerano.
- **Nome e titolo** (`recurrenceTitle`, `initialRuleName` in `domain/services/recurrence.dart`):
  - il titolo (elenco, dettaglio, "In arrivo", banner del movimento) è il nome della regola se c'è,
    altrimenti la descrizione dei movimenti (la nota), altrimenti la categoria, altrimenti
    "Trasferimento" o "Ricorrenza"; nomi e note di soli spazi contano come vuoti;
  - creazione da "Ripeti": in "Data e ripetizione", con una ripetizione scelta, c'è il campo facoltativo
    "Nome della ricorrenza" (`RepeatSettings.name`) con il titolo calcolato come segnaposto. Se resta
    vuoto il nome è la nota (se compilata), altrimenti vuoto e vale il titolo calcolato;
  - "Modifica questa e le successive" ha il campo "Nome della ricorrenza" (parte dal nome attuale,
    segnaposto = titolo calcolato da nota e categoria del form): la regola nuova prende quel nome,
    vuoto = titolo calcolato. Senza modifiche al campo tiene il nome della regola divisa;
  - la matita "Modifica regola" nel dettaglio è una scorciatoia per "Modifica questa e le successive"
    sulla prossima occorrenza non saltata né eliminata (disattivata se la ricorrenza è conclusa).
  - Sottotitolo in elenco: frequenza · categoria · portafoglio (trasferimenti: origine → destinazione),
    poi lo stato con la prossima scadenza.
- **Totali fissi** (Movimenti ricorrenti): l'effettivo del mese (importi registrati o della regola,
  senza saltate e pause) e, se ci sono regole non mensili, la "Media mensile prevista"
  (settimanali × 52 / 12, giornaliere × 365 / 12, annuali / 12, sempre diviso l'intervallo).
- "In arrivo" mostra solo i `pending` fino a oggi + 7 (compresi gli scaduti), non le prossime automatiche.

## Allegati

- File copiati in `<documenti app>/attachments/<transaction_id>/<uuid>.<ext>`.
- Foto: `imageQuality: 75`, `maxWidth/maxHeight: 2048`. PDF via `file_picker`.
- Massimo 5 allegati per movimento. Calcola `sha256` e `size_bytes` al salvataggio.
- La cancellazione logica del movimento non elimina i file (servono per l'annullamento).

Ciclo di vita:

- **Salvataggio**: i file si copiano prima della transazione; se la copia o la scrittura nel
  database fallisce, le copie (anche quelle a metà) si eliminano subito. Nessun file orfano.
- **Rimozione** di un allegato (Modifica movimento): sparisce dal form, al salvataggio il record
  si cancella logicamente con `delete` nell'outbox. Il file resta su disco.
- **Eliminazione del movimento**: solo il movimento è cancellato logicamente; allegati e file
  restano invariati, e "Annulla" li rende di nuovo disponibili.
- **Nessuna cancellazione fisica automatica** dei file di record cancellati logicamente finché non
  esiste la sincronizzazione (serviranno per annullare e per sincronizzare).
- **Orfani** = file senza alcun record in `attachments`, nemmeno cancellato. `OrphanAttachmentCleaner`
  li trova (solo se più vecchi di un giorno, per non toccare salvataggi in corso) ma l'app non
  lo chiama mai da sola per ora.
- **Apertura**: prima si controlla il file (esiste, dimensione e SHA-256): mancante o danneggiato →
  messaggio. Immagini nel visualizzatore a schermo intero (scorrimento, pinch-to-zoom, doppio tocco
  per tornare normale); PDF con un'app esterna (`open_filex`: su Android URI del FileProvider con
  permesso di lettura temporaneo, su iOS Quick Look) oppure "Condividi" (`share_plus`).
- Android: i permessi `READ_EXTERNAL_STORAGE` / `READ_MEDIA_*` dichiarati da `open_filex` sono rimossi
  dal manifest (`tools:node="remove"`): i file sono nella cartella privata e non servono.
- Info.plist: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSFaceIDUsageDescription`
  con testi in italiano.

## Privacy

- Nel selettore delle app non si vedono importi: Android 13+ `setRecentsScreenshotEnabled(false)`,
  prima di Android 13 `FLAG_SECURE` (blocca anche gli screenshot); iOS vista di copertura nativa
  su `UIScene.willDeactivateNotification` in `AppDelegate` (non si sovrascrivono i metodi di
  `FlutterSceneDelegate`); in Flutter un velo in `AppLockGate` quando lo stato non è `resumed`.
- Il velo è indipendente dal blocco con biometria: non cambia né il timer né lo sblocco.
- **Saldi nascosti** (`balancesHiddenProvider`, `features/wallets/application/balance_visibility.dart`):
  l'occhio nell'header di Portafogli ("Nascondi saldi" / "Mostra saldi") nasconde in tutta l'app
  patrimonio totale, totali dei gruppi, saldi dei portafogli, saldo nel dettaglio, saldi nel pannello
  di scelta del portafoglio e nella scheda Da/A dell'inserimento rapido, "Saldo del periodo" nella
  card di Movimenti. Ogni saldo passa da `BalanceText`: nascosto mostra "€ ••••" nello spazio
  dell'importo vero (invisibile, così l'impaginazione non salta) con Semantics "Saldo nascosto".
  Restano **sempre visibili** gli importi dei movimenti e i totali Entrate/Uscite della card.
  - **Dettaglio portafoglio**: il grafico dell'andamento non si mostra (nemmeno la linea), al suo
    posto "Mostra i saldi per visualizzare l'andamento".
  - **Aggiorna saldo**: nessun valore derivato dal saldo registrato. "Saldo registrato: € ••••", campo
    vuoto, differenza "€ ••••", niente "Il saldo coincide". Si registra solo come rettifica:
    "Registra come entrata o spesa" è disattivato, perché la categoria di entrata o di spesa direbbe
    il segno della differenza.
- **Saldi all'apertura** (Impostazioni › Privacy, `balances_on_open` in `app_meta`): sempre visibili
  (predefinito), sempre nascosti, ricorda l'ultima scelta (`balances_hidden`, salvata a ogni tocco
  dell'occhio).
  - Il cambio ha **effetto immediato** (`BalancesHidden.setMode`): "sempre visibili" li mostra,
    "sempre nascosti" li nasconde, "ricorda" conserva lo stato corrente, che diventa l'ultima scelta.
  - Con "sempre nascosti" si nascondono di nuovo quando l'app torna in primo piano dopo almeno 1 minuto
    effettivo in background (`hidden`/`paused`; `inactive` da solo non conta), indipendentemente dal
    blocco con biometria. Gli eventi arrivano da `AppLockGate`, come per il blocco.

## Export e import CSV

Formato unico per export e import (`domain/services/csv_format.dart`), intestazioni esatte:
`data;tipo;importo;valuta;portafoglio;portafoglio_destinazione;categoria;label;nota;id`.
Tipi: spesa | entrata | trasferimento | rettifica. Label separate da `|`.

- **Export**: separatore `;`, UTF-8 con BOM (Excel italiano), date GG/MM/AAAA, importi con virgola
  decimale (positivi, le rettifiche con segno). Rispetta periodo e filtri scelti; condivisione con
  `share_plus`. Un file esportato si reimporta identico.
- **Import** (`csv_import.dart`, logica pura): `planCsvImport` legge il file e restituisce un
  `ImportPlan` (righe valide, errori e avvisi con numero di riga, portafogli/categorie/label da creare,
  righe che aggiornano movimenti esistenti) senza scrivere nulla. Regole:
  - separatore `;` o `,` riconosciuto dalle intestazioni; BOM facoltativo; righe vuote ignorate;
  - data AAAA-MM-GG o GG/MM/AAAA; tipo senza distinzione di maiuscole; importo `1.234,56` o `1234.56`;
  - spesa/entrata con importo negativo → positivo con avviso; rettifica con segno; trasferimento
    negativo o importo zero → errore; valuta vuota = EUR, altre → errore;
  - portafogli, categorie e label abbinati per nome senza distinzione di maiuscole e spazi; le
    categorie per nome **e tipo** (spesa → categorie di spesa, entrata → di entrata). Categoria
    obbligatoria per spesa/entrata; se il nome esiste solo con l'altro tipo, la categoria è
    sconosciuta (da creare o abbinare con il tipo della riga), non un errore. Destinazione obbligatoria
    e diversa per i trasferimenti; i dati che non servono al tipo sono ignorati con un avviso;
  - nomi sconosciuti → da creare (solo dalle righe valide);
  - `id`: UUID esistente → aggiorna; UUID nuovo → si usa; di un movimento eliminato → errore (lapide);
    vuoto → UUID v5 (`importedRowId`, namespace fisso `importNamespace`) della riga normalizzata più un
    contatore per le righe identiche: reimportare lo stesso file aggiorna invece di duplicare.
  - `id` calcolato (riga senza id) di un movimento eliminato, es. dopo un annullamento: si passa
    in modo deterministico a una "generazione" successiva dell'id, così la lapide resta e il file si
    può reimportare (un `id` scritto nel file e cancellato resta invece un errore).
- `csvImportTemplate` genera il modello con intestazioni e 3 righe di esempio.
- **Esecuzione** (`buildImportOperations`, pura, poi `ImportRepository.execute`): un'unica transazione,
  movimenti salvati a blocchi con l'avanzamento; o tutto o niente. Le righe con errori sono saltate,
  mai importate a metà. Portafogli e categorie sconosciuti: "Crea nuovo" (portafoglio di tipo Altro,
  saldo 0 a oggi) o "Abbina a…" uno esistente. Le categorie si scelgono per nome + tipo: "Regali (spesa)" e
"Regali (entrata)" sono due righe distinte e "Abbina a…" propone solo categorie di quel tipo.
Label sconosciute create.
  Opzioni: portafoglio per le righe con la colonna vuota, label aggiuntiva su spese ed entrate.
  I movimenti nuovi hanno `import_batch_id`; quelli aggiornati tengono stato, ricorrenza e il loro
  `import_batch_id`. Una riga che con gli abbinamenti diventa un trasferimento sullo stesso
  portafoglio è scartata.
- **Annulla importazione** (Storico importazioni): cancella logicamente solo i movimenti con quel
  `import_batch_id` e imposta `undone_at`. I movimenti aggiornati non si ripristinano e l'anteprima e
  lo storico lo dicono prima di confermare. Portafogli, categorie e label creati restano. "Duplica"
  di un movimento importato non copia `import_batch_id`.

## Design

Font: **Manrope** (asset locale), cifre tabulari per gli importi.
Formati: locale `it_IT`, importi `€ 1.234,56`, settimana da lunedì.

| Token | Chiaro | Scuro |
| --- | --- | --- |
| background | #F7F7F5 | #111316 |
| surface | #FFFFFF | #1B1E23 |
| surfaceRaised (segmento attivo) | #FFFFFF + ombra | #3A3F48 |
| track (sfondo segmented) | #E9E9E4 | #23272D |
| border | #E4E4DF | #2A2E35 |
| borderStrong | #DCDCD6 | #353A42 |
| divider | #EFEFEA | #262A30 |
| text | #16181D | #EDEEF0 |
| textMuted | #5B5F66 | #A3A8B0 |
| expense (sfondo pieno) | #C2410C | #C2410C |
| expense (testo) | #C2410C | #F28C55 |
| expense (tinta / testo su tinta) | #FCE9DF / #9A3412 | #3A2219 / #F28C55 |
| income (sfondo pieno) | #1D4ED8 | #1D4ED8 |
| income (testo) | #1D4ED8 | #7DA0F7 |
| income (tinta / testo su tinta) | #DCE5FB / #1E3A8A | #1E2A4D / #7DA0F7 |
| neutral (trasferimenti, azioni neutre) | pieno #16181D, tinta #F1F1EE / #3D4148 | pieno #EDEEF0, tinta #23272D / #A3A8B0 |
| danger (testo) | #B4410C | #F28C55 |
| switchTrackOff (interruttore spento) | #C9CBC4 | #4A4F58 |
| switchThumb (pallino interruttore) | #FFFFFF + ombra | #FFFFFF + ombra |
| scrim (velo dietro i pannelli) | #111316 al 45% | #000000 al 60% |
| chartSeries (periodi di Confronta, in ordine) | #1D4ED8, #F08A4B, #0F5F58 | #7DA0F7, #F08A4B, #4FB3A8 |
| gruppo Liquidità | #1D4ED8 / tinta #DCE5FB | tinta #1E2A4D |
| gruppo Risparmi | #0F5F58 / tinta #D5ECE9 | #4FB3A8 / tinta #163A36 |
| gruppo Investimenti | #7C3AED / tinta #EAE2FB | #A78BFA / tinta #2E2448 |

I token vivono in `core/theme/app_colors.dart` (`AppColors`): i widget non usano colori scritti a mano.

- Raggi: card 18–20, campi e pulsanti 12–16, chip 8 (label) o pillola (categorie).
- Spaziatura base 4; margini laterali schermata 20.
- Target tattili minimo 44×44. Contrasto testo ≥ 4.5:1.
- Chip selezionati: categoria = colore del tipo (spesa/entrata); label e filtri = inversione
  (sfondo testo, testo su sfondo).
- Componenti in `core/widgets/`: `AppChip`, `AppSegmented`, `AppSwitch`, `AppListRow`,
  `AppBottomSheet`, `AmountText`, `SectionLabel`, `StateMessage` (stati vuoti ed errori),
  `BottomActionBar`, `TabHeader` (intestazione delle tab), `AppFilterChip` (chip dei filtri a tre
  stati: incluso con ✓ in inversione, escluso con ✕, testo barrato e bordo tratteggiato `danger`;
  Semantics con stato "non filtrato/incluso/escluso" e cosa fa il prossimo tocco).
- **Troncamento**: nei dettagli (Dettaglio ricorrenza, Dettaglio portafoglio, Modifica movimento) nessun
  testo si tronca: nomi e valori vanno a capo, le label stanno in un `Wrap` (nel Dettaglio ricorrenza
  oltre 6 se ne vedono 5 con "Mostra tutte (N)" / "Mostra meno").
  Nelle righe delle liste il troncamento resta (una riga con ellissi) e le label oltre la seconda
  diventano "+N" (`compactLabelTags`). `AppChip` e `AppFilterChip` hanno altezze minime e il testo
  limitato alla larghezza disponibile: un nome più largo della riga va a capo (nelle righe che
  scorrono in orizzontale resta su una riga).
- **Bordo inferiore (edge-to-edge)**: i pulsanti fissati in basso stanno in `BottomActionBar`
  (`Scaffold.bottomNavigationBar`), che aggiunge al proprio padding `bottomSystemInset`: il maggiore tra
  `viewPadding.bottom` (barra a 3 pulsanti, gesti, barra home) e la tastiera aperta (non la somma: la
  tastiera copre la barra). Mai `SafeArea(minimum:)`, che prende il massimo e lascia il pulsante
  attaccato alla barra. I pannelli passano da `AppBottomSheet` (navigator principale, `useSafeArea`,
  stesso spazio in basso, contenuto che scorre col campo attivo visibile). Le liste fuori dalle tab
  con `SafeArea(bottom: false)` aggiungono `bottomSystemInset` al padding finale.
  Verificato da `test/core/bottom_insets_test.dart`.
- **Errori**: un errore di caricamento non si mostra mai come uno stato vuoto. Le schermate principali
  usano `StateMessage.error` ("Non è stato possibile caricare …" + "Riprova"); i dettagli distinguono
  "non esiste più" da "non è stato possibile caricare".
- **Accessibilità** (verificata da `test/accessibility/`): ogni controllo toccabile ha un'etichetta
  (`tooltip`, `semanticLabel` o `Semantics`); target ≥ 44×44 anche quando c'è un bordo; niente altezze
  fisse dove c'è testo (si usa un'altezza minima), così il testo al 130% non va in overflow.
- **Contrasti** (verificati da `test/core/theme/contrast_test.dart`): testo ≥ 4.5:1 in entrambi i temi.
  Eccezione nota: la serie arancio dei grafici nel tema chiaro (#F08A4B) è 2,5:1 su bianco; i valori
  sono comunque scritti in legenda e tabella.
- **Icona e splash**: sorgenti in `assets/icon/` e `assets/splash/`, generate da `tool/generate_icon.py`;
  configurazione in `flutter_launcher_icons.yaml` e `flutter_native_splash.yaml`.

## Navigazione

Tab (StatefulShellRoute): **Movimenti** `/`, **Portafogli** `/wallets`, **Grafici** `/charts`,
**Confronta** `/compare`.

Altre rotte: `/add?type=expense|income|transfer` (modale a schermo intero),
`/transactions/:id`, `/filters`, `/wallets/new`, `/wallets/:id`, `/wallets/:id/edit`,
`/settings`, `/settings/categories`, `/settings/recurring`, `/settings/recurring/:id`,
`/settings/backup`, `/settings/import` (Importa da CSV), `/settings/imports` (Storico importazioni).

## Schermate

**Specifica visiva: la cartella `design/`** nella root del progetto contiene i mockup HTML
delle 14 schermate (tema chiaro) e un `design/README.md` con la mappa file → schermata → rotta.
Prima di implementare o modificare una schermata, **apri il suo file in `design/`** e
riproducine layout, gerarchia, spaziature, testi e stati (pannelli, dialog, stati selezionati)
con widget Flutter e i componenti di `core/widgets/`. Non copiare l'HTML e non usare WebView.
Il tema scuro si ottiene dai token della sezione Design. I dati nei mockup sono solo esempi.
In caso di conflitto tra un mockup e questo file, vale questo file.

Regola comune alle 4 tab (Movimenti, Portafogli, Grafici, Confronta): l'intestazione è `TabHeader`
(`core/widgets/`), con titolo, le azioni della schermata e **sempre ultimo a destra** l'avatar
"Profilo e impostazioni" (44×44, Semantics con quel nome) che apre `/settings`. Le impostazioni sono
quindi raggiungibili da ogni tab. Le azioni attuali: Movimenti cerca e filtri, Portafogli occhio dei saldi e "+",
Grafici e Confronta il pulsante Filtri con il numero di filtri attivi sull'icona. Sotto l'intestazione
di Grafici e Confronta i filtri attivi compaiono come chip rimovibili ("Rimuovi filtro …") con "Azzera"; le esclusioni
come "− Contanti", "− #storico" o "− Senza label" in tinta spesa ("Rimuovi esclusione …"). In Movimenti il chip del
riepilogo dice "Tutti tranne …" se ci sono solo portafogli esclusi.

La schermata **Filtri** è una sola e riceve il contesto dalla rotta (`/filters?scope=charts|compare`,
`FiltersScope`): da Movimenti mostra tutte le sezioni; da Grafici e Confronta nasconde Tipo, Periodo e
"Mostra trasferimenti" e lascia Portafogli, Categorie e Label con almeno una/tutte.

Riepilogo delle schermate:

- **Movimenti**: header con avatar (impostazioni), cerca e filtri. "Cerca" sostituisce l'intestazione
  con un campo (debounce 300 ms, ✕ per cancellare, "Chiudi ricerca" o indietro per uscire): al posto di
  periodo e riepilogo compaiono "N risultati · totale · con N filtri" e i risultati per giorno, oppure
  uno stato vuoto con suggerimento (e "Azzera filtri" se ci sono filtri attivi); selettore
  Giorno/Sett./Mese/Anno/Periodo (default Mese) con frecce; card riepilogo (saldo, entrate,
  uscite, % speso, chip "Tutti i portafogli"); sezione "In arrivo" (pending dei prossimi 7 giorni);
  lista per giorno con totale; pulsanti fissi "− Spesa" e "+ Entrata".
- **Inserimento rapido**: header con chiudi, chip portafoglio ("da"/"su"), chip data con icona
  ripetizione se ricorrente; segmented Spesa/Entrata/Trasferimento; importo grande colorato;
  categorie (pillole) e label (multiple); per il trasferimento scheda Da/A con inverti;
  nota + allegati; tastierino 3×4 (1–9, 00, 0, cancella); pulsante salva colorato per tipo.
- **Modifica movimento**: stessi campi in forma di form scorrevole, duplica in alto,
  elimina + salva in basso (salva disattivo senza modifiche).
- **Filtri**: tipo, periodo con date Dal/Al e preset, portafogli, categorie, label con
  "almeno una/tutte" e "Senza label" (tutti chip a tre stati con `AppFilterChip`, conteggio
  "2 incluse · 1 esclusa"), interruttore trasferimenti; Azzera e Applica.
- **Portafogli**: intestazione con occhio (nascondi/mostra saldi), "+" e avatar; patrimonio totale con barra per gruppi, pulsante trasferisci, liste per gruppo
  con saldo, ultimo aggiornamento e badge.
- **Dettaglio portafoglio**: tipo, saldo, ultimo aggiornamento, "Aggiorna saldo" (pannello con
  nuovo saldo, data, differenza, scelta rettifica/movimento), andamento 6 mesi, movimenti.
- **Nuovo/Modifica portafoglio**: nome, tipo (griglia 3×2), saldo iniziale e data, interruttori
  predefinito spese, predefinito entrate, includi nel patrimonio.
- **Grafici**: intestazione con Filtri e avatar, chip dei filtri attivi; selettore
  Giorno/Sett./Mese/Anno/Periodo come Movimenti (con "Periodo" le date Dal/Al compaiono sotto); Spese/Entrate, Categoria/Label, ciambella con totale al centro, legenda
  con importo, percentuale e barra.
- **Confronta**: intestazione con Filtri e avatar, chip dei filtri attivi; preset, periodi (max 3, con colore), Spese/Entrate/Saldo, Barre/Linee,
  tabella delle variazioni.
- **Impostazioni**: card profilo; Aspetto (tema); Preferenze (valuta, portafogli predefiniti,
  vista predefinita, inizio settimana, movimenti ricorrenti, categorie e label); Notifiche e
  sicurezza (biometria); Privacy (saldi all'apertura); Dati (backup ed esportazione, Importa da CSV, Storico importazioni); Esci / Elimina dati; versione.
- **Categorie e label**: tab, Spese/Entrate, elenco riordinabile, pannello di modifica con
  nome, colore, unisci, archivia.
- **Dettaglio ricorrenza**: card con il badge di stato (Automatico/Da confermare/In pausa/Conclusa) e
  accanto il tipo (Spesa/Entrata/Trasferimento); sotto, categoria e label come chip che vanno a capo:
  la categoria è una pillola con il pallino del suo colore e il nome in grassetto, le label chip grigi
  "#nome" (oltre 6 label: le prime 5 e "Mostra tutte (N)"); poi nome (a capo), importo, ripetizione con
  fine e portafoglio ("da Conto corrente", "da X a Y"), e l'interruttore della pausa.
- **Movimenti ricorrenti** e **Dettaglio ricorrenza** (matita "Modifica regola" = "questa e le successive" sulla prossima occorrenza): totali fissi mensili, Attive/In pausa,
  prossime occorrenze con conferma e menu (salta, modifica solo questa, questa e le successive),
  storico, pausa, elimina.

## Fuori scope per ora (fase 2)

Server Laravel e sincronizzazione, account, upload allegati, backup Google Drive, email
verificata e report automatici, notifiche, multi-valuta, budget, pubblicazione sugli store.
Non implementarli, ma non prendere decisioni che li rendano difficili.
