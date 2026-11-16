import 'package:dart_ytmusic_api/parsers/parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/artists.dart';
import 'package:dart_ytmusic_api/utils/filters.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

class SongParser {
  static SongFull parse(
    dynamic data, {
    AlbumBasic? album,
    bool isExplicit = false,
    List<ArtistBasic>? artists,
  }) {
    final parsedArtists = (artists != null && artists.isNotEmpty)
        ? artists
        : [
            ArtistBasic(
              name: traverseString(data, ["author"]) ?? '',
              artistId: traverseString(data, ["videoDetails", "channelId"]),
            ),
          ];
    return SongFull(
      type: "SONG",
      videoId: traverseString(data, ["videoDetails", "videoId"]) ?? '',
      name: traverseString(data, ["videoDetails", "title"]) ?? '',
      artists: parsedArtists,
      duration: int.parse(
        traverseString(data, ["videoDetails", "lengthSeconds"]) ?? '0',
      ),
      thumbnails: traverseList(data, [
        "videoDetails",
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      formats: traverseList(data, ["streamingData", "formats"]),
      adaptiveFormats: traverseList(data, ["streamingData", "adaptiveFormats"]),
      viewCount: int.tryParse(
        traverseString(data, ["videoDetails", "viewCount"]) ?? '',
      ),
      channelId: traverseString(data, ["videoDetails", "channelId"]),
      publishDate: traverseString(data, [
        "microformat",
        "microformatDataRenderer",
        "publishDate",
      ]),
      category: traverseString(data, [
        "microformat",
        "microformatDataRenderer",
        "category",
      ]),
      album: album,
      isExplicit: isExplicit,
    );
  }

  static String? _videoIdFromItem(dynamic item) {
    return traverseString(item, ["playlistItemData", "videoId"]) ??
        traverseString(item, ["playNavigationEndpoint", "videoId"]) ??
        traverseString(item, [
          "navigationEndpoint",
          "watchEndpoint",
          "videoId",
        ]);
  }

  /// Title run with `musicVideoType`, else first flex-column text (grey-out rows).
  static dynamic _titleFromColumns(List<dynamic> columns) {
    final titled = columns.firstWhere(isTitle, orElse: () => null);
    if (titled != null) return titled;
    return columns.isNotEmpty ? columns[0] : null;
  }

  static List<ArtistBasic> _artistsFromColumns(
    List<dynamic> columns, {
    dynamic fallback,
  }) {
    final artists = parseArtistRuns(columns);
    if (artists.isNotEmpty) return artists;
    if (fallback == null) return const [];
    return [
      ArtistBasic(
        name: traverseString(fallback, ["text"]) ?? '',
        artistId: traverseString(fallback, ["browseId"]),
      ),
    ];
  }

  /// Second-column text when no artist browse endpoint is present (grey-out).
  static List<ArtistBasic> _albumTrackArtists(
    dynamic item,
    List<ArtistBasic> albumArtists,
  ) {
    final trackArtists = parseArtistsFromFlexColumns(item);
    if (trackArtists.isNotEmpty) return trackArtists;

    final flexColumns = item is Map ? item['flexColumns'] : null;
    if (flexColumns is List && flexColumns.length > 1) {
      final secondCol =
          flexColumns[1]['musicResponsiveListItemFlexColumnRenderer'];
      final runs = secondCol?['text']?['runs'] as List<dynamic>?;
      if (runs != null && runs.isNotEmpty) {
        final name = traverseString(runs[0], ['text']) ?? '';
        if (name.isNotEmpty) {
          return [
            ArtistBasic(
              name: name,
              artistId: traverseString(runs[0], ['browseId']),
            ),
          ];
        }
      }
    }
    return albumArtists;
  }

  static SongDetailed parseSearchResult(dynamic item) {
    final columns = traverseList(item, [
      "flexColumns",
      "runs",
    ]).expand((e) => e is Iterable ? e : [e]).toList();

    // Two-row home/explore cards have title/subtitle, not flexColumns.
    if (columns.isEmpty) {
      return parseHomeTwoRow(item);
    }

    final title = _titleFromColumns(columns);
    final album = columns.firstWhere(isAlbum, orElse: () => null);
    final duration = columns.firstWhere(
      (item) => isDuration(item) && item != title,
      orElse: () => null,
    );
    final artists = _artistsFromColumns(
      columns,
      fallback: columns.length > 3 ? columns[3] : null,
    );

    String? playCount;
    String? albumId;
    final flexColumns = item['flexColumns'] as List<dynamic>?;
    if (flexColumns != null && flexColumns.length > 2) {
      final thirdCol =
          flexColumns[2]['musicResponsiveListItemFlexColumnRenderer'];
      final runs = thirdCol?['text']?['runs'] as List<dynamic>?;
      if (runs != null && runs.isNotEmpty) {
        playCount = runs[0]['text'] as String?;
      }
    }

    if (album != null) {
      albumId = traverseString(album, ["browseId"]);
    }

    return SongDetailed(
      type: "SONG",
      videoId: _videoIdFromItem(item) ?? '',
      name: traverseString(title, ["text"]) ?? '',
      artists: artists,
      album: album != null
          ? AlbumBasic(
              name: traverseString(album, ["text"]) ?? '',
              albumId: albumId ?? '',
            )
          : null,
      duration: Parser.parseDuration(duration?['text']),
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      playCount: playCount,
      albumId: albumId,
      isExplicit: hasExplicitBadge(item),
      isPlayable: !isGreyedOutItem(item),
    );
  }

  /// Home carousel song cards (`musicTwoRowItemRenderer`) without flex columns.
  static SongDetailed parseHomeTwoRow(dynamic item) {
    final artists = parseArtistsFromSubtitle(item);
    final subtitleRuns = traverseList(item, ['subtitle', 'runs']);
    final fallbackName = subtitleRuns.isNotEmpty
        ? traverseString(subtitleRuns.first, ['text'])
        : null;
    return SongDetailed(
      type: 'SONG',
      videoId: _videoIdFromItem(item) ?? '',
      name: traverseString(item, ['title', 'text']) ?? '',
      artists: artists.isNotEmpty
          ? artists
          : [
              if (fallbackName != null && fallbackName.isNotEmpty)
                ArtistBasic(name: fallbackName),
            ],
      duration: null,
      thumbnails: traverseList(item, [
        'thumbnails',
      ]).map((t) => ThumbnailFull.fromMap(t)).toList(),
      isExplicit: hasExplicitBadge(item),
      isPlayable: !isGreyedOutItem(item),
    );
  }

  static SongDetailed parseArtistSong(dynamic item, ArtistBasic artistBasic) {
    final columns = traverseList(item, [
      "flexColumns",
      "runs",
    ]).expand((e) => e is List ? e : [e]).toList();

    final title = _titleFromColumns(columns);
    final album = columns.firstWhere(isAlbum, orElse: () => null);
    final duration = columns.firstWhere(isDuration, orElse: () => null);
    final cleanedDuration = duration?['text']?.replaceAll(
      RegExp(r'[^0-9:]'),
      '',
    );

    return SongDetailed(
      type: "SONG",
      videoId: _videoIdFromItem(item) ?? '',
      name: traverseString(title, ["text"]) ?? '',
      artists: artistsOrFallback(parseArtistRuns(columns), artistBasic),
      album: album != null
          ? AlbumBasic(
              name: traverseString(album, ["text"]) ?? '',
              albumId: traverseString(album, ["browseId"]) ?? '',
            )
          : null,
      duration: Parser.parseDuration(cleanedDuration),
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      isExplicit: hasExplicitBadge(item),
      isPlayable: !isGreyedOutItem(item),
    );
  }

  static SongDetailed parseArtistTopSong(
    dynamic item,
    ArtistBasic artistBasic,
  ) {
    final columns = traverseList(item, [
      "flexColumns",
      "runs",
    ]).expand((e) => e is List ? e : [e]).toList();

    final title = _titleFromColumns(columns);
    final album = columns.firstWhere(isAlbum, orElse: () => null);
    // Flattened runs put the collaboration separator (" & ") at index 2.
    // The play count is its own flex column, for example "2.3M plays".
    final playCount = _playCountFromFlexColumns(item);

    String? albumId;
    if (album != null) {
      albumId = traverseString(album, ["browseId"]);
    }

    return SongDetailed(
      type: "SONG",
      videoId: _videoIdFromItem(item) ?? '',
      name: traverseString(title, ["text"]) ?? '',
      artists: artistsOrFallback(parseArtistRuns(columns), artistBasic),
      album: album != null
          ? AlbumBasic(
              name: traverseString(album, ["text"]) ?? '',
              albumId: albumId ?? '',
            )
          : null,
      duration: null,
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      playCount: playCount,
      albumId: albumId,
      isExplicit: hasExplicitBadge(item),
      isPlayable: !isGreyedOutItem(item),
    );
  }

  static final RegExp _playCountPattern = RegExp(
    r'^[\d.,]+\s*(?:[KMB]|mln|mila|million|billion)?\s*'
    r'(?:plays|riproduzioni|views?|visualizzazioni)\b',
    caseSensitive: false,
  );

  /// Play-count column on an artist top-song row.
  ///
  /// Collaboration credits split " & " into its own run, so the flattened
  /// run list cannot be indexed. A play-count column is a single run.
  static String? _playCountFromFlexColumns(dynamic item) {
    if (item is! Map) return null;
    final flexColumns = item['flexColumns'];
    if (flexColumns is! List) return null;
    for (final renderer in flexColumns) {
      if (renderer is! Map) continue;
      final column = renderer['musicResponsiveListItemFlexColumnRenderer'];
      if (column is! Map) continue;
      final runs = column['text']?['runs'];
      if (runs is! List || runs.length != 1 || runs.first is! Map) continue;
      final text = runs.first['text'];
      if (text is! String) continue;
      final trimmed = text.trim();
      if (_playCountPattern.hasMatch(trimmed)) return trimmed;
    }
    return null;
  }

  static SongDetailed parseAlbumSong(
    dynamic item,
    List<ArtistBasic> albumArtists,
    AlbumBasic albumBasic,
    List<ThumbnailFull> thumbnails,
  ) {
    final columns = traverseList(item, [
      "flexColumns",
      "runs",
    ]).expand((e) => e is Iterable ? e : [e]).toList();
    final title = _titleFromColumns(columns);
    final duration = traverseList(item, [
      "fixedColumns",
      "runs",
    ]).firstWhere(isDuration, orElse: () => null);

    return SongDetailed(
      type: "SONG",
      videoId: _videoIdFromItem(item) ?? '',
      name: traverseString(title, ["text"]) ?? '',
      artists: _albumTrackArtists(item, albumArtists),
      album: albumBasic,
      duration: Parser.parseDuration(duration?['text']),
      thumbnails: thumbnails,
      isExplicit: hasExplicitBadge(item),
      isPlayable: !isGreyedOutItem(item),
    );
  }

  static SongDetailed parseHomeSection(dynamic item) {
    if (item is Map && item.containsKey('musicTwoRowItemRenderer')) {
      return parseHomeTwoRow(item['musicTwoRowItemRenderer'] ?? item);
    }
    return parseSearchResult(item);
  }
}
