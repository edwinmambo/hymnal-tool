import 'package:flutter/material.dart';
import 'package:hymnal_tool/main.dart';
import 'package:hymnal_tool/models/models.dart';

Future<Song?> showSongEditor(BuildContext context, {Song? initial}) =>
    showDialog<Song>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog.fullscreen(child: SongEditor(initial: initial)),
    );

class SongEditor extends StatefulWidget {
  const SongEditor({super.key, this.initial});

  final Song? initial;

  @override
  State<SongEditor> createState() => _SongEditorState();
}

class _SongEditorState extends State<SongEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _alternateTitle;
  late final TextEditingController _author;
  late final TextEditingController _composer;
  late final TextEditingController _tune;
  late final TextEditingController _meter;
  late final TextEditingController _topic;
  late final TextEditingController _scripture;
  late final TextEditingController _hymnal;
  late final TextEditingController _edition;
  late final TextEditingController _number;
  late final TextEditingController _sourceUrl;
  late final TextEditingController _rightsNotice;
  late final TextEditingController _rightsHolder;
  late final TextEditingController _territory;
  late RightsStatus _rightsStatus;
  late List<_EditableSection> _sections;

  @override
  void initState() {
    super.initState();
    final song = widget.initial;
    _title = TextEditingController(text: song?.title ?? '');
    _alternateTitle = TextEditingController(text: song?.alternateTitle ?? '');
    _author = TextEditingController(text: song?.author ?? '');
    _composer = TextEditingController(text: song?.composer ?? '');
    _tune = TextEditingController(text: song?.tune ?? '');
    _meter = TextEditingController(text: song?.meter ?? '');
    _topic = TextEditingController(text: song?.topic ?? '');
    _scripture = TextEditingController(
      text: song?.scriptureReferences.join(', ') ?? '',
    );
    _hymnal = TextEditingController(text: song?.hymnal.name ?? '');
    _edition = TextEditingController(text: song?.hymnal.edition ?? '');
    _number = TextEditingController(text: song?.hymnal.number ?? '');
    _sourceUrl = TextEditingController(
      text: song?.rights.sourceUrl.isNotEmpty == true
          ? song!.rights.sourceUrl
          : song?.hymnal.sourceUrl ?? '',
    );
    _rightsNotice = TextEditingController(text: song?.rights.notice ?? '');
    _rightsHolder = TextEditingController(
      text: song?.rights.rightsHolder ?? '',
    );
    _territory = TextEditingController(text: song?.rights.territoryNote ?? '');
    _rightsStatus = song?.rights.status ?? RightsStatus.userProvided;
    _sections = song == null
        ? [_EditableSection(type: SongSectionType.verse, label: 'Verse 1')]
        : song.sections.map(_EditableSection.fromSection).toList();
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _alternateTitle,
      _author,
      _composer,
      _tune,
      _meter,
      _topic,
      _scripture,
      _hymnal,
      _edition,
      _number,
      _sourceUrl,
      _rightsNotice,
      _rightsHolder,
      _territory,
    ]) {
      controller.dispose();
    }
    for (final section in _sections) {
      section.dispose();
    }
    super.dispose();
  }

  Future<void> _pasteAndStructure() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste and structure lyrics'),
        content: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use headings such as “Verse 1”, “[Chorus]”, or “Bridge:”. '
                'Blank paragraphs become verses when headings are omitted.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                minLines: 10,
                maxLines: 18,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Verse 1\nLyrics…'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Structure lyrics'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    final parsed = _parseStructuredLyrics(value);
    if (parsed.isEmpty) return;
    setState(() {
      for (final section in _sections) {
        section.dispose();
      }
      _sections = parsed;
    });
  }

  void _addSection() {
    final verseCount =
        _sections.where((item) => item.type == SongSectionType.verse).length +
        1;
    setState(() {
      _sections.add(
        _EditableSection(
          type: SongSectionType.verse,
          label: 'Verse $verseCount',
        ),
      );
    });
  }

  void _duplicateSection(int index) {
    final source = _sections[index];
    setState(() {
      _sections.insert(
        index + 1,
        _EditableSection(
          type: source.type,
          label: '${source.label.text} copy',
          lyrics: source.lyrics.text,
        ),
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sections.isEmpty ||
        _sections.every((item) => item.lyrics.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add lyrics to at least one section.')),
      );
      return;
    }
    final state = HymnalScope.of(context);
    final now = DateTime.now();
    final initial = widget.initial;
    final song = Song(
      id: initial?.id ?? state.newId(),
      title: _title.text.trim(),
      alternateTitle: _alternateTitle.text.trim(),
      author: _author.text.trim(),
      composer: _composer.text.trim(),
      tune: _tune.text.trim(),
      meter: _meter.text.trim(),
      topic: _topic.text.trim(),
      scriptureReferences: _scripture.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
      sections: [
        for (var index = 0; index < _sections.length; index++)
          SongSection(
            id: _sections[index].id ?? state.newId(),
            type: _sections[index].type,
            label: _sections[index].label.text.trim().isEmpty
                ? '${_sections[index].type.label} ${index + 1}'
                : _sections[index].label.text.trim(),
            lyrics: _sections[index].lyrics.text.trim(),
            order: index,
          ),
      ],
      hymnal: HymnalReference(
        name: _hymnal.text.trim(),
        edition: _edition.text.trim(),
        number: _number.text.trim(),
        sourceUrl: _sourceUrl.text.trim(),
      ),
      rights: RightsInfo(
        status: _rightsStatus,
        notice: _rightsNotice.text.trim(),
        rightsHolder: _rightsHolder.text.trim(),
        sourceUrl: _sourceUrl.text.trim(),
        territoryNote: _territory.text.trim(),
        verifiedAt: _rightsStatus == RightsStatus.publicDomain ? now : null,
      ),
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
      isBundled: false,
    );
    await state.saveSong(song);
    if (!mounted) return;
    Navigator.pop(context, song);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(widget.initial == null ? 'Create a song' : 'Edit song'),
        actions: [
          TextButton.icon(
            onPressed: _pasteAndStructure,
            icon: const Icon(Icons.content_paste_go_rounded),
            label: const Text('Paste & structure'),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save song'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Song information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _responsiveFields(wide, [
                    _field(_title, 'Title', required: true),
                    _field(_alternateTitle, 'Alternate title'),
                    _field(_author, 'Author'),
                    _field(_composer, 'Composer / music'),
                    _field(_tune, 'Tune'),
                    _field(_meter, 'Meter'),
                    _field(_topic, 'Topic'),
                    _field(
                      _scripture,
                      'Scripture references',
                      hint: 'Psalm 23, John 10:11',
                    ),
                    _field(_hymnal, 'Hymnal / collection'),
                    _field(_edition, 'Edition'),
                    _field(_number, 'Hymn number'),
                  ]),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Slides',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addSection,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add section'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Each section becomes one projected slide. Drag to reorder.',
                  ),
                  const SizedBox(height: 14),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sections.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        final item = _sections.removeAt(oldIndex);
                        _sections.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) => _SectionEditorCard(
                      key: ValueKey(_sections[index].key),
                      section: _sections[index],
                      onDuplicate: () => _duplicateSection(index),
                      onDelete: _sections.length == 1
                          ? null
                          : () => setState(
                              () => _sections.removeAt(index).dispose(),
                            ),
                    ),
                  ),
                  if (!wide) ...[const SizedBox(height: 28), _rightsCard()],
                ],
              ),
            ),
            if (wide)
              SizedBox(
                width: 360,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                  children: [_rightsCard()],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rightsCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rights & source',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Record the permission that lets you project this song.'),
          const SizedBox(height: 16),
          DropdownButtonFormField<RightsStatus>(
            initialValue: _rightsStatus,
            decoration: const InputDecoration(labelText: 'Rights status'),
            items: [
              for (final status in RightsStatus.values)
                DropdownMenuItem(value: status, child: Text(status.label)),
            ],
            onChanged: (value) => setState(() => _rightsStatus = value!),
          ),
          const SizedBox(height: 12),
          _field(_rightsHolder, 'Rights holder'),
          _field(_rightsNotice, 'Copyright / license notice', maxLines: 4),
          _field(_sourceUrl, 'Source URL'),
          _field(_territory, 'Territory note', maxLines: 3),
        ],
      ),
    ),
  );

  Widget _responsiveFields(bool wide, List<Widget> fields) {
    if (!wide) return Column(children: fields);
    return Wrap(
      spacing: 14,
      runSpacing: 2,
      children: fields
          .map((field) => SizedBox(width: 330, child: field))
          .toList(),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool required = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    ),
  );
}

