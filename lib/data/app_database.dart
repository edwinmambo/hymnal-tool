import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Drift-backed database with a deliberately small runtime schema.
///
/// Domain objects are versionable JSON documents, while title/search columns
/// remain available for indexing. This avoids coupling the public models to
/// generated row classes and keeps native and web storage identical.
class AppDatabase extends GeneratedDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'hymnal_tool',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo> get allTables => const [];

  @override
  Iterable<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      await customStatement('''
            CREATE TABLE song_records (
              id TEXT NOT NULL PRIMARY KEY,
              title TEXT NOT NULL,
              search_text TEXT NOT NULL,
              data_json TEXT NOT NULL,
              is_bundled INTEGER NOT NULL DEFAULT 0,
              updated_at INTEGER NOT NULL
            )
          ''');
      await customStatement(
        'CREATE INDEX song_search_index ON song_records(search_text)',
      );
      await customStatement('''
            CREATE TABLE setlist_records (
              id TEXT NOT NULL PRIMARY KEY,
              name TEXT NOT NULL,
              data_json TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
      await customStatement('''
            CREATE TABLE theme_records (
              id TEXT NOT NULL PRIMARY KEY,
              name TEXT NOT NULL,
              data_json TEXT NOT NULL,
              background_bytes BLOB,
              is_built_in INTEGER NOT NULL DEFAULT 0
            )
          ''');
      await customStatement('''
            CREATE TABLE setting_records (
              key TEXT NOT NULL PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
    },
  );
}
