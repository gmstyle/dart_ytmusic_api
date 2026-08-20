import 'package:dart_ytmusic_api/parsers/album_parser.dart';
import 'package:dart_ytmusic_api/parsers/playlist_parser.dart';
import 'package:dart_ytmusic_api/parsers/video_parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

class ExploreParser {
  static MoodCategoriesResult parseMoodCategories(dynamic data) {
    final sections = <String, List<MoodCategory>>{};
    final gridSections = traverseList(data, [
      "singleColumnBrowseResultsRenderer",
      "tabs",
      "tabRenderer",
      "content",
      "sectionListRenderer",
      "contents",
    ]);

    for (final section in gridSections) {
      if (section is! Map || section['gridRenderer'] == null) continue;
      final grid = section['gridRenderer'];
      final title =
          traverseString(grid, [
            "header",
            "gridHeaderRenderer",
            "title",
            "runs",
            "text",
          ]) ??
          traverseString(grid, [
            "header",
            "gridHeaderRenderer",
            "title",
            "text",
          ]) ??
          '';

      final categories = <MoodCategory>[];
      for (final item in traverseList(grid, ["items"])) {
        if (item is! Map) continue;
        final renderer =
            item['musicNavigationButtonRenderer'] ?? item.values.first;
        if (renderer is! Map) continue;

        final categoryTitle =
            traverseString(renderer, ["buttonText", "runs", "text"]) ??
            traverseString(renderer, ["buttonText", "text"]);
        final params =
            traverseString(renderer, [
              "clickCommand",
              "browseEndpoint",
              "params",
            ]) ??
            traverseString(renderer, [
              "navigationEndpoint",
              "browseEndpoint",
              "params",
            ]);

        if (categoryTitle != null && params != null) {
          categories.add(MoodCategory(title: categoryTitle, params: params));
        }
      }

      if (title.isNotEmpty && categories.isNotEmpty) {
        sections[title] = categories;
      }
    }

    return MoodCategoriesResult(sections: sections);
  }

  static List<PlaylistDetailed> parseMoodPlaylists(dynamic data) {
    final playlists = <PlaylistDetailed>[];
    final sections = traverseList(data, [
      "singleColumnBrowseResultsRenderer",
      "tabs",
      "tabRenderer",
      "content",
      "sectionListRenderer",
      "contents",
    ]);

    for (final section in sections) {
      if (section is! Map) continue;

      List<dynamic> items = [];
      if (section['gridRenderer'] != null) {
        items = traverseList(section['gridRenderer'], ["items"]);
      } else if (section['musicCarouselShelfRenderer'] != null) {
        items = traverseList(section['musicCarouselShelfRenderer'], [
          "contents",
        ]);
      } else if (section['musicImmersiveCarouselShelfRenderer'] != null) {
        items = traverseList(section['musicImmersiveCarouselShelfRenderer'], [
          "contents",
        ]);
      }

      for (final item in items) {
        if (item is! Map) continue;
        final renderer = item['musicTwoRowItemRenderer'] ?? item.values.first;
        if (renderer is! Map) continue;
        playlists.add(PlaylistParser.parseHomeSection(renderer));
      }
    }

    return playlists;
  }

