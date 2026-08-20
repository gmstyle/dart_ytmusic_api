import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';

void main() {
  runApp(const YTMusicTestApp());
}

class YTMusicTestApp extends StatelessWidget {
  const YTMusicTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YTMusic API Tester',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const InitPage(),
    );
  }
}

// ─── Init Page ────────────────────────────────────────────────────────────────

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await YTMusic().initialize();
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting to YouTube Music…'),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Init error:\n$_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _init();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Home ─────────────────────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final List<_ApiGroup> _groups = [
    _ApiGroup('Search', [
      _ApiItem('Search Songs', _searchSongs),
      _ApiItem('Search Videos', _searchVideos),
      _ApiItem('Search Artists', _searchArtists),
      _ApiItem('Search Albums', _searchAlbums),
      _ApiItem('Search Playlists', _searchPlaylists),
      _ApiItem('Search Podcasts', _searchPodcasts),
      _ApiItem('Search Episodes', _searchEpisodes),
      _ApiItem('Search Profiles', _searchProfiles),
      _ApiItem('Search (generic)', _search),
      _ApiItem('Suggestions', _suggestions),
    ]),
    _ApiGroup('Get by ID', [
      _ApiItem('Get Song', _getSong),
      _ApiItem('Get Video', _getVideo),
      _ApiItem('Get Lyrics', _getLyrics),
      _ApiItem('Get Timed Lyrics', _getTimedLyrics),
      _ApiItem('Get Up Nexts', _getUpNexts),
      _ApiItem('Get Watch Playlist', _getWatchPlaylist),
      _ApiItem('Get Song Related', _getSongRelated),
      _ApiItem('Get Artist', _getArtist),
      _ApiItem('Get Artist Songs', _getArtistSongs),
      _ApiItem('Get Artist Albums', _getArtistAlbums),
      _ApiItem('Get Artist Singles', _getArtistSingles),
      _ApiItem('Get Artist Videos', _getArtistVideos),
      _ApiItem('Get Album', _getAlbum),
      _ApiItem('Get Playlist', _getPlaylist),
      _ApiItem('Get Playlist Videos', _getPlaylistVideos),
      _ApiItem('Get Album Browse ID', _getAlbumBrowseId),
      _ApiItem('Get Podcast', _getPodcast),
      _ApiItem('Get Episode', _getEpisode),
      _ApiItem('Get User', _getUser),
      _ApiItem('Get User Videos', _getUserVideos),
      _ApiItem('Get User Playlists', _getUserPlaylists),
    ]),
    _ApiGroup('Explore', [
      _ApiItem('Mood Categories', _getMoodCategories),
      _ApiItem('Mood Playlists', null),
      _ApiItem('Charts', _getCharts),
      _ApiItem('New Releases', _getNewReleases),
    ]),
    _ApiGroup('Browse', [_ApiItem('Home (with chips)', null)]),
  ];

  static String _defaultInput(String label) {
    if (label.contains('User')) return 'UC44hbeRoCZVVMVg5z0FfIww';
    if (label.contains('Artist')) return 'UC4G-AJa7kn8oumI6TT2WXYw';
    if (label.contains('Album Browse')) return 'MPREb_4OAyJwegLNd';
    if (label.contains('Album')) return 'MPREb_4OAyJwegLNd';
    if (label.contains('Get Podcast')) {
      return 'MPSPPLIB4EaahNDRK3xJz5oWXc4ldziESr0Itd';
    }
    if (label.contains('Get Episode')) return '8zPGAj21oig';
    if (label.contains('Playlist')) {
      return 'PLtlNphvWba01n19M7iz1lDEBsEXufYVMB';
    }
    if (label.contains('Song') ||
        label.contains('Video') ||
        label.contains('Lyrics') ||
        label.contains('Next') ||
        label.contains('Watch') ||
        label.contains('Related')) {
      return 'LDY4Bf8Zwn8';
    }
    if (label.contains('Charts')) return 'ZZ';
    if (label.contains('Podcast') || label.contains('Episode')) {
      return 'serial';
    }
    if (label.contains('Profile')) return 'MrBeast';
    return 'Aurora Runaway';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text('YTMusic API Tester'),
      ),
      body: ListView(
        children: _groups.map((group) {
          return ExpansionTile(
            initiallyExpanded: group.name == 'Search',
            title: Text(
              group.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: group.items.map((item) {
              return ListTile(
                title: Text(item.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (item.label == 'Home (with chips)') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HomeTestPage()),
                    );
                  } else if (item.label == 'Mood Playlists') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MoodPlaylistsPage(),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ApiCallPage(
                          label: item.label,
                          defaultInput: _defaultInput(item.label),
                          call: item.call!,
                        ),
                      ),
                    );
                  }
                },
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

// ─── API Call Page ────────────────────────────────────────────────────────────

class ApiCallPage extends StatefulWidget {
  final String label;
  final String defaultInput;
  final Future<List<String>> Function(String input) call;

  const ApiCallPage({
    super.key,
    required this.label,
    required this.defaultInput,
    required this.call,
  });

  @override
  State<ApiCallPage> createState() => _ApiCallPageState();
}

class _ApiCallPageState extends State<ApiCallPage> {
  late final TextEditingController _ctrl;
  List<String>? _results;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.defaultInput);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
      _results = null;
    });
    try {
      final res = await widget.call(_ctrl.text.trim());
      setState(() {
        _results = res;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: Text(widget.label),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Query / ID',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _run(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _run,
                  child: const Text('Run'),
                ),
              ],
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_error != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          if (_results != null)
            Expanded(
              child: _results!.isEmpty
                  ? const Center(child: Text('No results'))
                  : ListView.separated(
                      itemCount: _results!.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final text = _results![i];
                        final id = _extractCopyableId(text);
                        return ListTile(
                          dense: true,
                          title: Text(
                            text,
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: id != null
                              ? IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  tooltip: 'Copia ID: $id',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: id));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Copiato: $id'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                )
                              : null,
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}

// ─── Home Test Page (with chips) ──────────────────────────────────────────────

class HomeTestPage extends StatefulWidget {
  const HomeTestPage({super.key});

  @override
  State<HomeTestPage> createState() => _HomeTestPageState();
}

class _HomeTestPageState extends State<HomeTestPage> {
  BrowseHomeResult? _home;
  List<HomeSection>? _filteredSections;
  BrowseChip? _selectedChip;
  bool _loading = true;
  String? _error;
  final List<String> _breadcrumb = ['Home'];

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome({
    String? params,
    String? browseId,
    String? title,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.getHome(params: params, browseId: browseId);
      if (!mounted) return;
      setState(() {
        if (browseId == null && params == null) {
          _home = r;
          _breadcrumb
            ..clear()
            ..add('Home');
        } else if (title != null) {
          _breadcrumb.add(title);
        }
        _filteredSections = r.sections;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openSection(HomeSection section) async {
    if (section.browseId != null) {
      await _loadHome(
        browseId: section.browseId,
        params: section.browseParams,
        title: section.title,
      );
      return;
    }
    if (section.shelfId != null) {
      await _loadHome(
        browseId: feMusicHome,
        params: section.shelfId,
        title: section.title,
      );
    }
  }

  void _popBreadcrumb() {
    if (_breadcrumb.length <= 1) return;
    setState(() => _breadcrumb.removeLast());
    if (_breadcrumb.length == 1) {
      setState(() => _filteredSections = _home?.sections);
    }
  }

  Future<void> _onChipTap(BrowseChip chip) async {
    setState(
      () => _selectedChip = _selectedChip?.title == chip.title ? null : chip,
    );
    final params = _selectedChip?.title == chip.title ? chip.params : null;
    if (params == null) {
      setState(() => _filteredSections = _home!.sections);
      return;
    }
    await _loadHome(params: chip.params);
  }

  void _showBackgroundPreviewDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Background Image Preview'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text('Failed to load image'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                url,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Copy URL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: Text(_breadcrumb.join(' › ')),
        leading: _breadcrumb.length > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _popBreadcrumb,
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final home = _home!;
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              FilterChip(
                label: Text(_selectedChip == null ? '● All' : 'All'),
                selected: _selectedChip == null,
                onSelected: (_) {
                  setState(() {
                    _selectedChip = null;
                    _filteredSections = home.sections;
                  });
                },
              ),
              const SizedBox(width: 8),
              ...home.chips.map(
                (chip) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(chip.title),
                    selected: _selectedChip?.title == chip.title,
                    onSelected: (_) => _onChipTap(chip),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _filteredSections!.isEmpty
              ? const Center(child: Text('No sections'))
              : ListView.separated(
                  itemCount: _filteredSections!.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final section = _filteredSections![i];
                    return ExpansionTile(
                      title: Text(section.title),
                      subtitle: Text(
                        [
                          '${section.contents.length} items',
                          if (section.shelfId != null)
                            'shelf: ${section.shelfId!.substring(0, 8)}…',
                          if (section.browseId != null) '→ ${section.browseId}',
                        ].join(' · '),
                        style: const TextStyle(fontSize: 11),
                      ),
                      onExpansionChanged: (_) {},
                      trailing:
                          (section.browseId != null || section.shelfId != null)
                          ? IconButton(
                              icon: const Icon(Icons.open_in_new, size: 18),
                              tooltip: 'Open shelf',
                              onPressed: () => _openSection(section),
                            )
                          : null,
                      children: section.contents.take(10).map((item) {
                        return ListTile(
                          dense: true,
                          title: Text(
                            item is SearchResult
                                ? _resultTitle(item)
                                : item.toString(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
        ),
        if (home.backgroundUrl != null)
          InkWell(
            onTap: () =>
                _showBackgroundPreviewDialog(context, home.backgroundUrl!),
            child: Container(
              height: 56,
              color: Colors.grey.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      home.backgroundUrl!,
                      height: 40,
                      width: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 40,
                        width: 70,
                        color: Colors.grey.shade800,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white30,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Background Image (Tap to preview)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          home.backgroundUrl!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.open_in_new,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Mood Playlists Page ──────────────────────────────────────────────────────

class MoodPlaylistsPage extends StatefulWidget {
  const MoodPlaylistsPage({super.key});

  @override
  State<MoodPlaylistsPage> createState() => _MoodPlaylistsPageState();
}

class _MoodPlaylistsPageState extends State<MoodPlaylistsPage> {
  MoodCategoriesResult? _categories;
  List<String>? _playlists;
  String? _selectedCategory;
  bool _loadingCategories = true;
  bool _loadingPlaylists = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _error = null;
    });
    try {
      final r = await _api.getMoodCategories();
      if (!mounted) return;
      setState(() {
        _categories = r;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingCategories = false;
      });
    }
  }

  Future<void> _loadPlaylists(MoodCategory category) async {
    setState(() {
      _loadingPlaylists = true;
      _error = null;
      _selectedCategory = category.title;
      _playlists = null;
    });
    try {
      final r = await _api.getMoodPlaylists(category.params);
      if (!mounted) return;
      setState(() {
        _playlists = r
            .map(
              (p) => '${p.name}${_explicitTag(p.isExplicit)} · ${p.playlistId}',
            )
            .toList();
        _loadingPlaylists = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingPlaylists = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewingPlaylists = _playlists != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: viewingPlaylists
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _playlists = null;
                  _selectedCategory = null;
                  _error = null;
                }),
              )
            : null,
        title: Text(
          _selectedCategory == null
              ? 'Mood Playlists'
              : 'Mood: $_selectedCategory',
        ),
      ),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _categories == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            )
          : viewingPlaylists
          ? Column(
              children: [
                if (_error != null)
                  Material(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: _playlists!.isEmpty
                      ? const Center(child: Text('No playlists'))
                      : ListView.builder(
                          itemCount: _playlists!.length,
                          itemBuilder: (_, i) => ListTile(
                            dense: true,
                            title: Text(
                              _playlists![i],
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                ),
              ],
            )
          : Column(
              children: [
                if (_error != null)
                  Material(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    children: _categories!.sections.entries.expand((section) {
                      return [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            section.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        ...section.value.map(
                          (c) => ListTile(
                            dense: true,
                            title: Text(c.title),
                            subtitle: Text(
                              c.params,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing:
                                _loadingPlaylists &&
                                    _selectedCategory == c.title
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: _loadingPlaylists
                                ? null
                                : () => _loadPlaylists(c),
                          ),
                        ),
                      ];
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Utilities ────────────────────────────────────────────────────────────────

/// Extracts a copyable ID from a result string.
/// Handles two formats:
///   "🎵 Name\n   Artist · <id>"  → returns the part after the last " · "
///   "videoId: <id>"              → returns the part after ": " when it has no spaces
String? _extractCopyableId(String text) {
  final dotIdx = text.lastIndexOf(' · ');
  if (dotIdx != -1) {
    final id = text.substring(dotIdx + 3).trim();
    if (id.isNotEmpty) return id;
  }
  final colonIdx = text.indexOf(': ');
  if (colonIdx != -1) {
    final value = text.substring(colonIdx + 2).trim();
    if (value.isNotEmpty && !value.contains(' ')) return value;
  }
  return null;
}

// ─── Helper types ─────────────────────────────────────────────────────────────

class _ApiGroup {
  final String name;
  final List<_ApiItem> items;
  const _ApiGroup(this.name, this.items);
}

class _ApiItem {
  final String label;
  final Future<List<String>> Function(String)? call;
  const _ApiItem(this.label, this.call);
}

// ─── API wrappers ─────────────────────────────────────────────────────────────

final _api = YTMusic();

Future<List<String>> _searchSongs(String q) async {
  final r = await _api.searchSongs(q);
  return r
      .map(
        (s) =>
            '🎵 ${s.name}${_explicitTag(s.isExplicit)}\n   ${s.artist.name} - ${s.videoId} - ${s.playCount} - ${s.albumId}',
      )
      .toList();
}

Future<List<String>> _searchVideos(String q) async {
  final r = await _api.searchVideos(q);
  return r
      .map(
        (v) =>
            '🎬 ${v.name}${_explicitTag(v.isExplicit)}\n   ${v.artist.name} - ${v.videoId} - ${v.viewCount ?? 'N/A'}',
      )
      .toList();
}

Future<List<String>> _searchArtists(String q) async {
  final r = await _api.searchArtists(q);
  return r
      .map(
        (a) =>
            '👤 ${a.name}\n   ${a.artistId} - ${a.monthlyListeners ?? 'N/A'}',
      )
      .toList();
}

Future<List<String>> _searchAlbums(String q) async {
  final r = await _api.searchAlbums(q);
  return r
      .map(
        (a) =>
            '💿 ${a.name}${_explicitTag(a.isExplicit)}\n   ${a.artist.name} · ${a.albumId}',
      )
      .toList();
}

Future<List<String>> _searchPlaylists(String q) async {
  final r = await _api.searchPlaylists(q);
  return r
      .map(
        (p) => '📋 ${p.name}${_explicitTag(p.isExplicit)}\n   ${p.playlistId}',
      )
      .toList();
}

Future<List<String>> _searchPodcasts(String q) async {
  final r = await _api.searchPodcasts(q);
  return r
      .map((p) => '🎙️ ${p.name}\n   ${p.author ?? 'N/A'} · ${p.browseId}')
      .toList();
}

Future<List<String>> _searchEpisodes(String q) async {
  final r = await _api.searchEpisodes(q);
  return r
      .map((e) => '🎧 ${e.name}\n   ${e.podcastName ?? 'N/A'} · ${e.videoId}')
      .toList();
}

Future<List<String>> _searchProfiles(String q) async {
  final r = await _api.searchProfiles(q);
  return r
      .map((p) => '👤 ${p.name} ${p.handle ?? ''}\n   ${p.browseId}')
      .toList();
}

Future<List<String>> _search(String q) async {
  final r = await _api.search(q);
  return r.map((s) => '[${s.type}] ${_resultTitle(s)}').toList();
}

String _resultTitle(SearchResult s) {
  if (s is SongDetailed) {
    return '${s.name}${_explicitTag(s.isExplicit)} — ${s.artist.name}';
  }
  if (s is VideoDetailed) {
    return '${s.name}${_explicitTag(s.isExplicit)} — ${s.artist.name}';
  }
  if (s is ArtistDetailed) return s.name;
  if (s is AlbumDetailed) {
    return '${s.name}${_explicitTag(s.isExplicit)} — ${s.artist.name}';
  }
  if (s is PlaylistDetailed) {
    return '${s.name}${_explicitTag(s.isExplicit)}';
  }
  if (s is PodcastDetailed) {
    return '${s.name} — ${s.author ?? s.browseId}';
  }
  if (s is EpisodeDetailed) {
    return '${s.name} — ${s.podcastName ?? s.videoId}';
  }
  if (s is ProfileDetailed) {
    return '${s.name} ${s.handle ?? ''} · ${s.browseId}';
  }
  return s.toString();
}

/// Renders the "🔞" marker used throughout this example app whenever a
/// model's `isExplicit` field (added in dart_ytmusic_api 1.5.0) is `true`.
String _explicitTag(bool isExplicit) => isExplicit ? ' 🔞' : '';

Future<List<String>> _suggestions(String q) async {
  return _api.getSearchSuggestions(q);
}

Future<List<String>> _getSong(String id) async {
  final s = await _api.getSong(id);
  return [
    'Title: ${s.name}',
    'Artist: ${s.artist.name}',
    'Duration: ${s.duration}s',
    'videoId: ${s.videoId}',
    'albumId: ${s.album?.albumId ?? 'N/A'}',
    'viewCount: ${s.viewCount ?? 'N/A'}',
    'channelId: ${s.channelId ?? 'N/A'}',
    'publishDate: ${s.publishDate ?? 'N/A'}',
    'category: ${s.category ?? 'N/A'}',
    'isExplicit: ${s.isExplicit}',
  ];
}

Future<List<String>> _getVideo(String id) async {
  final v = await _api.getVideo(id);
  return [
    'Title: ${v.name}',
    'Artist: ${v.artist.name}',
    'Duration: ${v.duration}s',
    'videoId: ${v.videoId}',
    'viewCount: ${v.viewCount ?? 'N/A'}',
    'publishDate: ${v.publishDate ?? 'N/A'}',
    'category: ${v.category ?? 'N/A'}',
    'uploadDate: ${v.uploadDate ?? 'N/A'}',
    'musicVideoType: ${v.musicVideoType ?? 'N/A'}',
    // NOTE: getVideo() only calls the /player endpoint, which does not
    // expose the "Explicit" badge, so this is currently always false.
    'isExplicit: ${v.isExplicit} (always false, see note in README)',
  ];
}

Future<List<String>> _getLyrics(String id) async {
  final l = await _api.getLyrics(id);
  if (l == null) return ['No lyrics found'];
  return l.split('\n');
}

Future<List<String>> _getTimedLyrics(String id) async {
  final r = await _api.getTimedLyrics(id);
  if (r == null) return ['No timed lyrics found'];
  return r.timedLyricsData.where((l) => l.lyricLine != null).map((l) {
    final ms = l.cueRange?.startTimeMilliseconds ?? 0;
    final sec = (ms / 1000).toStringAsFixed(1);
    return '[$sec s] ${l.lyricLine}';
  }).toList();
}

Future<List<String>> _getUpNexts(String id) async {
  final r = await _api.getUpNexts(id);
  return r
      .map(
        (u) =>
            '${u.title}${_explicitTag(u.isExplicit)}\n   ${u.artists.name} · ${u.videoId}',
      )
      .toList();
}

Future<List<String>> _getArtist(String id) async {
  final a = await _api.getArtist(id);
  return [
    'Name: ${a.name}',
    'artistId: ${a.artistId}',
    'channelId: ${a.channelId ?? 'N/A'}',
    'Top songs: ${a.topSongs.length}',
    'Albums: ${a.topAlbums.length}',
    'Singles: ${a.topSingles.length}',
    'Videos: ${a.topVideos.length}',
    'Featured on: ${a.featuredOn.length}',
    'Similar artists: ${a.similarArtists.length}',
    'Subscribers: ${a.subscriberCount ?? 'N/A'}',
    'Description: ${a.description ?? 'N/A'}',
    'Monthly Listeners: ${a.monthlyListeners ?? 'N/A'}',
    'Total views: ${a.totalViews ?? 'N/A'}',
    ...a.topVideos.take(5).map((v) => '  video: ${v.name} · ${v.videoId}'),
    ...a.similarArtists
        .take(5)
        .map((s) => '  similar: ${s.name} · ${s.artistId}'),
  ];
}

Future<List<String>> _getArtistSongs(String id) async {
  final r = await _api.getArtistSongs(id);
  return r
      .map((s) => '${s.name}${_explicitTag(s.isExplicit)} · ${s.videoId}')
      .toList();
}

Future<List<String>> _getArtistAlbums(String id) async {
  final r = await _api.getArtistAlbums(id);
  return r
      .map((a) => '${a.name}${_explicitTag(a.isExplicit)} · ${a.albumId}')
      .toList();
}

Future<List<String>> _getArtistSingles(String id) async {
  final r = await _api.getArtistSingles(id);
  return r
      .map((s) => '${s.name}${_explicitTag(s.isExplicit)} · ${s.albumId}')
      .toList();
}

Future<List<String>> _getAlbum(String id) async {
  final a = await _api.getAlbum(id);
  return [
    'Title: ${a.name}${_explicitTag(a.isExplicit)}',
    'Artist: ${a.artist.name}',
    'Year: ${a.year ?? 'N/A'}',
    'isExplicit: ${a.isExplicit}',
    'Description: ${a.description ?? 'N/A'}',
    'Tracks: ${a.songs.length}',
    ...a.songs.mapIndexed(
      (i, s) => '  ${i + 1}. ${s.name}${_explicitTag(s.isExplicit)}',
    ),
  ];
}

Future<List<String>> _getPlaylist(String id) async {
  final p = await _api.getPlaylist(id);
  return [
    'Title: ${p.name}${_explicitTag(p.isExplicit)}',
    'Artist: ${p.artist.name}',
    'Videos: ${p.videoCount}',
    'isExplicit: ${p.isExplicit}',
    'Description: ${p.description ?? 'N/A'}',
  ];
}

Future<List<String>> _getPlaylistVideos(String id) async {
  final r = await _api.getPlaylistVideos(id);
  return r
      .map((v) => '${v.name}${_explicitTag(v.isExplicit)} · ${v.videoId}')
      .toList();
}

Future<List<String>> _getWatchPlaylist(String id) async {
  final r = await _api.getWatchPlaylist(videoId: id);
  return [
    'playlistId: ${r.playlistId ?? 'N/A'}',
    'lyricsBrowseId: ${r.lyricsBrowseId ?? 'N/A'}',
    'relatedBrowseId: ${r.relatedBrowseId ?? 'N/A'}',
    'tracks: ${r.tracks.length}',
    ...r.tracks
        .take(20)
        .map(
          (t) =>
              '${t.title}${_explicitTag(t.isExplicit)} · ${t.artist.name} · ${t.videoId}',
        ),
  ];
}

Future<List<String>> _getSongRelated(String id) async {
  final watch = await _api.getWatchPlaylist(videoId: id);
  final relatedId = watch.relatedBrowseId;
  if (relatedId == null) return ['No related browseId for this video'];
  final sections = await _api.getSongRelated(relatedId);
  return sections
      .expand(
        (s) => [
          '— ${s.title} (${s.contents.length})',
          ...s.contents.take(8).map((c) => '  ${_resultTitleOrString(c)}'),
        ],
      )
      .toList();
}

String _resultTitleOrString(dynamic item) {
  if (item is SearchResult) return _resultTitle(item);
  if (item is String) return item;
  return item.toString();
}

Future<List<String>> _getArtistVideos(String id) async {
  final r = await _api.getArtistVideos(id);
  return r
      .map((v) => '${v.name}${_explicitTag(v.isExplicit)} · ${v.videoId}')
      .toList();
}

Future<List<String>> _getMoodCategories(String _) async {
  final r = await _api.getMoodCategories();
  return r.sections.entries
      .expand(
        (e) => [
          '— ${e.key}',
          ...e.value.map((c) => '  ${c.title} · ${c.params}'),
        ],
      )
      .toList();
}

Future<List<String>> _getCharts(String country) async {
  final r = await _api.getCharts(country: country.isEmpty ? 'ZZ' : country);
  return [
    'Country: ${r.countries.selected}',
    'Videos: ${r.videos.length}',
    if (r.daily != null) 'Daily: ${r.daily!.length}',
    if (r.weekly != null) 'Weekly: ${r.weekly!.length}',
    if (r.genres != null) 'Genres: ${r.genres!.length}',
    'Artists: ${r.artists.length}',
    ...r.videos.take(5).map((p) => '  chart: ${p.title} · ${p.playlistId}'),
    ...r.artists
        .take(5)
        .map(
          (a) =>
              '  artist: ${a.title}${a.rank != null ? ' #${a.rank}' : ''} · ${a.browseId}',
        ),
  ];
}

Future<List<String>> _getNewReleases(String _) async {
  final r = await _api.getNewReleases();
  return [
    'Albums: ${r.albums.length}',
    ...r.albums
        .take(10)
        .map(
          (a) => '  💿 ${a.name}${_explicitTag(a.isExplicit)} · ${a.albumId}',
        ),
    'Videos: ${r.videos.length}',
    ...r.videos.take(10).map((v) => '  🎬 ${v.name} · ${v.videoId}'),
  ];
}

Future<List<String>> _getAlbumBrowseId(String id) async {
  var audioId = id;
  if (id.startsWith('MPRE')) {
    final album = await _api.getAlbum(id);
    audioId = album.playlistId;
  }
  final browseId = await _api.getAlbumBrowseId(audioId);
  return ['audioPlaylistId: $audioId', 'browseId: ${browseId ?? 'N/A'}'];
}

Future<List<String>> _getPodcast(String id) async {
  final p = await _api.getPodcast(id, limit: 30);
  final desc = (p.description ?? 'N/A').replaceAll('\n', ' ');
  return [
    'Name: ${p.name}',
    'browseId: ${p.browseId}',
    'Author: ${p.author?.name ?? 'N/A'} (${p.author?.artistId ?? 'N/A'})',
    'Description: ${desc.length > 160 ? '${desc.substring(0, 160)}…' : desc}',
    'Episodes: ${p.episodes.length}',
    ...p.episodes
        .take(10)
        .map(
          (e) =>
              '  🎧 ${e.name}\n     ${e.duration ?? '?'} · ${e.date ?? ''} · ${e.videoId}',
        ),
  ];
}

Future<List<String>> _getEpisode(String id) async {
  final e = await _api.getEpisode(id);
  final desc = (e.description ?? 'N/A').replaceAll('\n', ' ');
  return [
    'Title: ${e.name}',
    'videoId: ${e.videoId}',
    'browseId: ${e.browseId}',
    'Date: ${e.date ?? 'N/A'}',
    'Duration: ${e.duration ?? 'N/A'}',
    'Podcast: ${e.podcastName ?? 'N/A'} · ${e.podcastId ?? 'N/A'}',
    'Description: ${desc.length > 200 ? '${desc.substring(0, 200)}…' : desc}',
  ];
}

Future<List<String>> _getUser(String id) async {
  final u = await _api.getUser(id);
  return [
    'Name: ${u.name}',
    'channelId: ${u.channelId}',
    'Subscribers: ${u.subscriberCount ?? 'N/A'}',
    'Videos: ${u.videos.length}',
    'Playlists: ${u.playlists.length}',
    'videosParams: ${u.videosParams ?? 'N/A'}',
    'playlistsParams: ${u.playlistsParams ?? 'N/A'}',
    ...u.videos.take(5).map((v) => '  video: ${v.name} · ${v.videoId}'),
    ...u.playlists
        .take(5)
        .map((p) => '  playlist: ${p.name} · ${p.playlistId}'),
  ];
}

Future<List<String>> _getUserVideos(String id) async {
  final u = await _api.getUser(id);
  if (u.videosParams == null) {
    return u.videos.map((v) => '${v.name} · ${v.videoId}').toList();
  }
  final r = await _api.getUserVideos(id, u.videosParams!);
  return r.map((v) => '${v.name} · ${v.videoId}').toList();
}

Future<List<String>> _getUserPlaylists(String id) async {
  final u = await _api.getUser(id);
  if (u.playlistsParams == null) {
    return u.playlists.map((p) => '${p.name} · ${p.playlistId}').toList();
  }
  final r = await _api.getUserPlaylists(id, u.playlistsParams!);
  return r.map((p) => '${p.name} · ${p.playlistId}').toList();
}

extension _Indexed<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int i, T e) f) sync* {
    var i = 0;
    for (final e in this) {
      yield f(i++, e);
    }
  }
}
