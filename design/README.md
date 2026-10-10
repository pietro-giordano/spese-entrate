# Design di riferimento

Mockup delle 14 schermate (tema chiaro), esportati dal canvas di design.
Sono la **specifica visiva** dell'app: layout, spaziature, testi, colori, stati.

- Non sono pagine eseguibili da sole: leggile come sorgente (markup + stili inline +
  piccolo script con i dati di esempio e gli stati interattivi in `renderVals`).
- Non vanno convertite in HTML/WebView: vanno ricreate con widget Flutter
  usando i componenti di `core/widgets/` e i token del tema.
- Il tema scuro non ha file propri: si ottiene dai token della tabella "Design" in CLAUDE.md.
- I dati (importi, nomi, date) sono esempi, non dati iniziali.
- Le dimensioni di riferimento sono 390×844 pt (iPhone standard).

| File | Schermata | Rotta |
| --- | --- | --- |
| 01-movimenti.html | Movimenti (home, vista mensile) | `/` |
| 02-inserimento-rapido.html | Inserimento rapido (+ pannelli data/ripeti, allegati, portafoglio) | `/add` |
| 03-filtri.html | Filtri | `/filters` |
| 04-grafici.html | Grafici a torta | `/charts` |
| 05-confronta.html | Confronto periodi | `/compare` |
| 06-categorie-label.html | Categorie e label (+ pannello modifica) | `/settings/categories` |
| 07-impostazioni.html | Profilo e impostazioni | `/settings` |
| 08-modifica-movimento.html | Modifica movimento (+ dialog elimina) | `/transactions/:id` |
| 09-backup-export.html | Backup ed esportazione (**fase 2**, tranne export CSV) | `/settings/backup` |
| 10-portafogli.html | Portafogli | `/wallets` |
| 11-dettaglio-portafoglio.html | Dettaglio portafoglio (+ pannello Aggiorna saldo) | `/wallets/:id` |
| 12-nuovo-portafoglio.html | Nuovo/Modifica portafoglio | `/wallets/new` |
| 13-ricorrenti.html | Movimenti ricorrenti | `/settings/recurring` |
| 14-dettaglio-ricorrenza.html | Dettaglio ricorrenza (+ pannello occorrenza, dialog elimina) | `/settings/recurring/:id` |