  static ChartsResult parseCharts(dynamic data, {String country = 'ZZ'}) {
    final sections = traverseList(data, [
      "singleColumnBrowseResultsRenderer",
      "tabs",
      "tabRenderer",
      "content",
      "sectionListRenderer",
      "contents",
    ]);

    final countries = _parseChartCountries(
      sections.isNotEmpty ? sections[0] : null,
      data,
    );

    final carousels = <List<dynamic>>[];
    for (var i = 1; i < sections.length; i++) {
      final contents = traverseList(sections[i], [
        "musicCarouselShelfRenderer",
        "contents",
      ]);
      if (contents.isNotEmpty) carousels.add(contents);
    }

    final playlistCarousels = carousels.where(_isPlaylistCarousel).toList();
    final artistCarousels = carousels.where(_isArtistCarousel).toList();

    var playlistNames = ['videos'];
    if (country == 'US') playlistNames.add('genres');
    if (country == 'IN') playlistNames.add('languages');
    if (playlistCarousels.length > playlistNames.length) {
      playlistNames = ['daily', 'weekly', ...playlistNames.sublist(1)];
    }

    final videos = <ChartPlaylist>[];
    final daily = <ChartPlaylist>[];
    final weekly = <ChartPlaylist>[];
    final genres = <ChartPlaylist>[];
    final languages = <ChartPlaylist>[];

    for (
      var i = 0;
      i < playlistCarousels.length && i < playlistNames.length;
      i++
    ) {
      final parsed = _parseChartPlaylists(playlistCarousels[i]);
      switch (playlistNames[i]) {
        case 'daily':
          daily.addAll(parsed);
        case 'weekly':
          weekly.addAll(parsed);
        case 'genres':
          genres.addAll(parsed);
        case 'languages':
          languages.addAll(parsed);
        default:
          videos.addAll(parsed);
      }
    }

    final artists = artistCarousels.isEmpty
        ? <ChartArtist>[]
        : _parseChartArtists(artistCarousels.first);

    return ChartsResult(
      countries: countries,
      videos: videos,
      daily: daily.isEmpty ? null : daily,
      weekly: weekly.isEmpty ? null : weekly,
      genres: genres.isEmpty ? null : genres,
      languages: languages.isEmpty ? null : languages,
      artists: artists,
    );
  }

  static ChartsCountries _parseChartCountries(
    dynamic firstSection,
    dynamic data,
  ) {
    var selected = '';
    final options = <String>[];

    if (firstSection is Map && firstSection['musicShelfRenderer'] != null) {
      selected =
          traverseString(firstSection, [
            "musicShelfRenderer",
            "subheaders",
            "musicSideAlignedItemRenderer",
            "startItems",
            "musicSortFilterButtonRenderer",
            "text",
            "runs",
            "text",
          ]) ??
          '';
    }

    final mutations =
        data?['frameworkUpdates']?['entityBatchUpdate']?['mutations'];
    if (mutations is List) {
      for (final mutation in mutations) {
        final token = traverseString(mutation, [
          "payload",
          "musicFormBooleanChoice",
          "opaqueToken",
        ]);
        if (token != null) options.add(token);
      }
    }

    return ChartsCountries(selected: selected, options: options);
  }

  static bool _isPlaylistCarousel(List<dynamic> contents) {
    if (contents.isEmpty) return false;
    final first = contents.first;
    if (first is! Map) return false;
    final browseId = traverseString(first, [
      "musicTwoRowItemRenderer",
      "title",
      "navigationEndpoint",
      "browseEndpoint",
      "browseId",
    ]);
    return browseId?.startsWith('VL') ?? false;
  }

  static bool _isArtistCarousel(List<dynamic> contents) {
    if (contents.isEmpty) return false;
    final first = contents.first;
    return first is Map && first['musicResponsiveListItemRenderer'] != null;
  }

  static List<ChartPlaylist> _parseChartPlaylists(List<dynamic> contents) {
    return contents
        .map((item) {
          if (item is! Map) return null;
          final renderer = item['musicTwoRowItemRenderer'];
          if (renderer is! Map) return null;
          final browseId = traverseString(renderer, [
            "title",
            "navigationEndpoint",
            "browseEndpoint",
            "browseId",
          ]);
          return ChartPlaylist(
            title:
                traverseString(renderer, ["title", "runs", "text"]) ??
                traverseString(renderer, ["title", "text"]) ??
                '',
            playlistId: browseId != null && browseId.startsWith('VL')
                ? browseId.substring(2)
                : browseId ?? '',
            thumbnails:
                traverseList(renderer, [
                      "thumbnailRenderer",
                      "musicThumbnailRenderer",
                      "thumbnail",
                      "thumbnails",
                    ])
                    .followedBy(traverseList(renderer, ["thumbnails"]))
                    .map((t) => ThumbnailFull.fromMap(t))
                    .toList(),
          );
        })
        .whereType<ChartPlaylist>()
        .toList();
  }

