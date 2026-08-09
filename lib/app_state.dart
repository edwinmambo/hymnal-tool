import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hymnal_tool/data/repositories.dart';
import 'package:hymnal_tool/models/models.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class HymnalAppState extends ChangeNotifier {
  HymnalAppState({
    required this.songRepository,
    required this.setlistRepository,
    required this.themeRepository,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null;

  final SongRepository songRepository;
  final SetlistRepository setlistRepository;
  final ThemeRepository themeRepository;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final Uuid _uuid = const Uuid();

  StreamSubscription<List<Song>>? _songSubscription;
  StreamSubscription<List<Setlist>>? _setlistSubscription;
  StreamSubscription<List<PresentationTheme>>? _themeSubscription;

  List<Song> songs = const [];
  List<Setlist> setlists = const [];
  List<PresentationTheme> themes = const [];
  String searchQuery = '';
  String? selectedSongId;
  String? selectedSetlistId;
  String selectedThemeId = 'theme-sunrise';
  int navigationIndex = 0;
  bool initialized = false;

  Song? get selectedSong {
    for (final song in songs) {
      if (song.id == selectedSongId) return song;
    }
    return songs.firstOrNull;
  }

  Setlist? get selectedSetlist {
    for (final setlist in setlists) {
      if (setlist.id == selectedSetlistId) return setlist;
    }
    return setlists.firstOrNull;
  }

  PresentationTheme get selectedTheme {
    for (final theme in themes) {
      if (theme.id == selectedThemeId) return theme;
    }
    return defaultThemes.first;
  }

  List<Song> get filteredSongs {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return songs;

    final numberQuery = query.startsWith('#') ? query.substring(1) : query;
    if (RegExp(r'^\d+$').hasMatch(numberQuery)) {
      final exact = songs.where(
        (song) => _normalizedHymnNumber(song.hymnal.number) == numberQuery,
      );
      final prefix = songs.where((song) {
        final number = _normalizedHymnNumber(song.hymnal.number);
        return number.isNotEmpty &&
            number.startsWith(numberQuery) &&
            number != numberQuery;
      });
      final numberedMatches = [...exact, ...prefix];
      if (numberedMatches.isNotEmpty) return numberedMatches;
    }
    return songs.where((song) => song.searchableText.contains(query)).toList();
  }

  static String _normalizedHymnNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    return BigInt.parse(digits).toString();
  }

  List<Song> get selectedSetlistSongs {
    final setlist = selectedSetlist;
    if (setlist == null) return const [];
    return setlist.songIds
        .map((id) => songs.where((song) => song.id == id).firstOrNull)
        .whereType<Song>()
        .toList();
  }

  List<Song> get songsForPresentation {
    final planned = selectedSetlistSongs;
    if (planned.isNotEmpty) return planned;
    final song = selectedSong;
    return song == null ? const [] : [song];
  }

  Future<void> initialize() async {
    await themeRepository.seedBuiltIns(defaultThemes);
    final bundled = await _loadBundledCatalog();
    await songRepository.seedBundled(bundled);

    _songSubscription = songRepository.watchAll().listen((value) {
      songs = value;
      selectedSongId ??= value.firstOrNull?.id;
      notifyListeners();
    });
    _setlistSubscription = setlistRepository.watchAll().listen((value) {
      setlists = value;
      selectedSetlistId ??= value.firstOrNull?.id;
      notifyListeners();
    });
    _themeSubscription = themeRepository.watchAll().listen((value) {
      themes = value;
      notifyListeners();
    });
    initialized = true;
    notifyListeners();
  }

  Future<List<Song>> _loadBundledCatalog() async {
    final source = await rootBundle.loadString(
      'assets/catalog/starter_hymns.json',
    );
    final payload = jsonDecode(source) as Map<String, dynamic>;
    final version = payload['version'] as String?;
    if (version == null || version.isEmpty) {
      throw const FormatException('The starter catalog has no version.');
    }
    final entries = (payload['songs'] as List)
        .cast<Map<String, dynamic>>()
        .map(Song.fromJson)
        .map(_withSdahReference)
        .toList();
    final ids = <String>{};
    for (final song in entries) {
      if (!ids.add(song.id) ||
          song.sections.isEmpty ||
          song.rights.status != RightsStatus.publicDomain ||
          song.rights.sourceUrl.isEmpty ||
          song.rights.verifiedAt == null) {
        throw FormatException('Invalid bundled hymn: ${song.title}');
      }
      for (var index = 0; index < song.sections.length; index++) {
        if (song.sections[index].order != index) {
          throw FormatException('Invalid section order: ${song.title}');
        }
      }
    }
    return entries;
  }

  Song _withSdahReference(Song song) {
    final number = _sdahNumbersByTitle[song.title];
    if (number == null) return song;
    return song.copyWith(
      hymnal: HymnalReference(
        name: 'Seventh-day Adventist Hymnal',
        edition: '1985',
        number: number,
        sourceUrl: 'https://hymnary.org/hymnal/SDAH1985',
      ),
    );
  }

  void setSearch(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void selectSong(String id) {
    selectedSongId = id;
    notifyListeners();
  }

  void selectSetlist(String id) {
    selectedSetlistId = id;
    notifyListeners();
  }

  void selectTheme(String id) {
    selectedThemeId = id;
    notifyListeners();
  }

  void setNavigationIndex(int value) {
    navigationIndex = value;
    notifyListeners();
  }

  Future<void> saveSong(Song song) => songRepository.save(song);

  Future<int> importCatalogText(String source, {String origin = ''}) async {
    if (source.length > 12 * 1024 * 1024) {
      throw const FormatException('Catalogs must be smaller than 12 MB.');
    }
    final decoded = jsonDecode(source);
    final rawEntries = switch (decoded) {
      {'songs': final List<dynamic> songs} => songs,
      final List<dynamic> songs => songs,
      _ => throw const FormatException(
        'Expected a JSON object with a songs list, or a JSON list of songs.',
      ),
    };
    if (rawEntries.isEmpty) {
      throw const FormatException('The catalog contains no hymns.');
    }
    if (rawEntries.length > 2500) {
      throw const FormatException('A catalog can contain at most 2,500 hymns.');
    }

    final imported = <Song>[];
    final ids = <String>{};
    for (var index = 0; index < rawEntries.length; index++) {
      final raw = rawEntries[index];
      if (raw is! Map) {
        throw FormatException('Hymn ${index + 1} is not a JSON object.');
      }
      final song = Song.fromJson(Map<String, dynamic>.from(raw));
      if (song.title.trim().isEmpty || song.sections.isEmpty) {
        throw FormatException('Hymn ${index + 1} needs a title and lyrics.');
      }
      if (!ids.add(song.id)) {
        throw FormatException('Duplicate hymn id: ${song.id}');
      }
      if (song.rights.status == RightsStatus.unknown) {
        throw FormatException(
          '“${song.title}” needs public-domain, licensed, or user-provided rights metadata.',
        );
      }
      imported.add(
        song.copyWith(
          isBundled: false,
          hymnal: origin.isEmpty || song.hymnal.sourceUrl.isNotEmpty
              ? song.hymnal
              : HymnalReference(
                  name: song.hymnal.name,
                  edition: song.hymnal.edition,
                  number: song.hymnal.number,
                  sourceUrl: origin,
                ),
        ),
      );
    }

    for (final song in imported) {
      await songRepository.save(song);
    }
    selectedSongId = imported.first.id;
    notifyListeners();
    return imported.length;
  }

  Future<int> importCatalogUrl(Uri uri) async {
    if (!{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) {
      throw const FormatException('Enter a valid http or https catalog URL.');
    }
    final response = await _httpClient
        .get(uri, headers: const {'accept': 'application/json'})
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException(
        'Catalog download failed with HTTP ${response.statusCode}.',
      );
    }
    if (response.bodyBytes.length > 12 * 1024 * 1024) {
      throw const FormatException('Catalogs must be smaller than 12 MB.');
    }
    return importCatalogText(
      utf8.decode(response.bodyBytes),
      origin: uri.toString(),
    );
  }

  Future<void> deleteSong(Song song) async {
    if (song.isBundled) return;
    await songRepository.delete(song.id);
  }

  Future<Song> createEditableCopy(Song song) async {
    final now = DateTime.now();
    final copy = song.copyWith(
      id: _uuid.v4(),
      title: '${song.title} — edited copy',
      sections: [
        for (final section in song.sections) section.copyWith(id: _uuid.v4()),
      ],
      rights: const RightsInfo(
        status: RightsStatus.userProvided,
        notice: 'Local edited copy. Confirm rights before public projection.',
      ),
      createdAt: now,
      updatedAt: now,
      isBundled: false,
    );
    await saveSong(copy);
    selectedSongId = copy.id;
    return copy;
  }

  Future<Setlist> createSetlist(String name) async {
    final now = DateTime.now();
    final setlist = Setlist(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? 'New service' : name.trim(),
      songIds: const [],
      createdAt: now,
      updatedAt: now,
    );
    await setlistRepository.save(setlist);
    selectedSetlistId = setlist.id;
    return setlist;
  }

  Future<void> deleteSetlist(Setlist setlist) =>
      setlistRepository.delete(setlist.id);

  Future<void> addSongToSelectedSetlist(Song song) async {
    var setlist = selectedSetlist;
    setlist ??= await createSetlist('Sunday service');
    await setlistRepository.save(
      setlist.copyWith(
        songIds: [...setlist.songIds, song.id],
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> reorderSetlist(int oldIndex, int newIndex) async {
    final setlist = selectedSetlist;
    if (setlist == null) return;
    final ids = [...setlist.songIds];
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    await setlistRepository.save(
      setlist.copyWith(songIds: ids, updatedAt: DateTime.now()),
    );
  }

  Future<void> removeSetlistEntry(int index) async {
    final setlist = selectedSetlist;
    if (setlist == null) return;
    final ids = [...setlist.songIds]..removeAt(index);
    await setlistRepository.save(
      setlist.copyWith(songIds: ids, updatedAt: DateTime.now()),
    );
  }

  Future<void> saveTheme(PresentationTheme theme) =>
      themeRepository.save(theme);

  Future<PresentationTheme> addCustomBackground({
    required String name,
    required Uint8List bytes,
  }) async {
    final theme = PresentationTheme(
      id: _uuid.v4(),
      name: name,
      gradientColors: const [0xff2c1b18, 0xff0f1115],
      backgroundBytes: bytes,
    );
    await themeRepository.save(theme);
    selectedThemeId = theme.id;
    return theme;
  }

  String newId() => _uuid.v4();

  @override
  void dispose() {
    _songSubscription?.cancel();
    _setlistSubscription?.cancel();
    _themeSubscription?.cancel();
    if (_ownsHttpClient) _httpClient.close();
    super.dispose();
  }
}

const defaultThemes = [
  PresentationTheme(
    id: 'theme-sunrise',
    name: 'Quiet sunrise',
    gradientColors: [0xff8c4d3f, 0xff281e2b, 0xff10131a],
    overlayStrength: .3,
    isBuiltIn: true,
  ),
  PresentationTheme(
    id: 'theme-olive',
    name: 'Olive grove',
    gradientColors: [0xff66705a, 0xff24372f, 0xff111815],
    overlayStrength: .38,
    isBuiltIn: true,
  ),
  PresentationTheme(
    id: 'theme-dusk',
    name: 'Evening prayer',
    gradientColors: [0xff6f587d, 0xff2f2847, 0xff12131c],
    overlayStrength: .32,
    isBuiltIn: true,
  ),
  PresentationTheme(
    id: 'theme-ember',
    name: 'Warm ember',
    gradientColors: [0xffa05b3b, 0xff482a2e, 0xff161116],
    overlayStrength: .4,
    isBuiltIn: true,
  ),
];

/// SDAH number metadata for the public-domain starter texts.
///
/// Rights and lyric provenance remain attached to the Open Hymnal records;
/// this map only makes the corresponding 1985 SDAH numbers searchable.
const _sdahNumbersByTitle = <String, String>{
  'A Mighty Fortress Is Our God': '506',
  'Abide With Me': '50',
  'All Creatures of Our God and King': '2',
  "All Hail The Power Of Jesus' Name": '229',
  'Amazing Grace': '108',
  'And Can It Be': '198',
  'Be Thou My Vision': '547',
  'Blessed Assurance': '462',
  'Come Thou Fount Of Every Blessing': '334',
  'Crown Him With Many Crowns': '223',
  'For The Beauty Of The Earth': '565',
  'Holy, Holy, Holy': '73',
  'How Firm A Foundation': '509',
  'I Need Thee Every Hour': '483',
  'Immortal, Invisible, God Only Wise': '21',
  'It Is Well With My Soul': '530',
  'Joyful, Joyful, We Adore Thee': '12',
  'My Hope Is Built': '522',
  'Nearer, My God, To Thee': '473',
  'Jesus Shall Reign': '227',
  'Pass Me Not, O Gentle Savior': '569',
  'Praise To The Lord, The Almighty': '1',
  'Rock of Ages': '300',
  'Take My Life And Let It Be': '330',
  'What A Friend We Have In Jesus': '499',
  'When I Survey the Wondrous Cross': '154',
  'Guide Me, O Thou Great Jehovah': '538',
  'O For A Thousand Tongues': '250',
  'Savior, Like A Shepherd Lead Us': '545',
  'Beautiful Savior': '240',
};
