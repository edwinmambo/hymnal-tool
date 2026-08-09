import 'dart:typed_data';

enum SongSectionType { verse, refrain, chorus, bridge, intro, outro, custom }

extension SongSectionTypeLabel on SongSectionType {
  String get label => switch (this) {
    SongSectionType.verse => 'Verse',
    SongSectionType.refrain => 'Refrain',
    SongSectionType.chorus => 'Chorus',
    SongSectionType.bridge => 'Bridge',
    SongSectionType.intro => 'Intro',
    SongSectionType.outro => 'Outro',
    SongSectionType.custom => 'Custom',
  };
}

class SongSection {
  const SongSection({
    required this.id,
    required this.type,
    required this.label,
    required this.lyrics,
    required this.order,
  });

  final String id;
  final SongSectionType type;
  final String label;
  final String lyrics;
  final int order;

  SongSection copyWith({
    String? id,
    SongSectionType? type,
    String? label,
    String? lyrics,
    int? order,
  }) => SongSection(
    id: id ?? this.id,
    type: type ?? this.type,
    label: label ?? this.label,
    lyrics: lyrics ?? this.lyrics,
    order: order ?? this.order,
  );

  factory SongSection.fromJson(Map<String, dynamic> json) => SongSection(
    id: json['id'] as String,
    type: SongSectionType.values.byName(json['type'] as String),
    label: json['label'] as String,
    lyrics: json['lyrics'] as String,
    order: json['order'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'label': label,
    'lyrics': lyrics,
    'order': order,
  };
}

enum RightsStatus { publicDomain, licensed, userProvided, unknown }

extension RightsStatusLabel on RightsStatus {
  String get label => switch (this) {
    RightsStatus.publicDomain => 'Public domain',
    RightsStatus.licensed => 'Licensed',
    RightsStatus.userProvided => 'User provided',
    RightsStatus.unknown => 'Unknown',
  };
}

class HymnalReference {
  const HymnalReference({
    this.name = '',
    this.edition = '',
    this.number = '',
    this.sourceUrl = '',
  });

  final String name;
  final String edition;
  final String number;
  final String sourceUrl;

  factory HymnalReference.fromJson(Map<String, dynamic>? json) =>
      HymnalReference(
        name: json?['name'] as String? ?? '',
        edition: json?['edition'] as String? ?? '',
        number: json?['number'] as String? ?? '',
        sourceUrl: json?['sourceUrl'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'edition': edition,
    'number': number,
    'sourceUrl': sourceUrl,
  };
}

class RightsInfo {
  const RightsInfo({
    required this.status,
    this.notice = '',
    this.rightsHolder = '',
    this.sourceUrl = '',
    this.territoryNote = '',
    this.verifiedAt,
  });

  final RightsStatus status;
  final String notice;
  final String rightsHolder;
  final String sourceUrl;
  final String territoryNote;
  final DateTime? verifiedAt;

  factory RightsInfo.fromJson(Map<String, dynamic>? json) => RightsInfo(
    status: RightsStatus.values.byName(
      json?['status'] as String? ?? RightsStatus.unknown.name,
    ),
    notice: json?['notice'] as String? ?? '',
    rightsHolder: json?['rightsHolder'] as String? ?? '',
    sourceUrl: json?['sourceUrl'] as String? ?? '',
    territoryNote: json?['territoryNote'] as String? ?? '',
    verifiedAt: json?['verifiedAt'] == null
        ? null
        : DateTime.parse(json!['verifiedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'notice': notice,
    'rightsHolder': rightsHolder,
    'sourceUrl': sourceUrl,
    'territoryNote': territoryNote,
    'verifiedAt': verifiedAt?.toIso8601String(),
  };
}

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.sections,
    required this.createdAt,
    required this.updatedAt,
    required this.rights,
    this.alternateTitle = '',
    this.author = '',
    this.composer = '',
    this.tune = '',
    this.meter = '',
    this.topic = '',
    this.scriptureReferences = const [],
    this.hymnal = const HymnalReference(),
    this.isBundled = false,
  });

  final String id;
  final String title;
  final String alternateTitle;
  final String author;
  final String composer;
  final String tune;
  final String meter;
  final String topic;
  final List<String> scriptureReferences;
  final List<SongSection> sections;
  final HymnalReference hymnal;
  final RightsInfo rights;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isBundled;

  String get searchableText => [
    title,
    alternateTitle,
    author,
    composer,
    tune,
    meter,
    topic,
    hymnal.name,
    hymnal.number,
    ...scriptureReferences,
    ...sections.map((section) => section.lyrics),
  ].join(' ').toLowerCase();

