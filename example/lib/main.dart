import 'package:flutter/material.dart';
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
    ]),
    _ApiGroup('Browse', [_ApiItem('Home Sections', (_) => _getHomeSections())]),
  ];

  static String _defaultInput(String label) {
    if (label.contains('Artist')) return 'UC4G-AJa7kn8oumI6TT2WXYw';
    if (label.contains('Album')) return 'MPREb_4OAyJwegLNd';
    if (label.contains('Playlist')) {
      return 'RDCLAK5uy_nfs_t4FUu00E5ED6lveEBBX1VMYe1mFjk';
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ApiCallPage(
                        label: item.label,
                        defaultInput: _defaultInput(item.label),
                        call: item.call,
                      ),
                    ),
                  );
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
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: Text(
                          _results![i],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

// ─── Helper types ─────────────────────────────────────────────────────────────

class _ApiGroup {
  final String name;
  final List<_ApiItem> items;
  const _ApiGroup(this.name, this.items);
}

class _ApiItem {
  final String label;
  final Future<List<String>> Function(String) call;
  const _ApiItem(this.label, this.call);
}

// ─── API wrappers ─────────────────────────────────────────────────────────────

final _api = YTMusic();

Future<List<String>> _searchSongs(String q) async {
  final r = await _api.searchSongs(q);
  return r
      .map((s) => '🎵 ${s.name}\n   ${s.artist.name} · ${s.videoId}')
      .toList();
}

Future<List<String>> _searchVideos(String q) async {
  final r = await _api.searchVideos(q);
  return r
      .map((v) => '🎬 ${v.name}\n   ${v.artist.name} · ${v.videoId}')
      .toList();
}

Future<List<String>> _searchArtists(String q) async {
  final r = await _api.searchArtists(q);
  return r.map((a) => '👤 ${a.name}\n   ${a.artistId}').toList();
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
  ];
}

Future<List<String>> _getVideo(String id) async {
  final v = await _api.getVideo(id);
  return [
    'Title: ${v.name}',
    'Artist: ${v.artist.name}',
    'Duration: ${v.duration}s',
    'videoId: ${v.videoId}',
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
    'Top songs: ${a.topSongs.length}',
    'Albums: ${a.topAlbums.length}',
    'Singles: ${a.topSingles.length}',
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

Future<List<String>> _getHomeSections() async {
  final r = await _api.getHomeSections();
  final lines = <String>[];
  for (final section in r) {
    lines.add('── ${section.title} (${section.contents.length} items)');
    for (final item in section.contents.take(3)) {
      lines.add('   ${_resultTitle(item as SearchResult)}');
    }
  }
  return lines;
}

extension _Indexed<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int i, T e) f) sync* {
    var i = 0;
    for (final e in this) {
      yield f(i++, e);
    }
  }
}
