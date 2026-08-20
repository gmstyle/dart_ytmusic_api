import 'package:dart_ytmusic_api/parsers/album_parser.dart';
import 'package:dart_ytmusic_api/parsers/artist_parser.dart';
import 'package:dart_ytmusic_api/parsers/playlist_parser.dart';
import 'package:dart_ytmusic_api/parsers/song_parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

class Parser {
  static int? parseDuration(String? time) {
    if (time == null) return null;

    // Extract only the time portion using regex (format: H:MM:SS or MM:SS or M:SS)
    final timeMatch = RegExp(r'(\d+):(\d+)(?::(\d+))?').firstMatch(time);
    if (timeMatch == null) return null;

    // Parse the matched groups
    final parts = <int>[];
    for (int i = 1; i <= timeMatch.groupCount; i++) {
      final group = timeMatch.group(i);
      if (group != null) {
        parts.add(int.parse(group));
      }
    }

    if (parts.isEmpty) return null;

    // Handle different time formats
    if (parts.length == 2) {
      // MM:SS format
      final minutes = parts[0];
      final seconds = parts[1];
      return seconds + minutes * 60;
    } else if (parts.length == 3) {
      // H:MM:SS format
      final hours = parts[0];
      final minutes = parts[1];
      final seconds = parts[2];
      return seconds + minutes * 60 + hours * 60 * 60;
    }

    return null;
  }

  static double parseNumber(String string) {
    if (string.endsWith("K") ||
        string.endsWith("M") ||
        string.endsWith("B") ||
        string.endsWith("T")) {
      final number = double.parse(string.substring(0, string.length - 1));
      final multiplier = string.substring(string.length - 1);

      return {
            "K": number * 1000,
            "M": number * 1000 * 1000,
            "B": number * 1000 * 1000 * 1000,
            "T": number * 1000 * 1000 * 1000 * 1000,
          }[multiplier] ??
          double.nan;
    } else {
      return double.parse(string);
    }
  }

  static HomeSection parseHomeSection(dynamic data) {
    final headerTitle = data["header"]?["title"];
    final browseEndpoint =
        headerTitle?["runs"]?[0]?["navigationEndpoint"]?["browseEndpoint"];

    return HomeSection(
      title: traverseString(data, ["header", "title", "text"]) ?? '',
      shelfId: data["shelfId"] as String?,
      browseId: browseEndpoint?["browseId"] as String?,
      browseParams: browseEndpoint?["params"] as String?,
      contents: traverseList(data, ["contents"])
          .map(_parseHomeContentItem)
          .whereType<Object>()
          .toList(),
    );
  }

  /// Parses one home shelf item by its own primary browse/watch page type.
  static dynamic _parseHomeContentItem(dynamic item) {
    final renderer = item is Map
        ? (item['musicTwoRowItemRenderer'] ??
              item['musicResponsiveListItemRenderer'] ??
              item)
        : item;
    if (renderer is! Map) return null;

    final pageType = _primaryPageType(renderer);
    final watchPlaylistId = traverseString(renderer, [
      "navigationEndpoint",
      "watchPlaylistEndpoint",
      "playlistId",
    ]);

    switch (pageType) {
      case 'MUSIC_PAGE_TYPE_ALBUM':
        return AlbumParser.parseHomeSection(item);
      case 'MUSIC_PAGE_TYPE_PLAYLIST':
        return PlaylistParser.parseHomeSection(item);
      case 'MUSIC_PAGE_TYPE_ARTIST':
      case 'MUSIC_PAGE_TYPE_USER_CHANNEL':
        return ArtistParser.parseHomeSection(item);
      default:
        if (watchPlaylistId != null) {
          return PlaylistParser.parseHomeSection(item);
        }
        // Songs / videos (list rows or two-row watch cards).
        if (item is Map && item.containsKey('musicResponsiveListItemRenderer')) {
          return SongParser.parseHomeSection(item);
        }
        if (traverseString(renderer, ['watchEndpoint', 'videoId']) != null ||
            traverseString(renderer, ['videoId']) != null) {
          return SongParser.parseHomeSection(item);
        }
        return null;
    }
  }

  /// Page type of the item's primary title/navigation target (not subtitle).
  static String? _primaryPageType(Map renderer) {
    final title = renderer['title'];
    if (title != null) {
      final fromTitle = traverseString(title, ['pageType']);
      if (fromTitle != null) return fromTitle;
    }
    final nav = renderer['navigationEndpoint'];
    if (nav != null) {
      final fromNav = traverseString(nav, ['pageType']);
      if (fromNav != null) return fromNav;
    }
    return null;
  }
}
