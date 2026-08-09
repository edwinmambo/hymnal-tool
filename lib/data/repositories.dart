import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:hymnal_tool/data/app_database.dart';
import 'package:hymnal_tool/models/models.dart';

abstract interface class SongRepository {
  Stream<List<Song>> watchAll();
  Future<List<Song>> getAll();
  Future<void> save(Song song);
  Future<void> delete(String id);
  Future<void> seedBundled(List<Song> songs);
}

abstract interface class SetlistRepository {
  Stream<List<Setlist>> watchAll();
  Future<List<Setlist>> getAll();
  Future<void> save(Setlist setlist);
  Future<void> delete(String id);
}

abstract interface class ThemeRepository {
  Stream<List<PresentationTheme>> watchAll();
  Future<List<PresentationTheme>> getAll();
  Future<void> save(PresentationTheme theme);
  Future<void> seedBuiltIns(List<PresentationTheme> themes);
}

mixin _RepositoryUpdates<T> {
  final StreamController<void> _updates = StreamController<void>.broadcast();
  Future<List<T>> readAll();

  Stream<List<T>> watched() async* {
    yield await readAll();
    await for (final _ in _updates.stream) {
      yield await readAll();
    }
  }

  void changed() => _updates.add(null);
}

class DriftSongRepository
    with _RepositoryUpdates<Song>
    implements SongRepository {
  DriftSongRepository(this.database);

  final AppDatabase database;

  @override
  Stream<List<Song>> watchAll() => watched();

  @override
  Future<List<Song>> getAll() async {
    final rows = await database
        .customSelect(
          'SELECT data_json FROM song_records ORDER BY title COLLATE NOCASE',
        )
        .get();
    return rows
        .map(
          (row) => Song.fromJson(
            jsonDecode(row.read<String>('data_json')) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<List<Song>> readAll() => getAll();

  @override
  Future<void> save(Song song) async {
    await database.customStatement(
      '''INSERT INTO song_records
         (id, title, search_text, data_json, is_bundled, updated_at)
         VALUES (?, ?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
           title = excluded.title,
           search_text = excluded.search_text,
           data_json = excluded.data_json,
           is_bundled = excluded.is_bundled,
           updated_at = excluded.updated_at''',
      [
        song.id,
        song.title,
        song.searchableText,
        jsonEncode(song.toJson()),
        song.isBundled ? 1 : 0,
        song.updatedAt.millisecondsSinceEpoch,
      ],
    );
    changed();
  }

  @override
  Future<void> delete(String id) async {
    await database.customStatement('DELETE FROM song_records WHERE id = ?', [
      id,
    ]);
    changed();
  }

  @override
  Future<void> seedBundled(List<Song> songs) async {
    await database.transaction(() async {
      for (final song in songs) {
        await database.customStatement(
          '''INSERT INTO song_records
             (id, title, search_text, data_json, is_bundled, updated_at)
             VALUES (?, ?, ?, ?, 1, ?)
             ON CONFLICT(id) DO UPDATE SET
               title = excluded.title,
               search_text = excluded.search_text,
               data_json = excluded.data_json,
               is_bundled = 1,
               updated_at = excluded.updated_at''',
          [
            song.id,
            song.title,
            song.searchableText,
            jsonEncode(song.copyWith(isBundled: true).toJson()),
            song.updatedAt.millisecondsSinceEpoch,
          ],
        );
      }
    });
    changed();
  }
}

class DriftSetlistRepository
    with _RepositoryUpdates<Setlist>
    implements SetlistRepository {
  DriftSetlistRepository(this.database);

  final AppDatabase database;

  @override
  Stream<List<Setlist>> watchAll() => watched();

  @override
  Future<List<Setlist>> getAll() async {
    final rows = await database
        .customSelect(
          'SELECT data_json FROM setlist_records ORDER BY updated_at DESC',
        )
        .get();
    return rows
        .map(
          (row) => Setlist.fromJson(
            jsonDecode(row.read<String>('data_json')) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<List<Setlist>> readAll() => getAll();

  @override
  Future<void> save(Setlist setlist) async {
    await database.customStatement(
      '''INSERT INTO setlist_records (id, name, data_json, updated_at)
         VALUES (?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
           name = excluded.name,
           data_json = excluded.data_json,
           updated_at = excluded.updated_at''',
      [
        setlist.id,
        setlist.name,
        jsonEncode(setlist.toJson()),
        setlist.updatedAt.millisecondsSinceEpoch,
      ],
    );
    changed();
  }

  @override
  Future<void> delete(String id) async {
    await database.customStatement('DELETE FROM setlist_records WHERE id = ?', [
      id,
    ]);
    changed();
  }
}

class DriftThemeRepository
    with _RepositoryUpdates<PresentationTheme>
    implements ThemeRepository {
  DriftThemeRepository(this.database);

  final AppDatabase database;

  @override
  Stream<List<PresentationTheme>> watchAll() => watched();

  @override
  Future<List<PresentationTheme>> getAll() async {
    final rows = await database
        .customSelect(
          'SELECT data_json, background_bytes FROM theme_records '
          'ORDER BY is_built_in DESC, name COLLATE NOCASE',
        )
        .get();
    return rows
        .map(
          (row) => PresentationTheme.fromJson(
            jsonDecode(row.read<String>('data_json')) as Map<String, dynamic>,
            backgroundBytes: row.readNullable<Uint8List>('background_bytes'),
          ),
        )
        .toList();
  }

  @override
  Future<List<PresentationTheme>> readAll() => getAll();

  @override
  Future<void> save(PresentationTheme theme) async {
    await database.customStatement(
      '''INSERT INTO theme_records
         (id, name, data_json, background_bytes, is_built_in)
         VALUES (?, ?, ?, ?, ?)
         ON CONFLICT(id) DO UPDATE SET
           name = excluded.name,
           data_json = excluded.data_json,
           background_bytes = excluded.background_bytes,
           is_built_in = excluded.is_built_in''',
      [
        theme.id,
        theme.name,
        jsonEncode(theme.toJson()),
        theme.backgroundBytes,
        theme.isBuiltIn ? 1 : 0,
      ],
    );
    changed();
  }

  @override
  Future<void> seedBuiltIns(List<PresentationTheme> themes) async {
    await database.transaction(() async {
      for (final theme in themes) {
        await database.customStatement(
          '''INSERT OR IGNORE INTO theme_records
             (id, name, data_json, background_bytes, is_built_in)
             VALUES (?, ?, ?, NULL, 1)''',
          [theme.id, theme.name, jsonEncode(theme.toJson())],
        );
      }
    });
    changed();
  }
}
