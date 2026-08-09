import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hymnal_tool/data/app_database.dart';
import 'package:hymnal_tool/data/repositories.dart';
import 'package:hymnal_tool/models/models.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('song repository creates, updates, and deletes local songs', () async {
    final repository = DriftSongRepository(database);
    final now = DateTime.utc(2026, 8, 9);
    final song = Song(
      id: 'local-1',
      title: 'Local Song',
      sections: const [
        SongSection(
          id: 'v1',
          type: SongSectionType.verse,
          label: 'Verse 1',
          lyrics: 'First line',
          order: 0,
        ),
      ],
      rights: const RightsInfo(status: RightsStatus.userProvided),
      createdAt: now,
      updatedAt: now,
    );

    await repository.save(song);
    expect((await repository.getAll()).single.title, 'Local Song');

    await repository.save(song.copyWith(title: 'Updated Song'));
    expect((await repository.getAll()).single.title, 'Updated Song');

    await repository.delete(song.id);
    expect(await repository.getAll(), isEmpty);
  });

  test('setlist order and custom theme bytes persist', () async {
    final setlists = DriftSetlistRepository(database);
    final themes = DriftThemeRepository(database);
    final now = DateTime.utc(2026, 8, 9);
    await setlists.save(
      Setlist(
        id: 'set-1',
        name: 'Sabbath worship',
        songIds: const ['song-b', 'song-a'],
        createdAt: now,
        updatedAt: now,
      ),
    );
    await themes.save(
      PresentationTheme(
        id: 'custom-1',
        name: 'Custom',
        gradientColors: const [0xff000000, 0xff333333],
        backgroundBytes: Uint8List.fromList([1, 2, 3]),
      ),
    );

    expect((await setlists.getAll()).single.songIds, ['song-b', 'song-a']);
    expect((await themes.getAll()).single.backgroundBytes, [1, 2, 3]);
  });
}
