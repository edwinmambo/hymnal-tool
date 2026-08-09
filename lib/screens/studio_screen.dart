import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:hymnal_tool/app_state.dart';
import 'package:hymnal_tool/main.dart';
import 'package:hymnal_tool/models/models.dart';
import 'package:hymnal_tool/screens/presenter_screen.dart';
import 'package:hymnal_tool/screens/song_editor.dart';
import 'package:hymnal_tool/widgets/common.dart';

class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = HymnalScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _StudioHeader(compact: compact),
            Expanded(
              child: compact
                  ? _mobileBody(state.navigationIndex)
                  : Row(
                      children: [
                        _StudioNavigation(
                          selectedIndex: state.navigationIndex,
                          onDestinationSelected: state.setNavigationIndex,
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: _desktopBody(state.navigationIndex)),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: compact
          ? NavigationBar(
              selectedIndex: state.navigationIndex,
              onDestinationSelected: state.setNavigationIndex,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music_rounded),
                  label: 'Library',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_note_outlined),
                  selectedIcon: Icon(Icons.event_note_rounded),
                  label: 'Setlists',
                ),
                NavigationDestination(
                  icon: Icon(Icons.palette_outlined),
                  selectedIcon: Icon(Icons.palette_rounded),
                  label: 'Themes',
                ),
              ],
            )
          : null,
    );
  }

  Widget _desktopBody(int index) => switch (index) {
    1 => const SetlistsView(),
    2 => const ThemesView(),
    _ => const LibraryView(),
  };

  Widget _mobileBody(int index) => switch (index) {
    1 => const SetlistsView(compact: true),
    2 => const ThemesView(compact: true),
    _ => const LibraryView(compact: true),
  };
}

class _StudioHeader extends StatelessWidget {
  const _StudioHeader({required this.compact});

  final bool compact;

