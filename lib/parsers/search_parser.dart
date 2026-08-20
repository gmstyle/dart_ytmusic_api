import 'package:dart_ytmusic_api/parsers/album_parser.dart';
import 'package:dart_ytmusic_api/parsers/artist_parser.dart';
import 'package:dart_ytmusic_api/parsers/playlist_parser.dart';
import 'package:dart_ytmusic_api/parsers/podcast_parser.dart';
import 'package:dart_ytmusic_api/parsers/song_parser.dart';
import 'package:dart_ytmusic_api/parsers/video_parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

class SearchParser {
  static SearchResult? parse(dynamic item) {
    final flexColumns = traverseList(item, ["flexColumns"]);
    if (flexColumns.length < 2) return null;
    final type =
        traverseList(flexColumns[1], ["runs", "text"]).firstOrNull as String?;

    final parsers = {
      "Song": SongParser.parseSearchResult,
      "Video": VideoParser.parseSearchResult,
      "Artist": ArtistParser.parseSearchResult,
      "EP": AlbumParser.parseSearchResult,
      "Single": AlbumParser.parseSearchResult,
      "Album": AlbumParser.parseSearchResult,
      "Playlist": PlaylistParser.parseSearchResult,
      "Podcast": PodcastParser.parseSearchResult,
      "Podcasts": PodcastParser.parseSearchResult,
      "Episode": PodcastParser.parseEpisodeSearchResult,
      "Episodes": PodcastParser.parseEpisodeSearchResult,
      "Profile": PodcastParser.parseProfileSearchResult,
    };

    if (parsers.containsKey(type)) {
      return parsers[type]!(item);
    }

    final pageType = traverseString(item, [
      "navigationEndpoint",
      "browseEndpoint",
      "browseEndpointContextSupportedConfigs",
      "browseEndpointContextMusicConfig",
      "pageType",
    ]);
    switch (pageType) {
      case 'MUSIC_PAGE_TYPE_PODCAST_SHOW_DETAIL_PAGE':
        return PodcastParser.parseSearchResult(item);
      case 'MUSIC_PAGE_TYPE_USER_CHANNEL':
        return PodcastParser.parseProfileSearchResult(item);
    }

    return null;
  }
}
