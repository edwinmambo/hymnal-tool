# Hymnal Tool

[![Flutter CI](https://github.com/edwinmambo/hymnal-tool/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/edwinmambo/hymnal-tool/actions/workflows/flutter_ci.yml)

An offline-first Flutter lyrics presenter for Android, web, Windows, and macOS.

Hymnal Tool gives worship teams a focused operator studio for finding songs,
building setlists, and presenting readable lyrics without requiring an internet
connection during a service.

## What is included

- A searchable library seeded with 30 public-domain hymns.
- Exact and prefix hymn-number search (for example `108` or `#108`).
- JSON hymnal import from a local file or an HTTP(S) catalog, persisted offline.
- Structured song creation with paste-to-sections support.
- Hymn metadata, scripture references, source, and rights records.
- Reusable drag-and-drop setlists.
- Full-screen presentation with keyboard, touch, blank-screen, and text-size controls.
- Curated warm themes and locally stored custom background images.
- Drift/SQLite persistence on native platforms and Drift/WASM browser storage on web.

The bundled catalog is not an official SDA hymnal. Each included entry carries its
Open Hymnal source and public-domain notice. The catalog build deliberately rejects
entries without explicit rights and verification metadata.

## Importing SDAH Extended or another hymnal

Open **Library > Get more hymns** (the cloud-download button). You can choose a
JSON file or enter an HTTP(S) URL. The app accepts either a JSON object with a
`songs` array or a plain array of song objects using the same schema as
`assets/catalog/starter_hymns.json`. Imported hymns are saved in the local Drift
database and work offline.

The importer supports up to 2,500 hymns per catalog and requires every entry to
declare `publicDomain`, `licensed`, or `userProvided` rights. A complete licensed
SDAH Extended catalog can therefore be loaded without changing the app. Copyrighted
SDAH lyrics are intentionally not copied into this repository.

## Run locally

```sh
flutter pub get
flutter run -d chrome
flutter run -d android
```

Windows builds require Visual Studio's **Desktop development with C++** workload.
macOS builds must be produced on macOS.

## Project structure

- `lib/` contains the Flutter application and persistence layer.
- `assets/catalog/` contains the versioned starter catalog and rights metadata.
- `tool/` contains catalog validation and generation tooling.
- `test/` covers models, repositories, application state, and presentation flows.

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build web --release
```

To regenerate the checked-in catalog, download the Open Hymnal 2014.06 ThML source
to `.dart_tool/catalog_source/openhymnal.xml`, then run:

```sh
dart run tool/build_catalog.dart
```

## Rights and permitted content

The application code and the rights to individual hymn texts are separate concerns.
The bundled catalog includes only entries recorded as public domain with a source
and verification date. Do not submit copyrighted lyrics unless their license permits
redistribution in this repository. Users remain responsible for songs they import
or create locally.

This is an independent project and is not an official Seventh-day Adventist product.

## Contributing

Bug reports and focused feature proposals are welcome through GitHub Issues. Before
opening a pull request, run the verification commands above and read
[`CONTRIBUTING.md`](CONTRIBUTING.md).

## Status

The project is under active development. The current milestone focuses on a reliable
single-display, offline presentation workflow; Bible text, synchronized libraries,
and dedicated second-screen control are planned for later iterations.
