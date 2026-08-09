import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hymnal_tool/app_state.dart';
import 'package:hymnal_tool/data/app_database.dart';
import 'package:hymnal_tool/data/repositories.dart';
import 'package:hymnal_tool/main.dart';
import 'package:hymnal_tool/models/models.dart';
import 'package:hymnal_tool/screens/studio_screen.dart';

void main() {
  late AppDatabase database;
  late HymnalAppState state;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    state = HymnalAppState(
      songRepository: DriftSongRepository(database),
      setlistRepository: DriftSetlistRepository(database),
      themeRepository: DriftThemeRepository(database),
    );
  });

  tearDown(() async {
    state.dispose();
    await database.close();
  });

  test('numeric search prioritizes hymn numbers over lyric matches', () {
    state.songs = [
      _song(id: 'noise', number: '8', lyrics: 'There are 42 reasons'),
      _song(id: 'prefix', number: '420'),
      _song(id: 'exact', number: '042'),
    ];

    state.setSearch('#42');

    expect(state.filteredSongs.map((song) => song.id), ['exact', 'prefix']);
  });

  test('bundled public-domain hymns are searchable by SDAH number', () async {
    await state.initialize();
    await pumpEventQueue();

    state.setSearch('108');

    expect(state.filteredSongs.single.title, 'Amazing Grace');
    expect(state.filteredSongs.single.hymnal.number, '108');
  });

  test('JSON catalog import persists hymns for offline use', () async {
    final source = jsonEncode({
      'version': 'test-1',
      'songs': [_song(id: 'imported', number: '108').toJson()],
    });

    final count = await state.importCatalogText(
      source,
      origin: 'https://example.org/sdah.json',
    );

    expect(count, 1);
    final saved = (await state.songRepository.getAll()).single;
    expect(saved.id, 'imported');
    expect(saved.isBundled, isFalse);
    expect(saved.hymnal.number, '108');
    expect(saved.hymnal.sourceUrl, 'https://example.org/sdah.json');
  });

  test('catalog import rejects hymns without rights metadata', () async {
    final song = _song(
      id: 'unknown-rights',
    ).copyWith(rights: const RightsInfo(status: RightsStatus.unknown));

    expect(
      () => state.importCatalogText(
        jsonEncode({
          'songs': [song.toJson()],
        }),
      ),
      throwsFormatException,
    );
  });

  testWidgets('theme picker changes the active presentation theme', (
    tester,
  ) async {
    state.themes = defaultThemes;
    await tester.pumpWidget(
      HymnalScope(
        notifier: state,
        child: const MaterialApp(home: Scaffold(body: ThemesView())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Olive grove'));
    await tester.pumpAndSettle();

    expect(state.selectedThemeId, 'theme-olive');
    expect(state.selectedTheme.name, 'Olive grove');
  });
}

Song _song({
  required String id,
  String number = '',
  String lyrics = 'A hymn line',
}) {
  final now = DateTime.utc(2026, 8, 9);
  return Song(
    id: id,
    title: 'Hymn $id',
    sections: [
      SongSection(
        id: '$id-v1',
        type: SongSectionType.verse,
        label: 'Verse 1',
        lyrics: lyrics,
        order: 0,
      ),
    ],
    hymnal: HymnalReference(
      name: 'SDAH Extended',
      edition: '1985',
      number: number,
    ),
    rights: const RightsInfo(status: RightsStatus.userProvided),
    createdAt: now,
    updatedAt: now,
  );
}
