# Release Android — Finanze

- Nome visualizzato: **Finanze**
- applicationId / namespace Android: `io.github.pietrogiordano.finanze`
- Bundle ID iOS: `io.github.pietrogiordano.finanze`
- Versione: campo `version` in `pubspec.yaml` (`nome+build`, es. `1.0.0+1`).
  Il numero dopo `+` è il `versionCode` Android: deve **sempre crescere**, altrimenti
  Android rifiuta l'aggiornamento.

## Chiave di firma

| Cosa | Dove |
| --- | --- |
| Keystore | `/Users/pietrogiordano/keys/spese-release.jks` (alias `spese`) |
| Configurazione | `android/key.properties` (non nel repository) |
| Password | in `android/key.properties` su questo Mac; copia di sicurezza: _(da indicare, es. gestore di password)_ |

`android/key.properties`:

```properties
storePassword=…
keyPassword=…
keyAlias=spese
storeFile=/Users/pietrogiordano/keys/spese-release.jks
```

`key.properties`, `*.jks` e `*.keystore` sono in `.gitignore`: non vanno mai committati.
**Fai una copia di sicurezza del keystore e delle password** (fuori da questo Mac):
se la chiave si perde, l'app installata non si può più aggiornare, solo disinstallare
(perdendo i dati) e reinstallare.

## Build

```sh
flutter clean            # facoltativo, se qualcosa sembra in cache
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`.

La build release ha R8 attivo (`isMinifyEnabled`, `isShrinkResources`); regole aggiuntive in
`android/app/proguard-rules.pro`. Se dopo un aggiornamento dei pacchetti un plugin si rompe solo
in release (crash all'avvio, biometria, foto, PDF, condivisione), aggiungi lì le regole `-keep`
del plugin.

Per un APK più piccolo per una sola architettura (telefoni recenti):

```sh
flutter build apk --release --split-per-abi   # usa app-arm64-v8a-release.apk
```

## Installazione

### Via adb (telefono collegato con debug USB attivo)

```sh
adb devices                                                  # il telefono deve comparire
adb install -r build/app/outputs/flutter-apk/app-release.apk  # -r = installa sopra, tiene i dati
```

### Via file

1. Copia `app-release.apk` sul telefono (cavo, Google Drive, email a te stesso…).
2. Aprilo dal gestore file; alla prima volta Android chiede di consentire
   "Installa app sconosciute" per l'app da cui lo apri.
3. Conferma "Installa" (o "Aggiorna" se l'app c'è già).

## Aggiornamento di una versione già installata

I dati restano sul telefono solo se l'APK nuovo è firmato **con la stessa chiave** e ha un
numero di build più alto.

1. **Numero di build**: in `pubspec.yaml` aumenta il numero dopo `+` (es. `1.0.0+1` → `1.0.1+2`).
   Aumenta anche il nome se cambia qualcosa di visibile.
2. **Test di migrazione**: se lo schema del database è cambiato, segui la procedura
   "Migrazioni dello schema" in `CLAUDE.md`, poi:
   ```sh
   flutter test test/drift
   flutter test
   ```
3. **Backup nell'app**: sul telefono, Impostazioni → Backup ed esportazione → periodo che copre
   tutto → "Esporta", e salva il CSV fuori dal telefono. Il CSV contiene i movimenti confermati
   (non allegati né regole ricorrenti) e si può reimportare con "Importa da CSV".
4. **Build**: `flutter build apk --release`.
5. **Installa sopra**: `adb install -r …` oppure apri il file sul telefono → "Aggiorna".
   Non disinstallare prima: disinstallare cancella il database.
6. Apri l'app e controlla saldi, movimenti e la versione in fondo alle Impostazioni.
