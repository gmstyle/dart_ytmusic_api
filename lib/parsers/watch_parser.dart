import 'package:dart_ytmusic_api/parsers/parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/filters.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

class WatchParser {
  static dynamic playlistPanelContents(dynamic nextData) {
    return nextData?['contents']?['singleColumnMusicWatchNextResultsRenderer']?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['musicQueueRenderer']?['content']?['playlistPanelRenderer'];
  }

  static Map<String, String> tabBrowseIds(dynamic nextData) {
    final browseIds = <String, String>{};
    final tabs =
        nextData?['contents']?['singleColumnMusicWatchNextResultsRenderer']?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'];
    if (tabs is! List) return browseIds;

    for (final tab in tabs) {
      if (tab?['tabRenderer']?['unselectable'] != null) continue;
      final browseEndpoint =
          tab?['tabRenderer']?['endpoint']?['browseEndpoint'];
      if (browseEndpoint is! Map) continue;
      final pageType =
          browseEndpoint['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType']
              as String?;
      final browseId = browseEndpoint['browseId'] as String?;
      if (pageType != null && browseId != null) {
        browseIds[pageType] = browseId;
      }
    }
    return browseIds;
  }

  static WatchTrack? parseWatchTrack(dynamic renderer) {
    if (renderer is! Map) return null;
    if (renderer['unplayableText'] != null) return null;

    final videoId = renderer['videoId'] as String? ?? '';
    if (videoId.isEmpty) return null;

    final title = renderer['title']?['runs']?[0]?['text'] as String? ?? '';
    final longBylineRuns =
        renderer['longBylineText']?['runs'] as List<dynamic>?;
    final artistName = longBylineRuns?[0]?['text'] as String? ?? '';
    final artistId =
        longBylineRuns?[0]?['navigationEndpoint']?['browseEndpoint']?['browseId']
            as String?;

    AlbumBasic? album;
    if (longBylineRuns != null) {
      for (final run in longBylineRuns) {
        final pageType =
            run?['navigationEndpoint']?['browseEndpoint']?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType']
                as String?;
        if (pageType == 'MUSIC_PAGE_TYPE_ALBUM') {
          final albumName = run['text'] as String?;
          final albumId =
              run['navigationEndpoint']?['browseEndpoint']?['browseId']
                  as String?;
          if (albumName != null && albumId != null) {
            album = AlbumBasic(name: albumName, albumId: albumId);
            break;
          }
        }
      }
    }

    final durationText = renderer['lengthText']?['runs']?[0]?['text'];
    final duration = Parser.parseDuration(durationText as String?) ?? 0;

    final thumbnailsList = renderer['thumbnail']?['thumbnails'];
    final thumbnails = thumbnailsList is List
        ? thumbnailsList.map((item) => ThumbnailFull.fromMap(item)).toList()
        : <ThumbnailFull>[];

    return WatchTrack(
      videoId: videoId,
      title: title,
      artist: ArtistBasic(name: artistName, artistId: artistId),
      album: album,
      duration: duration,
      thumbnails: thumbnails,
      isExplicit: hasExplicitBadge(renderer),
    );
  }

  static List<WatchTrack> parseWatchPlaylist(
    List<dynamic> contents, {
    bool skipFirst = false,
  }) {
    final tracks = <WatchTrack>[];
    final items = skipFirst ? contents.skip(1) : contents;

    for (final item in items) {
      if (item is! Map) continue;

      if (item['playlistPanelVideoWrapperRenderer'] != null) {
        final wrapper = item['playlistPanelVideoWrapperRenderer'];
        final primary = wrapper['primaryRenderer'];
        final counterpartRenderer =
            wrapper['counterpart']?[0]?['counterpartRenderer']?['playlistPanelVideoRenderer'];
        final track = parseWatchTrack(primary?['playlistPanelVideoRenderer']);
        if (track != null) {
          final counterpart = parseWatchTrack(counterpartRenderer);
          tracks.add(
            counterpart != null
                ? WatchTrack(
                    videoId: track.videoId,
                    title: track.title,
                    artist: track.artist,
                    album: track.album,
                    duration: track.duration,
                    thumbnails: track.thumbnails,
                    isExplicit: track.isExplicit,
                    counterpart: counterpart,
                  )
                : track,
          );
        }
        continue;
      }

      final track = parseWatchTrack(item['playlistPanelVideoRenderer']);
      if (track != null) tracks.add(track);
    }

    return tracks;
  }

  static String? playlistIdFromContents(List<dynamic> contents) {
    for (final item in contents) {
      final renderer = item is Map ? item['playlistPanelVideoRenderer'] : null;
      final playlistId = traverseString(renderer, [
        'navigationEndpoint',
        'watchEndpoint',
        'playlistId',
      ]);
      if (playlistId != null && playlistId.isNotEmpty) return playlistId;
    }
    return null;
  }
}
