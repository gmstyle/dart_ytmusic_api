import 'package:dart_ytmusic_api/parsers/album_parser.dart';
import 'package:dart_ytmusic_api/parsers/artist_parser.dart';
import 'package:dart_ytmusic_api/parsers/playlist_parser.dart';
import 'package:dart_ytmusic_api/parsers/song_parser.dart';
import 'package:dart_ytmusic_api/parsers/video_parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

class RelatedParser {
  static List<RelatedSection> parseSections(dynamic data) {
    final sections = traverseList(data, ["sectionListRenderer", "contents"]);
    return sections.map(parseSection).whereType<RelatedSection>().toList();
  }

  static RelatedSection? parseSection(dynamic row) {
    if (row is! Map) return null;

    if (row['musicDescriptionShelfRenderer'] != null) {
      final shelf = row['musicDescriptionShelfRenderer'];
      final title =
          traverseString(shelf, ["header", "runs", "text"]) ??
          traverseString(shelf, ["header", "text"]) ??
          'About';
      final runs = shelf['description']?['runs'] as List<dynamic>?;
      final description = runs?.map((r) => r['text']?.toString() ?? '').join();
      return RelatedSection(title: title, contents: [description ?? '']);
    }

    final renderer = row.values.first;
    if (renderer is! Map || renderer['contents'] == null) return null;

    final title =
        traverseString(renderer, [
          "header",
          "musicCarouselShelfBasicHeaderRenderer",
          "title",
          "runs",
          "text",
        ]) ??
        traverseString(renderer, [
          "header",
          "musicCarouselShelfBasicHeaderRenderer",
          "strapline",
          "runs",
          "text",
        ]) ??
        traverseString(renderer, ["header", "title", "text"]) ??
        '';

    final contents = <dynamic>[];
    for (final item in renderer['contents'] as List<dynamic>) {
      final parsed = _parseItem(item);
      if (parsed != null) contents.add(parsed);
    }

    if (contents.isEmpty) return null;
    return RelatedSection(title: title, contents: contents);
  }

  static dynamic _parseItem(dynamic item) {
    if (item is! Map) return null;

    final twoRow = item['musicTwoRowItemRenderer'];
    if (twoRow != null) {
      final pageType = traverseString(twoRow, [
        "title",
        "navigationEndpoint",
        "browseEndpoint",
        "browseEndpointContextSupportedConfigs",
        "browseEndpointContextMusicConfig",
        "pageType",
      ]);

      switch (pageType) {
        case 'MUSIC_PAGE_TYPE_ALBUM':
          return AlbumParser.parseRelatedRelease(twoRow);
        case 'MUSIC_PAGE_TYPE_ARTIST':
        case 'MUSIC_PAGE_TYPE_USER_CHANNEL':
          return ArtistParser.parseSimilarArtists(twoRow);
        case 'MUSIC_PAGE_TYPE_PLAYLIST':
          return PlaylistParser.parseHomeSection(twoRow);
        default:
          final videoId = traverseString(twoRow, [
            "navigationEndpoint",
            "watchEndpoint",
            "videoId",
          ]);
          if (videoId != null) {
            return VideoParser.parseArtistTopVideo(
              twoRow,
              ArtistBasic(name: '', artistId: null),
            );
          }
      }
    }

    final responsive = item['musicResponsiveListItemRenderer'];
    if (responsive != null) {
      return SongParser.parseSearchResult(responsive);
    }

    return null;
  }
}
