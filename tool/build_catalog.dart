// Builds the app's words-only starter catalog from the Open Hymnal 2014.06
// ThML release. Run after downloading the source to:
// .dart_tool/catalog_source/openhymnal.xml
import 'dart:convert';
import 'dart:io';

const sourceUrl = 'http://openhymnal.org/openhymnal.201406.xml';
const selectedTitles = [
  'A Mighty Fortress Is Our God',
  'Abide With Me',
  'All Creatures of Our God and King',
  "All Hail The Power Of Jesus' Name",
  'Amazing Grace',
  'And Can It Be',
  'Be Thou My Vision',
  'Blessed Assurance',
  'Come Thou Fount Of Every Blessing',
  'Crown Him With Many Crowns',
  'For The Beauty Of The Earth',
  'Holy, Holy, Holy',
  'How Firm A Foundation',
  'I Need Thee Every Hour',
  'Immortal, Invisible, God Only Wise',
  'It Is Well With My Soul(When Peace Like a River)',
  'Joyful, Joyful, We Adore Thee',
  'My Hope Is Built (also known as The Solid Rock)',
  'Nearer, My God, To Thee',
  'Jesus Shall Reign',
  'Pass Me Not, O Gentle Savior',
  'Praise To The Lord, The Almighty',
  'Rock of Ages',
  'Take My Life And Let It Be',
  'What A Friend We Have In Jesus',
  'When I Survey the Wondrous Cross',
  'Guide Me, O Thou Great Jehovah',
  'O For A Thousand Tongues',
  'Savior, Like A Shepherd Lead Us',
  'Beautiful Savior (also known as Fairest Lord Jesus)',
];

void main() {
  final input = File('.dart_tool/catalog_source/openhymnal.xml');
  if (!input.existsSync()) {
    stderr.writeln('Missing ${input.path}');
    exitCode = 1;
    return;
  }
  final source = input.readAsStringSync();
  final blocks = <String, String>{};
  final blockPattern = RegExp(
    r'<div3[^>]*>\s*<h3>(.*?)</h3>(.*?)</div3>',
    dotAll: true,
  );
  for (final match in blockPattern.allMatches(source)) {
    final title = _text(match.group(1)!);
    blocks.putIfAbsent(title, () => match.group(2)!);
  }

  final now = DateTime.utc(2026, 8, 9).toIso8601String();
  final songs = <Map<String, Object?>>[];
  for (var songIndex = 0; songIndex < selectedTitles.length; songIndex++) {
    final expectedTitle = selectedTitles[songIndex];
    final block = blocks[expectedTitle];
    if (block == null) {
      throw StateError('Missing selected hymn: $expectedTitle');
    }
    final metadataMatch = RegExp(
      r'<p>\s*<i>(.*?)</i>\s*</p>',
      dotAll: true,
    ).firstMatch(block);
    if (metadataMatch == null) {
      throw StateError('No rights data: $expectedTitle');
    }
    final metadata = _text(metadataMatch.group(1)!);
    if (!metadata.toLowerCase().contains('copyright: public domain')) {
      throw StateError('Not explicitly public domain: $expectedTitle');
    }

    final lyricArea = block.substring(0, metadataMatch.start);
    final stanzaMatches = RegExp(
      r'<p>\s*(\d+)\.\s*(.*?)\s*</p>',
      dotAll: true,
    ).allMatches(lyricArea).toList();
    if (stanzaMatches.isEmpty) throw StateError('No verses: $expectedTitle');

    final displayTitle = expectedTitle
        .replaceAll(RegExp(r'\s*\(also known as.*?\)$'), '')
        .replaceAll(RegExp(r'\s*\(When Peace Like a River\)$'), '')
        .trim();
    final author =
        RegExp(
          r'Words:\s*(.*?)(?:Music:|Setting:|copyright:)',
          caseSensitive: false,
        ).firstMatch(metadata)?.group(1)?.trim() ??
        '';
    final music =
        RegExp(
          r'Music:\s*(.*?)(?:Setting:|copyright:)',
          caseSensitive: false,
        ).firstMatch(metadata)?.group(1)?.trim() ??
        '';
    final tune = RegExp("['‘](.*?)['’]").firstMatch(music)?.group(1) ?? '';
    final scriptures = RegExp(r'<scripRef[^>]*>(.*?)</scripRef>', dotAll: true)
        .allMatches(block)
        .map((match) => _text(match.group(1)!))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    songs.add({
      'id': 'open-hymnal-${(songIndex + 1).toString().padLeft(3, '0')}',
      'title': displayTitle,
      'alternateTitle': expectedTitle == displayTitle ? '' : expectedTitle,
      'author': author,
      'composer': music,
      'tune': tune,
      'meter': '',
      'topic': 'Classic hymn',
      'scriptureReferences': scriptures,
      'sections': [
        for (var index = 0; index < stanzaMatches.length; index++)
          {
            'id':
                'open-hymnal-${(songIndex + 1).toString().padLeft(3, '0')}-v${index + 1}',
            'type': 'verse',
            'label': 'Verse ${index + 1}',
            'lyrics': _text(stanzaMatches[index].group(2)!),
            'order': index,
          },
      ],
      'hymnal': {
        'name': 'Open Hymnal Project',
        'edition': '2014.06',
        'number': '',
        'sourceUrl': sourceUrl,
      },
      'rights': {
        'status': 'publicDomain',
        'notice': metadata,
        'rightsHolder': 'Public domain',
        'sourceUrl': sourceUrl,
        'territoryNote':
            'Marked public domain by the source under United States law; '
            'verify local law before redistribution in another territory.',
        'verifiedAt': now,
      },
      'createdAt': now,
      'updatedAt': now,
      'isBundled': true,
    });
  }

  final output = File('assets/catalog/starter_hymns.json');
  output.parent.createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  output.writeAsStringSync(
    encoder.convert({
      'version': '2026.08.1',
      'source': sourceUrl,
      'songCount': songs.length,
      'songs': songs,
    }),
  );
  stdout.writeln('Wrote ${songs.length} verified hymns to ${output.path}');
}

String _text(String html) => html
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