  Song copyWith({
    String? id,
    String? title,
    String? alternateTitle,
    String? author,
    String? composer,
    String? tune,
    String? meter,
    String? topic,
    List<String>? scriptureReferences,
    List<SongSection>? sections,
    HymnalReference? hymnal,
    RightsInfo? rights,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isBundled,
  }) => Song(
    id: id ?? this.id,
    title: title ?? this.title,
    alternateTitle: alternateTitle ?? this.alternateTitle,
    author: author ?? this.author,
    composer: composer ?? this.composer,
    tune: tune ?? this.tune,
    meter: meter ?? this.meter,
    topic: topic ?? this.topic,
    scriptureReferences: scriptureReferences ?? this.scriptureReferences,
    sections: sections ?? this.sections,
    hymnal: hymnal ?? this.hymnal,
    rights: rights ?? this.rights,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isBundled: isBundled ?? this.isBundled,
  );

  factory Song.fromJson(Map<String, dynamic> json) => Song(
    id: json['id'] as String,
    title: json['title'] as String,
    alternateTitle: json['alternateTitle'] as String? ?? '',
    author: json['author'] as String? ?? '',
    composer: json['composer'] as String? ?? '',
    tune: json['tune'] as String? ?? '',
    meter: json['meter'] as String? ?? '',
    topic: json['topic'] as String? ?? '',
    scriptureReferences: (json['scriptureReferences'] as List? ?? const [])
        .cast<String>(),
    sections:
        (json['sections'] as List)
            .cast<Map<String, dynamic>>()
            .map(SongSection.fromJson)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
    hymnal: HymnalReference.fromJson(json['hymnal'] as Map<String, dynamic>?),
    rights: RightsInfo.fromJson(json['rights'] as Map<String, dynamic>?),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isBundled: json['isBundled'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'alternateTitle': alternateTitle,
    'author': author,
    'composer': composer,
    'tune': tune,
    'meter': meter,
    'topic': topic,
    'scriptureReferences': scriptureReferences,
    'sections': sections.map((section) => section.toJson()).toList(),
    'hymnal': hymnal.toJson(),
    'rights': rights.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isBundled': isBundled,
  };
}

class Setlist {
  const Setlist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<String> songIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Setlist copyWith({
    String? name,
    List<String>? songIds,
    DateTime? updatedAt,
  }) => Setlist(
    id: id,
    name: name ?? this.name,
    songIds: songIds ?? this.songIds,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory Setlist.fromJson(Map<String, dynamic> json) => Setlist(
    id: json['id'] as String,
    name: json['name'] as String,
    songIds: (json['songIds'] as List).cast<String>(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'songIds': songIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class PresentationTheme {
  const PresentationTheme({
    required this.id,
    required this.name,
    required this.gradientColors,
    this.overlayStrength = .35,
    this.textColor = 0xffffffff,
    this.alignment = 'center',
    this.fontSize = 64,
    this.isBuiltIn = false,
    this.backgroundBytes,
  });

  final String id;
  final String name;
  final List<int> gradientColors;
  final double overlayStrength;
  final int textColor;
  final String alignment;
  final double fontSize;
  final bool isBuiltIn;
  final Uint8List? backgroundBytes;

  PresentationTheme copyWith({
    String? id,
    String? name,
    List<int>? gradientColors,
    double? overlayStrength,
    int? textColor,
    String? alignment,
    double? fontSize,
    bool? isBuiltIn,
    Uint8List? backgroundBytes,
  }) => PresentationTheme(
    id: id ?? this.id,
    name: name ?? this.name,
    gradientColors: gradientColors ?? this.gradientColors,
    overlayStrength: overlayStrength ?? this.overlayStrength,
    textColor: textColor ?? this.textColor,
    alignment: alignment ?? this.alignment,
    fontSize: fontSize ?? this.fontSize,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    backgroundBytes: backgroundBytes ?? this.backgroundBytes,
  );

  factory PresentationTheme.fromJson(
    Map<String, dynamic> json, {
    Uint8List? backgroundBytes,
  }) => PresentationTheme(
    id: json['id'] as String,
    name: json['name'] as String,
    gradientColors: (json['gradientColors'] as List).cast<int>(),
    overlayStrength: (json['overlayStrength'] as num).toDouble(),
    textColor: json['textColor'] as int,
    alignment: json['alignment'] as String,
    fontSize: (json['fontSize'] as num).toDouble(),
    isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    backgroundBytes: backgroundBytes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gradientColors': gradientColors,
    'overlayStrength': overlayStrength,
    'textColor': textColor,
    'alignment': alignment,
    'fontSize': fontSize,
    'isBuiltIn': isBuiltIn,
  };
}

class PresentationSlide {
  const PresentationSlide({
    required this.song,
    required this.section,
    required this.songIndex,
    required this.sectionIndex,
  });

  final Song song;
  final SongSection section;
  final int songIndex;
  final int sectionIndex;
}