  Future<void> _present(BuildContext context) async {
    final state = HymnalScope.of(context);
    final songs = state.songsForPresentation;
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a song or add songs to a setlist first.'),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PresenterScreen(
          songs: songs,
          theme: state.selectedTheme,
          initialSongId: state.selectedSong?.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(compact ? 16 : 22, 14, compact ? 16 : 22, 12),
    child: Row(
      children: [
        const BrandMark(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hymnal Tool',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (!compact)
                Text(
                  'Prepare quietly. Present beautifully.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              HymnalScope.of(context).selectedSetlist?.name ??
                  'Single song mode',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        FilledButton.icon(
          onPressed: () => _present(context),
          icon: const Icon(Icons.present_to_all_rounded),
          label: Text(compact ? 'Present' : 'Start presentation'),
        ),
      ],
    ),
  );
}

class _StudioNavigation extends StatelessWidget {
  const _StudioNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => NavigationRail(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    labelType: NavigationRailLabelType.all,
    groupAlignment: -.7,
    destinations: const [
      NavigationRailDestination(
        icon: Icon(Icons.library_music_outlined),
        selectedIcon: Icon(Icons.library_music_rounded),
        label: Text('Library'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.event_note_outlined),
        selectedIcon: Icon(Icons.event_note_rounded),
        label: Text('Setlists'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.palette_outlined),
        selectedIcon: Icon(Icons.palette_rounded),
        label: Text('Themes'),
      ),
    ],
  );
}

class LibraryView extends StatelessWidget {
  const LibraryView({super.key, this.compact = false});

  final bool compact;

  Future<void> _createSong(BuildContext context) async {
    final result = await showSongEditor(context);
    if (result != null && context.mounted) {
      HymnalScope.of(context).selectSong(result.id);
    }
  }

  Future<void> _openCatalogImporter(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _CatalogImportSheet(state: HymnalScope.of(context)),
      );

  @override
  Widget build(BuildContext context) {
    final state = HymnalScope.of(context);
    final list = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Song library',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text('${state.songs.length} songs available offline'),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Get more hymns',
                    onPressed: () => _openCatalogImporter(context),
                    icon: const Icon(Icons.cloud_download_outlined),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Create song',
                    onPressed: () => _createSong(context),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: state.setSearch,
                decoration: const InputDecoration(
                  hintText: 'Search title, number, topic, scripture, or lyrics',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.filteredSongs.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No songs found',
                  message:
                      'Try a different title, hymn number, topic, or lyric phrase.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                  itemCount: state.filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = state.filteredSongs[index];
                    final selected = song.id == state.selectedSong?.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: ListTile(
                        selected: selected,
                        selectedTileColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: .55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: song.isBundled
                                ? Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: song.hymnal.number.isNotEmpty
                              ? Text(
                                  song.hymnal.number,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : Icon(
                                  song.isBundled
                                      ? Icons.menu_book_rounded
                                      : Icons.music_note_rounded,
                                ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.author.isEmpty
                              ? '${song.sections.length} slides'
                              : song.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing:
                            song.rights.status == RightsStatus.publicDomain
                            ? const Tooltip(
                                message: 'Public domain',
                                child: Icon(Icons.public_rounded, size: 19),
                              )
                            : null,
                        onTap: () {
                          state.selectSong(song.id);
                          if (compact) {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(
                                    title: const Text('Song details'),
                                  ),
                                  body: SongDetailPane(song: song),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
    if (compact) return list;
    return Row(
      children: [
        SizedBox(width: 360, child: list),
        const VerticalDivider(width: 1),
        Expanded(
          child: state.selectedSong == null
              ? const EmptyState(
                  icon: Icons.library_music_rounded,
                  title: 'Choose a song',
                  message:
                      'Select a hymn to see its slides, metadata, and presentation actions.',
                )
              : SongDetailPane(song: state.selectedSong!),
        ),
      ],
    );
  }
}

class SongDetailPane extends StatelessWidget {
  const SongDetailPane({super.key, required this.song});

  final Song song;

  Future<void> _present(BuildContext context) async {
    final state = HymnalScope.of(context);
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PresenterScreen(
          songs: [song],
          theme: state.selectedTheme,
          initialSongId: song.id,
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final state = HymnalScope.of(context);
    final editable = song.isBundled
        ? await state.createEditableCopy(song)
        : song;
    if (!context.mounted) return;
    final result = await showSongEditor(context, initial: editable);
    if (result != null && context.mounted) state.selectSong(result.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = HymnalScope.of(context);
    final reference = [
      if (song.hymnal.name.isNotEmpty) song.hymnal.name,
      if (song.hymnal.edition.isNotEmpty) song.hymnal.edition,
      if (song.hymnal.number.isNotEmpty) '#${song.hymnal.number}',
    ].join(' · ');
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 16,
          runSpacing: 14,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reference.isNotEmpty)
                    Text(
                      reference.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  if (song.author.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Words: ${song.author}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _present(context),
                  icon: const Icon(Icons.present_to_all_rounded),
                  label: const Text('Present'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await state.addSongToSelectedSetlist(song);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added “${song.title}” to the active setlist.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.playlist_add_rounded),
                  label: const Text('Add to setlist'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _edit(context),
                  icon: Icon(
                    song.isBundled ? Icons.copy_rounded : Icons.edit_rounded,
                  ),
                  label: Text(song.isBundled ? 'Edit copy' : 'Edit'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (song.topic.isNotEmpty)
              Chip(
                avatar: const Icon(Icons.sell_outlined, size: 18),
                label: Text(song.topic),
              ),
            if (song.tune.isNotEmpty)
              Chip(
                avatar: const Icon(Icons.graphic_eq_rounded, size: 18),
                label: Text(song.tune),
              ),
            if (song.meter.isNotEmpty) Chip(label: Text('Meter ${song.meter}')),
            for (final scripture in song.scriptureReferences)
              Chip(
                avatar: const Icon(Icons.auto_stories_outlined, size: 18),
                label: Text(scripture),
              ),
          ],
        ),
        const SizedBox(height: 26),
        Text('Lyrics', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        _SectionGrid(sections: song.sections),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined),
                    const SizedBox(width: 10),
                    Text(
                      'Rights & source',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(song.rights.status.label),
                if (song.rights.notice.isNotEmpty) Text(song.rights.notice),
                if (song.rights.territoryNote.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    song.rights.territoryNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionGrid extends StatelessWidget {
  const _SectionGrid({required this.sections});

  final List<SongSection> sections;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 12.0;
      final columns = constraints.maxWidth >= 760 ? 2 : 1;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final section in sections)
            SizedBox(
              width: width,
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            section.type == SongSectionType.verse
                                ? Icons.format_align_left_rounded
                                : Icons.repeat_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            section.label.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        section.lyrics,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(height: 1.55),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _CatalogImportSheet extends StatefulWidget {
  const _CatalogImportSheet({required this.state});

  final HymnalAppState state;

  @override
  State<_CatalogImportSheet> createState() => _CatalogImportSheetState();
}

class _CatalogImportSheetState extends State<_CatalogImportSheet> {
  final TextEditingController _url = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _run(Future<int> Function() operation) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final count = await operation();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count hymns saved for offline use.')),
      );
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              'Could not import this catalog. Check the URL, JSON format, and web CORS access. ($error)',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFile() async {
    const jsonTypes = XTypeGroup(label: 'Hymnal JSON', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: const [jsonTypes]);
    if (file == null) return;
    await _run(
      () async => widget.state.importCatalogText(
        utf8.decode(await file.readAsBytes()),
        origin: file.name,
      ),
    );
  }

  Future<void> _download() async {
    final uri = Uri.tryParse(_url.text.trim());
    if (uri == null) {
      setState(() => _error = 'Enter a valid catalog URL.');
      return;
    }
    await _run(() => widget.state.importCatalogUrl(uri));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        4,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Get more hymns',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Import a hymnal catalog from a JSON file or download one directly. Imported hymns are stored on this device and remain available offline.',
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickFile,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Choose JSON catalog'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'OR DOWNLOAD',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _url,
                enabled: !_busy,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Catalog URL',
                  hintText: 'https://example.org/hymnal.json',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
                onSubmitted: (_) => _busy ? null : _download(),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _download,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_for_offline_outlined),
                label: Text(_busy ? 'Importing…' : 'Download and save'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'SDAH Extended-ready: you can import a licensed or user-provided SDAH catalog here. The app requires every imported hymn to include rights metadata; copyrighted lyrics are not bundled automatically.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Format: a JSON object with a “songs” array using the same fields as the bundled starter catalog. Up to 2,500 hymns and 12 MB per import.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SetlistsView extends StatelessWidget {
  const SetlistsView({super.key, this.compact = false});

  final bool compact;

  Future<void> _create(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New setlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && context.mounted) {
      await HymnalScope.of(context).createSetlist(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = HymnalScope.of(context);
    final selector = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Saved setlists',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => _create(context),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.setlists.isEmpty
              ? EmptyState(
                  icon: Icons.event_note_rounded,
                  title: 'Plan a service',
                  message: 'Create a setlist, then add songs from the library.',
                  action: FilledButton.icon(
                    onPressed: () => _create(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create setlist'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: state.setlists.length,
                  itemBuilder: (context, index) {
                    final item = state.setlists[index];
                    return ListTile(
                      selected: item.id == state.selectedSetlist?.id,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: .55),
                      leading: const Icon(Icons.event_note_rounded),
                      title: Text(item.name),
                      subtitle: Text('${item.songIds.length} songs'),
                      onTap: () => state.selectSetlist(item.id),
                    );
                  },
                ),
        ),
      ],
    );
    if (compact) {
      return Column(
        children: [
          SizedBox(height: 230, child: selector),
          const Divider(height: 1),
          const Expanded(child: _SetlistDetail()),
        ],
      );
    }
    return Row(
      children: [
        SizedBox(width: 330, child: selector),
        const VerticalDivider(width: 1),
        const Expanded(child: _SetlistDetail()),
      ],
    );
  }
}

class _SetlistDetail extends StatelessWidget {
  const _SetlistDetail();

  @override
  Widget build(BuildContext context) {
    final state = HymnalScope.of(context);
    final setlist = state.selectedSetlist;
    if (setlist == null) {
      return const EmptyState(
        icon: Icons.playlist_play_rounded,
        title: 'Choose a setlist',
        message: 'Its song order and presentation flow will appear here.',
      );
    }
    final songs = state.selectedSetlistSongs;
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setlist.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text('${songs.length} songs · drag to reorder'),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete setlist',
                onPressed: () => state.deleteSetlist(setlist),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: songs.isEmpty
                ? const EmptyState(
                    icon: Icons.playlist_add_rounded,
                    title: 'This setlist is empty',
                    message:
                        'Open the library and use “Add to setlist” on a song.',
                  )
                : ReorderableListView.builder(
                    itemCount: songs.length,
                    onReorderItem: state.reorderSetlist,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return Card(
                        key: ValueKey('${setlist.id}-$index-${song.id}'),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(song.title),
                          subtitle: Text('${song.sections.length} slides'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Remove',
                                onPressed: () =>
                                    state.removeSetlistEntry(index),
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                ),
                              ),
                              const Icon(Icons.drag_indicator_rounded),
                            ],
                          ),
                          onTap: () {
                            state.selectSong(song.id);
                            state.setNavigationIndex(0);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ThemesView extends StatelessWidget {
  const ThemesView({super.key, this.compact = false});

  final bool compact;

  Future<void> _importBackground(BuildContext context) async {
    const imageTypes = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final file = await openFile(acceptedTypeGroups: const [imageTypes]);
    if (file == null || !context.mounted) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    await HymnalScope.of(
      context,
    ).addCustomBackground(name: file.name, bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    final state = HymnalScope.of(context);
    final theme = state.selectedTheme;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presentation themes',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Text('Choose a warm backdrop or bring your own image.'),
              ],
            ),
            FilledButton.tonalIcon(
              onPressed: () => _importBackground(context),
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Import background'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: compact ? 280 : 340,
            mainAxisExtent: 200,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: state.themes.length,
          itemBuilder: (context, index) {
            final item = state.themes[index];
            final selected = item.id == theme.id;
            return InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => state.selectTheme(item.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.all(selected ? 4 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: ThemeBackdrop(
                  theme: item,
                  borderRadius: BorderRadius.circular(19),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Text(
                          'Amazing grace, how sweet the sound',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(item.textColor),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fine tune “${theme.name}”',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Contrast overlay · ${(theme.overlayStrength * 100).round()}%',
                ),
                Slider(
                  value: theme.overlayStrength,
                  onChanged: (value) =>
                      state.saveTheme(theme.copyWith(overlayStrength: value)),
                ),
                Text('Preferred text size · ${theme.fontSize.round()} px'),
                Slider(
                  min: 40,
                  max: 92,
                  divisions: 13,
                  value: theme.fontSize.clamp(40, 92),
                  onChanged: (value) =>
                      state.saveTheme(theme.copyWith(fontSize: value)),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'left',
                      icon: Icon(Icons.format_align_left_rounded),
                      label: Text('Left'),
                    ),
                    ButtonSegment(
                      value: 'center',
                      icon: Icon(Icons.format_align_center_rounded),
                      label: Text('Center'),
                    ),
                    ButtonSegment(
                      value: 'right',
                      icon: Icon(Icons.format_align_right_rounded),
                      label: Text('Right'),
                    ),
                  ],
                  selected: {theme.alignment},
                  onSelectionChanged: (value) =>
                      state.saveTheme(theme.copyWith(alignment: value.first)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