  static List<ChartArtist> _parseChartArtists(List<dynamic> contents) {
    return contents
        .map((item) {
          if (item is! Map) return null;
          final renderer = item['musicResponsiveListItemRenderer'];
          if (renderer is! Map) return null;

          final flexColumns = renderer['flexColumns'] as List<dynamic>?;
          final titleCol = flexColumns?.isNotEmpty == true
              ? flexColumns![0]['musicResponsiveListItemFlexColumnRenderer']
              : null;
          final subCol = flexColumns != null && flexColumns.length > 1
              ? flexColumns[1]['musicResponsiveListItemFlexColumnRenderer']
              : null;

          final rank = traverseString(renderer, [
            "customIndexColumn",
            "musicCustomIndexColumnRenderer",
            "text",
            "runs",
            "text",
          ]);

          final trendIcon = traverseString(renderer, [
            "customIndexColumn",
            "musicCustomIndexColumnRenderer",
            "icon",
            "iconType",
          ]);
          final trend = switch (trendIcon) {
            'ARROW_DROP_UP' => 'up',
            'ARROW_DROP_DOWN' => 'down',
            'ARROW_CHART_NEUTRAL' => 'neutral',
            _ => null,
          };

          final browseId =
              traverseString(titleCol, [
                "text",
                "runs",
                "navigationEndpoint",
                "browseEndpoint",
                "browseId",
              ]) ??
              traverseString(renderer, [
                "navigationEndpoint",
                "browseEndpoint",
                "browseId",
              ]) ??
              '';

          return ChartArtist(
            title: traverseString(titleCol, ["text", "runs", "text"]) ?? '',
            browseId: browseId,
            subscribers: traverseString(subCol, ["text", "runs", "text"]),
            thumbnails: traverseList(renderer, [
              "thumbnail",
              "musicThumbnailRenderer",
              "thumbnail",
              "thumbnails",
            ]).map((t) => ThumbnailFull.fromMap(t)).toList(),
            rank: rank,
            trend: trend,
          );
        })
        .whereType<ChartArtist>()
        .toList();
  }

  static NewReleasesResult parseNewReleases(dynamic data) {
    final albums = <AlbumDetailed>[];
    final videos = <VideoDetailed>[];
    final carousels = traverseList(data, ['musicCarouselShelfRenderer']);

    for (final carousel in carousels) {
      if (carousel is! Map) continue;
      final browseId =
          traverseString(carousel, [
            'header',
            'title',
            'navigationEndpoint',
            'browseEndpoint',
            'browseId',
          ]) ??
          traverseString(carousel, [
            'moreContentButton',
            'browseEndpoint',
            'browseId',
          ]);
      final contents = carousel['contents'];
      if (contents is! List) continue;

      if (browseId == 'FEmusic_new_releases_albums') {
        for (final item in contents) {
          final renderer = item is Map ? item['musicTwoRowItemRenderer'] : null;
          if (renderer != null) {
            albums.add(AlbumParser.parseRelatedRelease(renderer));
          }
        }
      } else if (browseId == 'FEmusic_new_releases_videos') {
        for (final item in contents) {
          final renderer = item is Map ? item['musicTwoRowItemRenderer'] : null;
          if (renderer != null) {
            final artistRun = traverseList(renderer, ['subtitle', 'runs'])
                .expand((e) => e is Iterable ? e : [e])
                .cast<dynamic>()
                .firstWhere(
                  (r) => traverseString(r, ['browseId']) != null,
                  orElse: () => null,
                );
            videos.add(
              VideoParser.parseArtistTopVideo(
                renderer,
                ArtistBasic(
                  name: traverseString(artistRun, ['text']) ?? '',
                  artistId: traverseString(artistRun, ['browseId']),
                ),
              ),
            );
          }
        }
      }
    }

    return NewReleasesResult(albums: albums, videos: videos);
  }
}
