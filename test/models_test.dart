import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hymnal_tool/models/models.dart';

void main() {
  test(
    'song JSON round-trip preserves searchable metadata and section order',
    () {
      final now = DateTime.utc(2026, 8, 9);
      final song = Song(
        id: 'song-1',
        title: 'A Test Hymn',
        author: 'Ada Author',
        topic: 'Faith',
        scriptureReferences: const ['Psalm 23'],
        sections: const [
          SongSection(
            id: 'section-1',
            type: SongSectionType.verse,
            label: 'Verse 1',
            lyrics: 'A quiet line of faith',
            order: 0,
          ),
        ],
        hymnal: const HymnalReference(name: 'Test collection', number: '42'),
        rights: const RightsInfo(status: RightsStatus.userProvided),
        createdAt: now,
        updatedAt: now,
      );

      final decoded = Song.fromJson(jsonDecode(jsonEncode(song.toJson())));
      expect(decoded.title, song.title);
      expect(decoded.sections.single.label, 'Verse 1');
      expect(decoded.searchableText, contains('psalm 23'));
      expect(decoded.searchableText, contains('quiet line'));
      expect(decoded.searchableText, contains('42'));
    },
  );

  test('bundled catalog has 30 validated public-domain entries', () {
    final payload =
        jsonDecode(File('assets/catalog/starter_hymns.json').readAsStringSync())
            as Map<String, dynamic>;
    final songs = (payload['songs'] as List).cast<Map<String, dynamic>>();
    expect(payload['songCount'], 30);
    expect(songs, hasLength(30));
    expect(songs.map((song) => song['id']).toSet(), hasLength(30));
    for (final entry in songs) {
      final song = Song.fromJson(entry);
      expect(song.sections, isNotEmpty, reason: song.title);
      expect(song.rights.status, RightsStatus.publicDomain, reason: song.title);
      expect(song.rights.sourceUrl, isNotEmpty, reason: song.title);
      expect(song.rights.verifiedAt, isNotNull, reason: song.title);
      expect(
        song.sections.map((section) => section.order),
        orderedEquals(List.generate(song.sections.length, (index) => index)),
      );
    }
  });
}
