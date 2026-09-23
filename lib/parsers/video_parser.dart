import 'package:dart_ytmusic_api/parsers/parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/artists.dart';
import 'package:dart_ytmusic_api/utils/filters.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

class VideoParser {
  static VideoFull parse(
    dynamic data, {
    bool isExplicit = false,
    List<ArtistBasic>? artists,
  }) {
    return VideoFull(
      type: "VIDEO",
      videoId: traverseString(data, ["videoDetails", "videoId"]) ?? '',
      name: traverseString(data, ["videoDetails", "title"]) ?? '',
      artists: artists != null && artists.isNotEmpty
          ? artists
          : [
              ArtistBasic(
                artistId: traverseString(data, ["videoDetails", "channelId"]),
                name: traverseString(data, ["author"]) ?? '',
              ),
            ],
      duration: int.parse(
        traverseString(data, ["videoDetails", "lengthSeconds"]) ?? '0',
      ),
      thumbnails: traverseList(data, [
        "videoDetails",
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      unlisted: traverse(data, ["unlisted"]),
      familySafe: traverse(data, ["familySafe"]),
      paid: traverse(data, ["paid"]),
      tags: traverseList(data, ["tags"]).whereType<String>().toList(),
      viewCount: int.tryParse(
        traverseString(data, ["videoDetails", "viewCount"]) ?? '',
      ),
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
      uploadDate: traverseString(data, [
        "microformat",
        "microformatDataRenderer",
        "uploadDate",
      ]),
      musicVideoType: traverseString(data, ["videoDetails", "musicVideoType"]),
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

  static VideoDetailed parseSearchResult(dynamic item) {
    final columns = traverseList(item, [
      "flexColumns",
      "runs",
    ]).expand((e) => e is Iterable ? e : [e]).toList();

    final title = columns.firstWhere(
      isTitle,
      orElse: () => columns.isNotEmpty ? columns[0] : null,
    );
    final duration = columns.firstWhere(isDuration, orElse: () => null);
    final parsedArtists = parseArtistRuns(columns);
    final artists = parsedArtists.isNotEmpty
        ? parsedArtists
        : [
            ArtistBasic(
              artistId: traverseString(columns.length > 1 ? columns[1] : null, [
                "browseId",
              ]),
              name:
                  traverseString(columns.length > 1 ? columns[1] : null, [
                    "text",
                  ]) ??
                  '',
            ),
          ];

    String? viewCount;
    final flexColumns = item['flexColumns'] as List<dynamic>?;
    if (flexColumns != null && flexColumns.length > 1) {
      final secondCol =
          flexColumns[1]['musicResponsiveListItemFlexColumnRenderer'];
      final runs = secondCol?['text']?['runs'] as List<dynamic>?;
      if (runs != null && runs.length > 2) {
        viewCount = runs[2]['text'] as String?;
      }
    }

    return VideoDetailed(
      type: "VIDEO",
      videoId: _videoIdFromItem(item) ?? '',
      name: traverseString(title, ["text"]) ?? '',
      artists: artists,
      duration: Parser.parseDuration(duration?['text']),
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      viewCount: viewCount,
      isExplicit: hasExplicitBadge(item),
      isPlayable: !isGreyedOutItem(item),
    );
  }

  static VideoDetailed parseArtistTopVideo(
    dynamic item,
    ArtistBasic artistBasic,
  ) {
    return VideoDetailed(
      type: "VIDEO",
      videoId: traverseString(item, ["videoId"]) ?? '',
      name: traverseString(item, ["runs", "text"]) ?? '',
      artists: artistsOrFallback(parseArtistsFromSubtitle(item), artistBasic),
      duration: null,
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      isExplicit: hasExplicitBadge(item),
      isPlayable: !isGreyedOutItem(item),
    );
  }

  static VideoDetailed? parsePlaylistVideo(dynamic item) {
    final flexColumns = traverseList(item, [
      'flexColumns',
      'runs',
    ]).expand((e) => e is Iterable ? e : [e]).toList();
    final fixedColumns = traverseList(item, [
      'fixedColumns',
      'runs',
    ]).expand((e) => e is Iterable ? e : [e]).toList();

    final title = flexColumns.firstWhere(
      isTitle,
      orElse: () => flexColumns.isNotEmpty ? flexColumns[0] : null,
    );
    final duration = fixedColumns.firstWhere(isDuration, orElse: () => null);
    final parsedArtists = parseArtistRuns(flexColumns);
    final artists = parsedArtists.isNotEmpty
        ? parsedArtists
        : [
            ArtistBasic(
              name:
                  traverseString(
                    flexColumns.length > 1 ? flexColumns[1] : null,
                    ["text"],
                  ) ??
                  '',
              artistId: traverseString(
                flexColumns.length > 1 ? flexColumns[1] : null,
                ["browseId"],
              ),
            ),
          ];

    final videoId =
        _videoIdFromItem(item) ??
        () {
          final firstThumb = traverseList(item, ["thumbnails"]).firstOrNull;
          final url = firstThumb is Map && firstThumb['url'] is String
              ? firstThumb['url'] as String
              : '';
          return RegExp(
            r"https:\/\/i\.ytimg\.com\/vi\/(.+)\/",
          ).firstMatch(url)?.group(1);
        }();

    if (videoId == null || videoId.isEmpty) {
      return null;
    }

    return VideoDetailed(
      type: "VIDEO",
      videoId: videoId,
      name: traverseString(title, ["text"]) ?? '',
      artists: artists,
      duration: Parser.parseDuration(
        duration is Map ? duration['text'] : duration?.toString(),
      ),
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      isExplicit: hasExplicitBadge(item),
      isPlayable: !isGreyedOutItem(item),
    );
  }
}
