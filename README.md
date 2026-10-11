# Spese & Entrate

App Flutter (iOS e Android) per registrare spese, entrate, trasferimenti e portafogli personali.
Funziona offline e senza account: i dati restano sul telefono, in un database SQLite (Drift),
già predisposto per una futura sincronizzazione.

- Regole del progetto, architettura, schema e design: [CLAUDE.md](CLAUDE.md)
- Mockup delle schermate: [design/](design/README.md)

## Requisiti

- Flutter stable 3.47 o successivo (Dart 3.13)
- Android: Android Studio o SDK con un emulatore o un telefono collegato
- iOS (solo su macOS): Xcode e CocoaPods (`brew install cocoapods`)

```sh
flutter doctor        # controlla che tutto sia installato
flutter pub get       # scarica i pacchetti
```

## Avviare l'app

```sh
flutter devices                 # dispositivi ed emulatori disponibili
flutter run                     # avvia sul dispositivo scelto (r = ricarica, R = riavvia)
flutter run -d <id-dispositivo> # su un dispositivo preciso
```

## Codice generato

Riverpod, Drift e Freezed generano file `*.g.dart` e `*.freezed.dart`.
Dopo aver toccato una classe con annotazioni (`@riverpod`, `@freezed`, tabelle Drift):

```sh
dart run build_runner build --delete-conflicting-outputs   # una volta
dart run build_runner watch --delete-conflicting-outputs   # a ogni salvataggio
```

## Controlli

```sh
dart format lib test            # formattazione
flutter analyze                 # nessun errore né warning
flutter test                    # tutti i test
flutter test test/domain        # solo la logica di dominio
flutter test test/accessibility # etichette, target tattili, temi e testo al 130%
flutter test --coverage         # copertura in coverage/lcov.info
```

## Database e migrazioni

Lo schema è in `lib/data/db/`. Quando cambia, si alza `schemaVersion` in `AppDatabase`, si scrive
la migrazione e si salva lo schema della nuova versione:

```sh
dart run drift_dev make-migrations   # salva drift_schemas/ e genera i test in test/drift/
```

## Icona e splash

Le immagini sorgente sono in `assets/icon/` e `assets/splash/`; i colori sono i token del tema.

```sh
python3 tool/generate_icon.py "$PWD"        # rigenera le immagini (serve Pillow: pip install pillow)
dart run flutter_launcher_icons             # icone Android e iOS (flutter_launcher_icons.yaml)
dart run flutter_native_splash:create       # splash chiaro e scuro (flutter_native_splash.yaml)
```

## Build

```sh
flutter build apk --debug                   # APK di prova
flutter build apk --release                 # APK firmato (serve la configurazione di firma)
flutter build appbundle                     # pacchetto per il Play Store
flutter build ios --debug --no-codesign     # verifica la compilazione iOS senza firma
flutter build ipa                           # archivio per l'App Store (serve un account Apple)
```

## Struttura

```
lib/
  core/       # date, importi, ID, tema, router, componenti riusabili
  domain/     # modelli, interfacce dei repository, logica pura (saldi, statistiche, ricorrenze)
  data/       # database Drift, repository, file e servizi di sistema
  features/   # schermate e stato per area (movimenti, portafogli, grafici, ricorrenze, impostazioni)
test/         # stessa struttura di lib/, più accessibility/ e drift/ (migrazioni)
tool/         # script di supporto (icona)
```
