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
      _ApiItem('Search (generic)', _search),
      _ApiItem('Suggestions', _suggestions),
    ]),
    _ApiGroup('Get by ID', [
      _ApiItem('Get Song', _getSong),
      _ApiItem('Get Video', _getVideo),
      _ApiItem('Get Lyrics', _getLyrics),
      _ApiItem('Get Timed Lyrics', _getTimedLyrics),
      _ApiItem('Get Up Nexts', _getUpNexts),
      _ApiItem('Get Artist', _getArtist),
      _ApiItem('Get Artist Songs', _getArtistSongs),
      _ApiItem('Get Artist Albums', _getArtistAlbums),
      _ApiItem('Get Artist Singles', _getArtistSingles),
      _ApiItem('Get Album', _getAlbum),
      _ApiItem('Get Playlist', _getPlaylist),
      _ApiItem('Get Playlist Videos', _getPlaylistVideos),
    ]),
    _ApiGroup('Browse', [_ApiItem('Home (with chips)', null)]),
  ];

  static String _defaultInput(String label) {
    if (label.contains('Artist')) return 'UC4G-AJa7kn8oumI6TT2WXYw';
    if (label.contains('Album')) return 'MPREb_4OAyJwegLNd';
    if (label.contains('Playlist')) {
      return 'PLtlNphvWba01n19M7iz1lDEBsEXufYVMB';
    }
    if (label.contains('Song') ||
        label.contains('Video') ||
        label.contains('Lyrics') ||
        label.contains('Next')) {
      return 'LDY4Bf8Zwn8';
    }
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

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome({String? params}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.getHome(params: params);
      if (!mounted) return;
      setState(() {
        _home ??= r;
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
        title: const Text('Home with chips'),
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
            onTap: () => _showBackgroundPreviewDialog(context, home.backgroundUrl!),
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
                        child: const Icon(Icons.broken_image, color: Colors.white30, size: 20),
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
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          home.backgroundUrl!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new, color: Colors.white70, size: 20),
                ],
              ),
            ),
          ),
      ],
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
            '🎵 ${s.name}\n   ${s.artist.name} - ${s.videoId} - ${s.playCount} - ${s.albumId}',
      )
      .toList();
}

Future<List<String>> _searchVideos(String q) async {
  final r = await _api.searchVideos(q);
  return r
      .map(
        (v) =>
            '🎬 ${v.name}\n   ${v.artist.name} - ${v.videoId} - ${v.viewCount ?? 'N/A'}',
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
      .map((a) => '💿 ${a.name}\n   ${a.artist.name} · ${a.albumId}')
      .toList();
}

Future<List<String>> _searchPlaylists(String q) async {
  final r = await _api.searchPlaylists(q);
  return r.map((p) => '📋 ${p.name}\n   ${p.playlistId}').toList();
}

Future<List<String>> _search(String q) async {
  final r = await _api.search(q);
  return r.map((s) => '[${s.type}] ${_resultTitle(s)}').toList();
}

String _resultTitle(SearchResult s) {
  if (s is SongDetailed) return '${s.name} — ${s.artist.name}';
  if (s is VideoDetailed) return '${s.name} — ${s.artist.name}';
  if (s is ArtistDetailed) return s.name;
  if (s is AlbumDetailed) return '${s.name} — ${s.artist.name}';
  if (s is PlaylistDetailed) return s.name;
  return s.toString();
}

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
      .map((u) => '${u.title}\n   ${u.artists.name} · ${u.videoId}')
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
    'Subscribers: ${a.subscriberCount ?? 'N/A'}',
    'Description: ${a.description ?? 'N/A'}',
    'Monthly Listeners: ${a.monthlyListeners ?? 'N/A'}',
    'Total views: ${a.totalViews ?? 'N/A'}',
  ];
}

Future<List<String>> _getArtistSongs(String id) async {
  final r = await _api.getArtistSongs(id);
  return r.map((s) => '${s.name} · ${s.videoId}').toList();
}

Future<List<String>> _getArtistAlbums(String id) async {
  final r = await _api.getArtistAlbums(id);
  return r.map((a) => '${a.name} · ${a.albumId}').toList();
}

Future<List<String>> _getArtistSingles(String id) async {
  final r = await _api.getArtistSingles(id);
  return r.map((s) => '${s.name} · ${s.albumId}').toList();
}

Future<List<String>> _getAlbum(String id) async {
  final a = await _api.getAlbum(id);
  return [
    'Title: ${a.name}',
    'Artist: ${a.artist.name}',
    'Year: ${a.year ?? 'N/A'}',
    'Tracks: ${a.songs.length}',
    ...a.songs.mapIndexed((i, s) => '  ${i + 1}. ${s.name}'),
  ];
}

Future<List<String>> _getPlaylist(String id) async {
  final p = await _api.getPlaylist(id);
  return [
    'Title: ${p.name}',
    'Artist: ${p.artist.name}',
    'Videos: ${p.videoCount}',
  ];
}

Future<List<String>> _getPlaylistVideos(String id) async {
  final r = await _api.getPlaylistVideos(id);
  return r.map((v) => '${v.name} · ${v.videoId}').toList();
}

extension _Indexed<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int i, T e) f) sync* {
    var i = 0;
    for (final e in this) {
      yield f(i++, e);
    }
  }
}