class _EditableSection {
  _EditableSection({
    this.id,
    required this.type,
    required String label,
    String lyrics = '',
  }) : key = UniqueKey(),
       label = TextEditingController(text: label),
       lyrics = TextEditingController(text: lyrics);

  factory _EditableSection.fromSection(SongSection section) => _EditableSection(
    id: section.id,
    type: section.type,
    label: section.label,
    lyrics: section.lyrics,
  );

  final Key key;
  final String? id;
  SongSectionType type;
  final TextEditingController label;
  final TextEditingController lyrics;

  void dispose() {
    label.dispose();
    lyrics.dispose();
  }
}

class _SectionEditorCard extends StatefulWidget {
  const _SectionEditorCard({
    super.key,
    required this.section,
    required this.onDuplicate,
    this.onDelete,
  });

  final _EditableSection section;
  final VoidCallback onDuplicate;
  final VoidCallback? onDelete;

  @override
  State<_SectionEditorCard> createState() => _SectionEditorCardState();
}

class _SectionEditorCardState extends State<_SectionEditorCard> {
  @override
  Widget build(BuildContext context) {
    final lyrics = widget.section.lyrics.text;
    final readabilityWarning =
        lyrics.length > 430 || '\n'.allMatches(lyrics).length > 9;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.drag_indicator_rounded),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<SongSectionType>(
                    initialValue: widget.section.type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [
                      for (final type in SongSectionType.values)
                        DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: (value) =>
                        setState(() => widget.section.type = value!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: widget.section.label,
                    decoration: const InputDecoration(labelText: 'Slide label'),
                  ),
                ),
                IconButton(
                  tooltip: 'Duplicate section',
                  onPressed: widget.onDuplicate,
                  icon: const Icon(Icons.copy_rounded),
                ),
                IconButton(
                  tooltip: 'Delete section',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.section.lyrics,
              minLines: 4,
              maxLines: 10,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Lyrics'),
            ),
            if (readabilityWarning)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: Color(0xff9c602c),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This slide may shrink below 32 px on a 1080p display. Consider splitting it.',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

List<_EditableSection> _parseStructuredLyrics(String input) {
  final lines = input.replaceAll('\r\n', '\n').split('\n');
  final sections = <_EditableSection>[];
  final header = RegExp(
    r'^\s*(?:\[)?(verse|refrain|chorus|bridge|intro|outro|custom)\s*(\d+)?(?:\])?\s*:?\s*$',
    caseSensitive: false,
  );
  SongSectionType currentType = SongSectionType.verse;
  String currentLabel = 'Verse 1';
  final buffer = <String>[];
  var verseNumber = 1;

  void flush() {
    final lyrics = buffer.join('\n').trim();
    if (lyrics.isNotEmpty) {
      sections.add(
        _EditableSection(
          type: currentType,
          label: currentLabel,
          lyrics: lyrics,
        ),
      );
      buffer.clear();
    }
  }

  for (final line in lines) {
    final match = header.firstMatch(line);
    if (match != null) {
      flush();
      currentType = SongSectionType.values.byName(
        match.group(1)!.toLowerCase(),
      );
      final number = match.group(2);
      currentLabel = number == null
          ? currentType.label
          : '${currentType.label} $number';
      continue;
    }
    if (line.trim().isEmpty && buffer.isNotEmpty) {
      flush();
      verseNumber++;
      currentType = SongSectionType.verse;
      currentLabel = 'Verse $verseNumber';
      continue;
    }
    buffer.add(line);
  }
  flush();
  return sections;
}
