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
- File e media: `image_picker`, `file_picker`, `path_provider`, `path`.
- Sistema: `local_auth`, `share_plus`.
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

## Schema

Colonne in snake_case. "Comuni" = `id TEXT PK, created_at INT, updated_at INT, deleted_at INT NULL, device_id TEXT`.

**wallets** — comuni +
`name TEXT`, `type TEXT` (cash | checking | card | savings | investment | other),
`currency TEXT DEFAULT 'EUR'`, `initial_balance_cents INT`, `initial_balance_date TEXT`,
`include_in_total BOOL DEFAULT true`, `sort_order INT`, `archived_at INT NULL`,
`last_balance_verified_date TEXT NULL` (data dell'ultima verifica con "Aggiorna saldo", dalla versione 2 dello schema).

**categories** — comuni +
`name TEXT`, `kind TEXT` (expense | income), `color INT`, `sort_order INT`, `archived_at INT NULL`.

**labels** — comuni + `name TEXT`, `color INT`.
Nome unico tra le label non cancellate (controllo nel repository).

**transactions** — comuni +
`type TEXT` (expense | income | transfer | adjustment),
`status TEXT DEFAULT 'confirmed'` (confirmed | pending),
`amount_cents INT` (sempre > 0, tranne `adjustment` che ha segno),
`currency TEXT`, `date TEXT`, `wallet_id TEXT` (origine per i trasferimenti),
`to_wallet_id TEXT NULL` (solo transfer), `category_id TEXT NULL` (obbligatoria per expense/income),
`note TEXT NULL`, `recurrence_id TEXT NULL`, `occurrence_date TEXT NULL`.
Indici: `date`, `wallet_id`, `category_id`. Vincolo unico: `(recurrence_id, occurrence_date)`.

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

**settings** (sincronizzabile) — comuni + `key TEXT UNIQUE`, `value TEXT`.
Chiavi: `default_expense_wallet_id`, `default_income_wallet_id`, `week_start` (1 = lunedì),
`default_period` (month), `currency` (EUR).

**app_meta** (solo locale, non sincronizzata) — `key TEXT PK`, `value TEXT`.
Chiavi: `device_id`, `theme_mode` (system | light | dark), `biometric_lock` (bool),
`profile_name`, `profile_email`.

**outbox** (solo locale) — `id INT PK AUTOINCREMENT`, `entity TEXT`, `entity_id TEXT`,
`op TEXT` (upsert | delete), `changed_at INT`.

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
- **Filtro label**: modalità "almeno una" (default) o "tutte".

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
- Modifica "solo questa": si modifica il movimento. "Questa e le successive": la regola esistente
  termina il giorno prima e se ne crea una nuova dalla data dell'occorrenza.

## Allegati

- File copiati in `<documenti app>/attachments/<transaction_id>/<uuid>.<ext>`.
- Foto: `imageQuality: 75`, `maxWidth/maxHeight: 2048`. PDF via `file_picker`.
- Massimo 5 allegati per movimento. Calcola `sha256` e `size_bytes` al salvataggio.
- La cancellazione logica del movimento non elimina i file (servono per l'annullamento).
- Info.plist: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSFaceIDUsageDescription`
  con testi in italiano.

## Export

- CSV con separatore `;`, UTF-8 con BOM (Excel italiano), importi con virgola decimale.
- Colonne: data, tipo, importo, valuta, portafoglio, portafoglio destinazione, categoria, label
  (separate da `|`), nota, id.
- Rispetta periodo e filtri scelti; condivisione tramite `share_plus`.

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
  `AppBottomSheet`, `AmountText`, `SectionLabel`.

## Navigazione

Tab (StatefulShellRoute): **Movimenti** `/`, **Portafogli** `/wallets`, **Grafici** `/charts`,
**Confronta** `/compare`.

Altre rotte: `/add?type=expense|income|transfer` (modale a schermo intero),
`/transactions/:id`, `/filters`, `/wallets/new`, `/wallets/:id`, `/wallets/:id/edit`,
`/settings`, `/settings/categories`, `/settings/recurring`, `/settings/recurring/:id`,
`/settings/backup`.

## Schermate

**Specifica visiva: la cartella `design/`** nella root del progetto contiene i mockup HTML
delle 14 schermate (tema chiaro) e un `design/README.md` con la mappa file → schermata → rotta.
Prima di implementare o modificare una schermata, **apri il suo file in `design/`** e
riproducine layout, gerarchia, spaziature, testi e stati (pannelli, dialog, stati selezionati)
con widget Flutter e i componenti di `core/widgets/`. Non copiare l'HTML e non usare WebView.
Il tema scuro si ottiene dai token della sezione Design. I dati nei mockup sono solo esempi.
In caso di conflitto tra un mockup e questo file, vale questo file.

Riepilogo delle schermate:

- **Movimenti**: header con avatar (impostazioni), cerca e filtri; selettore
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
  "almeno una/tutte", interruttore trasferimenti; Azzera e Applica.
- **Portafogli**: patrimonio totale con barra per gruppi, pulsante trasferisci, liste per gruppo
  con saldo, ultimo aggiornamento e badge.
- **Dettaglio portafoglio**: tipo, saldo, ultimo aggiornamento, "Aggiorna saldo" (pannello con
  nuovo saldo, data, differenza, scelta rettifica/movimento), andamento 6 mesi, movimenti.
- **Nuovo/Modifica portafoglio**: nome, tipo (griglia 3×2), saldo iniziale e data, interruttori
  predefinito spese, predefinito entrate, includi nel patrimonio.
- **Grafici**: periodo, Spese/Entrate, Categoria/Label, ciambella con totale al centro, legenda
  con importo, percentuale e barra.
- **Confronta**: preset, periodi (max 3, con colore), Spese/Entrate/Saldo, Barre/Linee,
  tabella delle variazioni.
- **Impostazioni**: card profilo; Aspetto (tema); Preferenze (valuta, portafogli predefiniti,
  vista predefinita, inizio settimana, movimenti ricorrenti, categorie e label); Notifiche e
  sicurezza (biometria); Dati (backup ed esportazione); Esci / Elimina dati; versione.
- **Categorie e label**: tab, Spese/Entrate, elenco riordinabile, pannello di modifica con
  nome, colore, unisci, archivia.
- **Movimenti ricorrenti** e **Dettaglio ricorrenza**: totali fissi mensili, Attive/In pausa,
  prossime occorrenze con conferma e menu (salta, modifica solo questa, questa e le successive),
  storico, pausa, elimina.

## Fuori scope per ora (fase 2)

Server Laravel e sincronizzazione, account, upload allegati, backup Google Drive, email
verificata e report automatici, notifiche, multi-valuta, budget, pubblicazione sugli store.
Non implementarli, ma non prendere decisioni che li rendano difficili.
