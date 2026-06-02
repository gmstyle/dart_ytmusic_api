import 'package:dart_ytmusic_api/parsers/album_parser.dart';
import 'package:dart_ytmusic_api/parsers/playlist_parser.dart';
import 'package:dart_ytmusic_api/parsers/song_parser.dart';
import 'package:dart_ytmusic_api/parsers/video_parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

class ArtistParser {
  static String? carouselTitle(dynamic carousel) {
    final header = carousel is Map ? carousel['header'] : null;
    final basicHeader = header is Map
        ? header['musicCarouselShelfBasicHeaderRenderer']
        : null;
    final titleObj = basicHeader is Map ? basicHeader['title'] : null;
    if (titleObj is Map) {
      final runs = titleObj['runs'];
      if (runs is List && runs.isNotEmpty) {
        return runs[0]['text']?.toString();
      }
      final simple = titleObj['simpleText'];
      if (simple is String) return simple;
    }
    return null;
  }

  static dynamic findCarousel(
    List<dynamic> carousels,
    bool Function(String) test,
  ) {
    for (final c in carousels) {
      final title = carouselTitle(c);
      if (title != null && test(title)) return c;
    }
    return null;
  }

  static bool isAlbums(String title) {
    final lower = title.toLowerCase();
    return lower.contains('album');
  }

  static bool isSingles(String title) {
    final lower = title.toLowerCase();
    return lower.contains('single') ||
        lower == 'eps' ||
        (lower.contains('ep') &&
            !lower.contains('featured') &&
            !lower.contains('album'));
  }

  static bool isVideos(String title) {
    final lower = title.toLowerCase();
    return lower.contains('video') || lower.contains('live performance');
  }

  static bool isFeatured(String title) {
    final lower = title.toLowerCase();
    return lower.contains('featured') || lower.contains('playlist');
  }

  static bool isSimilar(String title) {
    final lower = title.toLowerCase();
    return lower.contains('fan') ||
        lower.contains('similar') ||
        lower.contains('also like') ||
        lower.contains('related');
  }

  static List<dynamic> findAllCarousels(
    List<dynamic> carousels,
    bool Function(String) test,
  ) {
    final result = <dynamic>[];
    for (final c in carousels) {
      final title = carouselTitle(c);
      if (title != null && test(title)) result.add(c);
    }
    return result;
  }

  static ArtistFull parse(dynamic data, String artistId) {
    final artistBasic = ArtistBasic(
      artistId: artistId,
      name: traverseString(data, ["header", "title", "text"]) ?? '',
    );

    final carousels = traverseList(data, ["musicCarouselShelfRenderer"]);
    final albumsCarousel = findCarousel(carousels, isAlbums);
    final singlesCarousel = findCarousel(carousels, isSingles);
    final videosCarousels = findAllCarousels(carousels, isVideos);
    final featuredCarousels = findAllCarousels(carousels, isFeatured);
    final similarCarousel = findCarousel(carousels, isSimilar);

    final allVideoContents = <dynamic>[];
    for (final c in videosCarousels) {
      allVideoContents.addAll(_parseCarouselContents(c));
    }

    final allFeaturedContents = <dynamic>[];
    for (final c in featuredCarousels) {
      allFeaturedContents.addAll(_parseCarouselContents(c));
    }

    return ArtistFull(
      name: artistBasic.name,
      type: "ARTIST",
      artistId: artistId,
      thumbnails: traverseList(data, [
        "header",
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      topSongs: traverseList(data, ["musicShelfRenderer", "contents"])
          .map((item) => SongParser.parseArtistTopSong(item, artistBasic))
          .toList()
          .where((song) => song.videoId.isNotEmpty)
          .toList(),
      topAlbums: _parseCarouselContents(albumsCarousel)
          .map((item) => AlbumParser.parseArtistTopAlbum(item, artistBasic))
          .toList()
          .where((album) => album.albumId.isNotEmpty)
          .toList(),
      topSingles: _parseCarouselContents(singlesCarousel)
          .map((item) => AlbumParser.parseArtistTopAlbum(item, artistBasic))
          .toList()
          .where(
            (single) =>
                single.albumId.isNotEmpty && single.albumId.startsWith('M'),
          )
          .toList(),
      topVideos: allVideoContents
          .map((item) => VideoParser.parseArtistTopVideo(item, artistBasic))
          .toList(),
      featuredOn: allFeaturedContents
          .map(
            (item) => PlaylistParser.parseArtistFeaturedOn(item, artistBasic),
          )
          .toList(),
      similarArtists: _parseCarouselContents(
        similarCarousel,
      ).map((item) => parseSimilarArtists(item)).toList(),
      subscriberCount: traverseString(data, [
        "header",
        "subscriptionButton",
        "subscribeButtonRenderer",
        "subscriberCountText",
        "text",
      ]),
      monthlyListeners: traverseString(data, [
        "header",
        "monthlyListenerCount",
        "text",
      ]),
      totalViews: _extractTotalViews(data),
      description: _extractDescription(data),
      channelId: traverseString(data, [
        "header",
        "subscriptionButton",
        "subscribeButtonRenderer",
        "channelId",
      ]),
    );
  }

  static List<dynamic> _parseCarouselContents(dynamic carousel) {
    if (carousel is! Map) return [];
    final contents = carousel['contents'];
    return contents is List ? contents : [];
  }

  static String? _extractTotalViews(dynamic data) {
    final descriptionShelf = traverseList(data, [
      "musicDescriptionShelfRenderer",
    ]);
    if (descriptionShelf.isEmpty) return null;
    final subheader = traverseString(descriptionShelf.first, [
      "subheader",
      "text",
    ]);
    return subheader;
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

  static ArtistDetailed parseSearchResult(dynamic item) {
    final columns = traverseList(item, [
      "flexColumns",
      "runs",
    ]).expand((e) => e is List ? e : [e]).toList();

    final title = columns[0];

    String? monthlyListeners;
    final flexColumns = item['flexColumns'] as List<dynamic>?;
    if (flexColumns != null && flexColumns.length > 1) {
      final secondCol =
          flexColumns[1]['musicResponsiveListItemFlexColumnRenderer'];
      final runs = secondCol?['text']?['runs'] as List<dynamic>?;
      if (runs != null && runs.length > 2) {
        monthlyListeners = runs[2]['text'] as String?;
      }
    }

    return ArtistDetailed(
      type: "ARTIST",
      artistId: traverseString(item, ["browseId"]) ?? '',
      name: traverseString(title, ["text"]) ?? '',
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
      monthlyListeners: monthlyListeners,
    );
  }

  static ArtistDetailed parseSimilarArtists(dynamic item) {
    return ArtistDetailed(
      type: "ARTIST",
      artistId: traverseString(item, ["browseId"]) ?? '',
      name: traverseString(item, ["runs", "text"]) ?? '',
      thumbnails: traverseList(item, [
        "thumbnails",
      ]).map((item) => ThumbnailFull.fromMap(item)).toList(),
    );
  }
}
