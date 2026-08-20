import 'package:dart_ytmusic_api/parsers/playlist_parser.dart';
import 'package:dart_ytmusic_api/parsers/video_parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

class UserParser {
  static UserFull parse(dynamic data, String channelId) {
    final name =
        traverseString(data, ['header', 'title', 'text']) ??
        traverseString(data, ['musicVisualHeaderRenderer', 'title', 'text']) ??
        '';
    final subscriberCount = traverseString(data, [
      'header',
      'subscriptionButton',
      'subscribeButtonRenderer',
      'subscriberCountText',
      'text',
    ]);

    final carousels = traverseList(data, ['musicCarouselShelfRenderer']);
    Map? videosCarousel;
    Map? playlistsCarousel;
    for (final c in carousels) {
      if (c is! Map) continue;
      final title =
          (traverseString(c, ['header', 'title', 'runs', 'text']) ??
                  traverseString(c, ['header', 'title', 'text']) ??
                  '')
              .toLowerCase();
      if (title.contains('video')) videosCarousel = c;
      if (title.contains('playlist')) playlistsCarousel = c;
    }

    final videos = <VideoDetailed>[];
    for (final item in _contents(videosCarousel)) {
      final renderer = item is Map ? item['musicTwoRowItemRenderer'] : null;
      if (renderer != null) {
        videos.add(
          VideoParser.parseArtistTopVideo(
            renderer,
            ArtistBasic(name: name, artistId: channelId),
          ),
        );
      }
    }

    final playlists = <PlaylistDetailed>[];
    for (final item in _contents(playlistsCarousel)) {
      final renderer = item is Map ? item['musicTwoRowItemRenderer'] : null;
      if (renderer != null) {
        playlists.add(
          PlaylistParser.parseArtistFeaturedOn(
            renderer,
            ArtistBasic(name: name, artistId: channelId),
          ),
        );
      }
    }

    return UserFull(
      name: name,
      channelId: channelId,
      subscriberCount: subscriberCount,
      videos: videos,
      playlists: playlists,
      videosParams: _carouselParams(videosCarousel),
      playlistsParams: _carouselParams(playlistsCarousel),
    );
  }

  static List<dynamic> _contents(Map? carousel) {
    final contents = carousel?['contents'];
    return contents is List ? contents : [];
  }

  static String? _carouselParams(Map? carousel) {
    return traverseString(carousel, [
          'header',
          'title',
          'navigationEndpoint',
          'browseEndpoint',
          'params',
        ]) ??
        traverseString(carousel, [
          'moreContentButton',
          'browseEndpoint',
          'params',
        ]);
  }

  static List<PlaylistDetailed> parsePlaylistsGrid(
    dynamic data,
    String channelId,
    String name,
  ) {
    final artist = ArtistBasic(name: name, artistId: channelId);
    return traverseList(data, ['musicTwoRowItemRenderer'])
        .map((item) => PlaylistParser.parseArtistFeaturedOn(item, artist))
        .toList();
  }

  static List<VideoDetailed> parseVideosGrid(
    dynamic data,
    String channelId,
    String name,
  ) {
    final artist = ArtistBasic(name: name, artistId: channelId);
    return traverseList(data, [
      'musicTwoRowItemRenderer',
    ]).map((item) => VideoParser.parseArtistTopVideo(item, artist)).toList();
  }
}
