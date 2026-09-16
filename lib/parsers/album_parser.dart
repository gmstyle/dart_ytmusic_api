import 'package:dart_ytmusic_api/parsers/song_parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/artists.dart';
import 'package:dart_ytmusic_api/utils/filters.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

class AlbumParser {
  static AlbumFull parse(dynamic data, String albumId) {
    final albumBasic = AlbumBasic(
      albumId: albumId,
      name: traverseString(data, ["tabs", "title", "text"]) ?? '',
    );

    final artists = parseArtistsFromStrapline(data);
    final albumArtists = artists.isNotEmpty
        ? artists
        : [
            ArtistBasic(
              artistId: traverseString(data, [
                "tabs",
                "straplineTextOne",
                "browseId",
              ]),
              name:
                  traverseString(data, ["tabs", "straplineTextOne", "text"]) ??
                  '',
            ),
          ];

    final thumbnails = traverseList(data, [
      "background",
      "thumbnails",
    ]).map((item) => ThumbnailFull.fromMap(item)).toList();

    return AlbumFull(
      name: albumBasic.name,
      type: "ALBUM",
      albumId: albumId,
      playlistId:
          traverseString(data, ["musicPlayButtonRenderer", "playlistId"]) ?? '',
      artists: albumArtists,
      year: processYear(traverseList(data, ["tabs", "subtitle", "text"]).last),
      thumbnails: thumbnails,
      songs: traverseList(data, ["musicResponsiveListItemRenderer"])
          .map(
            (item) => SongParser.parseAlbumSong(
              item,
              albumArtists,
              albumBasic,
              thumbnails,
            ),
          )
          .toList(),
      relatedReleases: _parseRelatedReleases(data),
      isExplicit: hasExplicitBadge(
        traverse(data, ["musicResponsiveHeaderRenderer"]),
      ),
      description: _extractDescription(data),
    );
  }

  static String? _extractDescription(dynamic data) {
    final descriptionShelf = traverseList(data, [
      "musicDescriptionShelfRenderer",
    ]);
    if (descriptionShelf.isEmpty) return null;
    final runs =
        descriptionShelf.first['description']?['runs'] as List<dynamic>?;
    if (runs == null) return null;
    return runs.map((r) => r['text']?.toString() ?? '').join();
  }

  static List<AlbumDetailed> _parseRelatedReleases(dynamic data) {
    final carousels = traverseList(data, ["musicCarouselShelfRenderer"]);
    final result = <AlbumDetailed>[];
    for (final carousel in carousels) {
      final contents = carousel['contents'];
      if (contents is! List) continue;
      for (final item in contents) {
        final renderer = item['musicTwoRowItemRenderer'];
        if (renderer != null) {
          result.add(parseRelatedRelease(renderer));
        }
      }
    }
    return result;
  }

  static AlbumDetailed parseRelatedRelease(dynamic item) {
    final subtitleRuns = traverseList(item, [
      "subtitle",
      "runs",
    ]).expand((e) => e is List ? e : [e]).toList();
    final artists = parseArtistRuns(subtitleRuns);

    final albumId =
        traverseString(item, ["navigationEndpoint", "browseId"]) ?? '';
    final playlistId =
        traverseString(item, ["watchPlaylistEndpoint", "playlistId"]) ?? '';

    return AlbumDetailed(
      type: "ALBUM",
      albumId: albumId,
      playlistId: playlistId,
      name: traverseString(item, ["title", "text"]) ?? '',
      artists: artists,
      year: null,
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      isExplicit: hasExplicitBadge(item),
    );
  }

  static AlbumDetailed parseSearchResult(dynamic item) {
    final columns = traverseList(item, [
      "flexColumns",
      "runs",
    ]).expand((e) => e is List ? e : [e]).toList();

    final title = columns[0];
    final parsedArtists = parseArtistRuns(columns);
    final artists = parsedArtists.isNotEmpty
        ? parsedArtists
        : [
            ArtistBasic(
              name:
                  traverseString(columns.length > 3 ? columns[3] : null, [
                    "text",
                  ]) ??
                  '',
              artistId: traverseString(columns.length > 3 ? columns[3] : null, [
                "browseId",
              ]),
            ),
          ];
    final playlistId =
        traverseString(item, ["overlay", "playlistId"]) ??
        traverseString(item, ["thumbnailOverlay", "playlistId"]);

    return AlbumDetailed(
      type: "ALBUM",
      albumId: traverseList(item, ["browseId"]).last,
      playlistId: playlistId ?? '',
      artists: artists,
      year: processYear(columns.last?['text']),
      name: traverseString(title, ["text"]) ?? '',
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      isExplicit: hasExplicitBadge(item),
    );
  }

  static AlbumDetailed parseArtistAlbum(dynamic item, ArtistBasic artistBasic) {
    return AlbumDetailed(
      type: "ALBUM",
      albumId:
          traverseList(item, [
            "browseId",
          ]).where((element) => element != artistBasic.artistId).firstOrNull ??
          '',
      playlistId:
          traverseString(item, ["thumbnailOverlay", "playlistId"]) ?? '',
      name: traverseString(item, ["title", "text"]) ?? '',
      artists: artistsOrFallback(parseArtistsFromSubtitle(item), artistBasic),
      year: processYear(traverseList(item, ["subtitle", "text"]).last),
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      isExplicit: hasExplicitBadge(item),
    );
  }

  static AlbumDetailed parseArtistTopAlbum(
    dynamic item,
    ArtistBasic artistBasic,
  ) {
    return AlbumDetailed(
      type: "ALBUM",
      albumId: traverseList(item, ["browseId"]).isEmpty
          ? ''
          : traverseList(item, ["browseId"]).last,
      playlistId:
          traverseString(item, ["musicPlayButtonRenderer", "playlistId"]) ?? '',
      name: traverseString(item, ["title", "text"]) ?? '',
      artists: artistsOrFallback(parseArtistsFromSubtitle(item), artistBasic),
      year: processYear(traverseList(item, ["subtitle", "text"]).last),
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      isExplicit: hasExplicitBadge(item),
    );
  }

  static AlbumDetailed parseHomeSection(dynamic item) {
    final artists = parseArtistsFromSubtitle(item);
    final fallback = traverse(item, ["subtitle", "runs"]);
    final parsed = artists.isNotEmpty
        ? artists
        : [
            ArtistBasic(
              name: traverseString(fallback, ["text"]) ?? '',
              artistId: traverseString(fallback, ["browseId"]) ?? '',
            ),
          ];

    return AlbumDetailed(
      type: "ALBUM",
      albumId: traverseString(item, ["title", "browseId"]) ?? '',
      playlistId:
          traverseString(item, ["thumbnailOverlay", "playlistId"]) ?? '',
      name: traverseString(item, ["title", "text"]) ?? '',
      artists: parsed,
      year: null,
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      isExplicit: hasExplicitBadge(item),
    );
  }

  static int? processYear(String? year) {
    return year != null && RegExp(r"^\d{4}$").hasMatch(year)
        ? int.parse(year)
        : null;
  }
}
