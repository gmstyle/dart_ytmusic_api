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

  static String? _runsText(dynamic node) {
    final runs = node is Map ? node['runs'] : null;
    if (runs is! List) return traverseString(node, ['text']);
    return runs
        .map((r) => r is Map ? (r['text']?.toString() ?? '') : '')
        .join();
  }

  static String? _durationFromProgress(dynamic progressNode) {
    final renderer = progressNode is Map
        ? progressNode['musicPlaybackProgressRenderer'] ?? progressNode
        : progressNode;
    final runs = traverseList(renderer, ['durationText', 'runs']);
    for (final run in runs.reversed) {
      final text = traverseString(run, ['text'])?.trim();
      if (text != null && text.isNotEmpty && text != '•') return text;
    }
    return null;
  }

  static String? _dateFromSubtitle(dynamic subtitle) {
    final runs = subtitle is Map ? subtitle['runs'] : null;
    if (runs is! List) return null;
    for (final run in runs.reversed) {
      final text = traverseString(run, ['text'])?.trim();
      if (text == null || text.isEmpty || text == '•') continue;
      if (text.toLowerCase().contains('view')) continue;
      return text;
    }
    return null;
  }

  static List<ThumbnailFull> _thumbnails(dynamic item) {
    return traverseList(item, [
      'thumbnails',
    ]).map((t) => ThumbnailFull.fromMap(t)).toList();
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
      thumbnails: _thumbnails(item),
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
      thumbnails: _thumbnails(item),
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
      thumbnails: _thumbnails(item),
    );
  }

  /// Parses a podcast show page (`MPSP…` browse).
  static PodcastFull parse(dynamic data, String browseId) {
    final header = _responsiveHeader(data);
    final authorRun = traverse(header, ['straplineTextOne', 'runs']);
    final authorName = traverseString(authorRun, ['text']);
    final authorId = traverseString(authorRun, ['browseId']);

    String? description = _runsText(
      traverse(header, [
        'description',
        'musicDescriptionShelfRenderer',
        'description',
      ]),
    );
    description ??= _runsText(
      traverseList(data, [
        'musicDescriptionShelfRenderer',
        'description',
      ]).firstOrNull,
    );

    final shelf = _episodeShelf(data);
    final episodes = parseEpisodeItems(shelf?['contents']);

    return PodcastFull(
      browseId: browseId,
      name: _runsText(header?['title']) ?? '',
      author: authorName == null
          ? null
          : ArtistBasic(name: authorName, artistId: authorId),
      description: description,
      thumbnails: _thumbnails(header ?? data),
      episodes: episodes,
    );
  }

  static List<PodcastEpisode> parseEpisodeItems(dynamic contents) {
    if (contents is! List) return [];
    final result = <PodcastEpisode>[];
    for (final item in contents) {
      if (item is! Map) continue;
      final renderer = item['musicMultiRowListItemRenderer'] ?? item;
      if (renderer is! Map) continue;
      final episode = parseEpisodeItem(renderer);
      if (episode.videoId.isNotEmpty || episode.browseId.isNotEmpty) {
        result.add(episode);
      }
    }
    return result;
  }

  static PodcastEpisode parseEpisodeItem(dynamic item) {
    final videoId =
        traverseString(item, ['onTap', 'watchEndpoint', 'videoId']) ??
        traverseString(item, ['watchEndpoint', 'videoId']) ??
        '';
    final browseId =
        traverseString(item, ['title', 'browseId']) ??
        (videoId.isNotEmpty ? 'MPED$videoId' : '');
    final index = item is Map
        ? (item['onTap']?['watchEndpoint']?['index'] as int?)
        : null;

    return PodcastEpisode(
      videoId: videoId,
      browseId: browseId,
      name: _runsText(item is Map ? item['title'] : null) ?? '',
      description: _runsText(item is Map ? item['description'] : null),
      duration: _durationFromProgress(
        item is Map ? item['playbackProgress'] : null,
      ),
      date: _dateFromSubtitle(item is Map ? item['subtitle'] : null),
      index: index,
      thumbnails: _thumbnails(item),
    );
  }

  /// Parses a single episode page (`MPED…` browse).
  static EpisodeFull parseEpisode(dynamic data, String browseId) {
    final header = _responsiveHeader(data);
    final strapline = traverse(header, ['straplineTextOne', 'runs']);
    final podcastName = traverseString(strapline, ['text']);
    final podcastId = traverseString(strapline, ['browseId']);

    String? playlistId = podcastId;
    final menuItems = traverseList(header, ['menuRenderer', 'items']);
    for (final menuItem in menuItems) {
      final icon = traverseString(menuItem, ['icon', 'iconType']);
      if (icon == 'BROADCAST') {
        playlistId = traverseString(menuItem, ['browseId']) ?? playlistId;
        break;
      }
    }

    final videoId = browseId.startsWith('MPED')
        ? browseId.substring(4)
        : (traverseString(data, ['videoId']) ?? browseId);

    String? description = _runsText(
      traverseList(data, [
        'musicDescriptionShelfRenderer',
        'description',
      ]).firstOrNull,
    );

    return EpisodeFull(
      videoId: videoId,
      browseId: browseId.startsWith('MPED') ? browseId : 'MPED$browseId',
      name: _runsText(header?['title']) ?? '',
      date: _dateFromSubtitle(header?['subtitle']),
      duration: _durationFromProgress(header?['progress']),
      description: description,
      podcastId: playlistId,
      podcastName: podcastName,
      thumbnails: _thumbnails(header ?? data),
    );
  }

  static Map? _responsiveHeader(dynamic data) {
    final headers = traverseList(data, ['musicResponsiveHeaderRenderer']);
    final first = headers.firstOrNull;
    return first is Map ? first : null;
  }

  static Map? _episodeShelf(dynamic data) {
    final shelves = traverseList(data, ['musicShelfRenderer']);
    for (final shelf in shelves) {
      if (shelf is! Map) continue;
      final contents = shelf['contents'];
      if (contents is List &&
          contents.any(
            (c) => c is Map && c.containsKey('musicMultiRowListItemRenderer'),
          )) {
        return shelf;
      }
    }
    return shelves.whereType<Map>().firstOrNull;
  }

  /// Continuation token from a podcast episode shelf, if any.
  static String? continuationToken(dynamic data) {
    final shelf = data is Map && data.containsKey('contents')
        ? _episodeShelf(data)
        : (data is Map ? data : _episodeShelf(data));
    dynamic continuation = traverse(shelf ?? data, ['continuation']);
    if (continuation is List && continuation.isNotEmpty) {
      continuation = continuation[0];
    }
    return continuation is String && continuation.isNotEmpty
        ? continuation
        : null;
  }
}
