import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/filters.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

class PlaylistParser {
  static PlaylistFull parse(dynamic data, String playlistId) {
    final artist = traverse(data, ["tabs", "straplineTextOne"]);

    return PlaylistFull(
      type: "PLAYLIST",
      playlistId: playlistId,
      name: traverseString(data, ["tabs", "title", "text"]) ?? '',
      artist: ArtistBasic(
        name: traverseString(artist, ["text"]) ?? '',
        artistId: traverseString(artist, ["browseId"]),
      ),
      videoCount: _parseVideoCount(
        traverseList(data, ["tabs", "secondSubtitle", "text"]),
      ),
      thumbnails: traverseList(data, [
        "tabs",
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
    );
  }

  static int _parseVideoCount(List<dynamic> runs) {
    final strings = runs.map((r) => r.toString()).toList();

    final trackKeywords = [
      'track',
      'song',
      'video',
      'brano',
      'tracc',
      'canzon',
      'titel',
      'cancion',
      'tema',
      'faix',
      'músic',
      'music',
      'titre',
      'chanson',
    ];

    // 1. Try to find a run containing track keywords
    for (final run in strings) {
      final lower = run.toLowerCase();
      if (trackKeywords.any((kw) => lower.contains(kw))) {
        final digits = RegExp(
          r'\d+',
        ).allMatches(run).map((m) => m.group(0)).join('');
        if (digits.isNotEmpty) {
          return int.tryParse(digits) ?? 0;
        }
      }
    }

    // 2. Fallback: filter out separators, views, and durations
    final durationKeywords = [
      'hour',
      'ore',
      'min',
      'sec',
      'day',
      'giorn',
      'week',
      'settiman',
      'month',
      'mes',
      'year',
      'ann',
      'stund',
      'tag',
      'woch',
      'jahr',
      'durée',
      'temps',
      'temp',
      '+',
      'over',
      'oltre',
      'mehr',
      'más',
      'plus',
      'mais',
    ];
    final viewKeywords = [
      'view',
      'visualiz',
      'aufruf',
      'reproducc',
      'vista',
      'vue',
      'exib',
    ];

    for (final run in strings) {
      final trimmed = run.trim();
      if (trimmed == '•' || trimmed.isEmpty) continue;

      final lower = trimmed.toLowerCase();
      if (viewKeywords.any((kw) => lower.contains(kw))) continue;
      if (durationKeywords.any((kw) => lower.contains(kw))) continue;

      // First remaining run that contains digits is likely the track count
      final digits = RegExp(
        r'\d+',
      ).allMatches(trimmed).map((m) => m.group(0)).join('');
      if (digits.isNotEmpty) {
        return int.tryParse(digits) ?? 0;
      }
    }

    return 0;
  }

  static PlaylistDetailed parseSearchResult(dynamic item) {
    final columns = traverseList(item, [
      "flexColumns",
      "runs",
    ]).expand((e) => e is List ? e : [e]).toList();

    // No specific way to identify the title
    final title = columns[0];
    final artist = columns.firstWhere(
      isArtist,
      orElse: () =>
          columns.length > 2 ? columns[3] : AlbumBasic(albumId: '', name: ''),
    );

    return PlaylistDetailed(
      type: "PLAYLIST",
      playlistId: traverseString(item, ["overlay", "playlistId"]) ?? '',
      name: traverseString(title, ["text"]) ?? '',
      artist: ArtistBasic(
        name: traverseString(artist, ["text"]) ?? '',
        artistId: traverseString(artist, ["browseId"]),
      ),
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
    );
  }

  static PlaylistDetailed parseArtistFeaturedOn(
    dynamic item,
    ArtistBasic artistBasic,
  ) {
    return PlaylistDetailed(
      type: "PLAYLIST",
      playlistId:
          traverseString(item, ["navigationEndpoint", "browseId"]) ?? '',
      name: traverseString(item, ["runs", "text"]) ?? '',
      artist: artistBasic,
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
    );
  }

  static PlaylistDetailed parseHomeSection(dynamic item) {
    final artist = traverse(item, ["subtitle", "runs"]);

    return PlaylistDetailed(
      type: "PLAYLIST",
      playlistId:
          traverseString(item, ["navigationEndpoint", "playlistId"]) ?? '',
      name: traverseString(item, ["runs", "text"]) ?? '',
      artist: ArtistBasic(
        name: traverseString(artist, ["text"]) ?? '',
        artistId: traverseString(artist, ["browseId"]),
      ),
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
    );
  }
}
