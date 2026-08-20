import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

class PodcastParser {
  static String? _directBrowseId(dynamic item) {
    if (item is Map) {
      final direct = item['navigationEndpoint']?['browseEndpoint']?['browseId'];
      if (direct is String && direct.isNotEmpty) return direct;
    }
    final ids = traverseList(item, ['browseId']).whereType<String>();
    return ids.where((id) => id.startsWith('MPSP')).firstOrNull ??
        ids.lastOrNull;
  }

  static PodcastDetailed parseSearchResult(dynamic item) {
    final columns = traverseList(item, [
      'flexColumns',
      'runs',
    ]).expand((e) => e is Iterable ? e : [e]).toList();
    final title = columns.isNotEmpty ? columns[0] : null;
    final author = columns.length > 1 ? columns[1] : null;
    final browseId = _directBrowseId(item) ?? '';

    return PodcastDetailed(
      type: 'PODCAST',
      browseId: browseId,
      name: traverseString(title, ['text']) ?? '',
      author: traverseString(author, ['text']),
      thumbnails: traverseList(item, [
        'thumbnails',
      ]).map((t) => ThumbnailFull.fromMap(t)).toList(),
    );
  }

  static EpisodeDetailed parseEpisodeSearchResult(dynamic item) {
    final columns = traverseList(item, [
      'flexColumns',
      'runs',
    ]).expand((e) => e is Iterable ? e : [e]).toList();
    final title = columns.isNotEmpty ? columns[0] : null;
    String? date;
    String? podcastName;
    String? podcastId;
    if (columns.length > 1) {
      final runs = columns.skip(1).toList();
      for (final run in runs) {
        final pageType = traverseString(run, [
          'navigationEndpoint',
          'browseEndpoint',
          'browseEndpointContextSupportedConfigs',
          'browseEndpointContextMusicConfig',
          'pageType',
        ]);
        if (pageType == 'MUSIC_PAGE_TYPE_PODCAST_SHOW_DETAIL_PAGE' ||
            (traverseString(run, ['browseId'])?.startsWith('MPSP') ?? false)) {
          podcastName = traverseString(run, ['text']);
          podcastId = traverseString(run, ['browseId']);
        } else if (date == null) {
          final text = traverseString(run, ['text']);
          if (text != null && text != ' • ' && text != 'Episode') {
            date = text;
          }
        }
      }
    }

    return EpisodeDetailed(
      type: 'EPISODE',
      videoId:
          traverseString(item, ['playNavigationEndpoint', 'videoId']) ??
          traverseString(item, ['watchEndpoint', 'videoId']) ??
          '',
      name: traverseString(title, ['text']) ?? '',
      date: date,
      podcastName: podcastName,
      podcastId: podcastId,
      thumbnails: traverseList(item, [
        'thumbnails',
      ]).map((t) => ThumbnailFull.fromMap(t)).toList(),
    );
  }

  static ProfileDetailed parseProfileSearchResult(dynamic item) {
    final columns = traverseList(item, [
      'flexColumns',
      'runs',
    ]).expand((e) => e is Iterable ? e : [e]).toList();
    final title = columns.isNotEmpty ? columns[0] : null;
    String? handle;
    for (final col in columns.skip(1)) {
      final text = traverseString(col, ['text']);
      if (text != null && text.startsWith('@')) {
        handle = text;
        break;
      }
    }

    return ProfileDetailed(
      type: 'PROFILE',
      browseId: _directBrowseId(item) ?? '',
      name: traverseString(title, ['text']) ?? '',
      handle: handle,
      thumbnails: traverseList(item, [
        'thumbnails',
      ]).map((t) => ThumbnailFull.fromMap(t)).toList(),
    );
  }
}
