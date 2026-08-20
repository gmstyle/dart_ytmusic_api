// ignore_for_file: avoid_print
//
// Debug utility to inspect the *raw* Innertube JSON responses returned by
// YouTube Music, so new/undocumented fields can be discovered and compared
// against what the parsers in lib/parsers currently extract.
//
// Usage (run from the package root):
//   dart run tool/dump_raw.dart search "Eminem Kill You"
//   dart run tool/dump_raw.dart player dQw4w9WgXcQ
//   dart run tool/dump_raw.dart next dQw4w9WgXcQ
//   dart run tool/dump_raw.dart browse UCuAXFkgsw1L7xaCfnd5JJOw
//   dart run tool/dump_raw.dart home
//   dart run tool/dump_raw.dart suggestions "faded"
//   dart run tool/dump_raw.dart charts [US|ZZ|...]
//   dart run tool/dump_raw.dart moods
//   dart run tool/dump_raw.dart new-releases
//   dart run tool/dump_raw.dart lyrics dQw4w9WgXcQ
//   dart run tool/dump_raw.dart related dQw4w9WgXcQ
//   dart run tool/dump_raw.dart search-filter "Eg-..." "query"
//
// Output is written as pretty-printed JSON to tool/output/<endpoint>_<arg>.json
import 'dart:convert';
import 'dart:io';

import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';

Future<void> _writeJson(String name, dynamic data) async {
  final dir = Directory('tool/output');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  final file = File('${dir.path}/$safeName.json');
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  print('wrote ${file.path}');
}

Future<String?> _lyricsBrowseId(YTMusic yt, String videoId) async {
  final next = await yt.constructRequest('next', body: {'videoId': videoId});
  final tabs =
      next?['contents']?['singleColumnMusicWatchNextResultsRenderer']?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'];
  if (tabs is! List) return null;
  for (final tab in tabs) {
    if (tab?['tabRenderer']?['unselectable'] != null) continue;
    final endpoint = tab?['tabRenderer']?['endpoint']?['browseEndpoint'];
    if (endpoint?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType'] ==
        'MUSIC_PAGE_TYPE_TRACK_LYRICS') {
      return endpoint['browseId'] as String?;
    }
  }
  return null;
}

Future<String?> _relatedBrowseId(YTMusic yt, String videoId) async {
  final next = await yt.constructRequest('next', body: {'videoId': videoId});
  final tabs =
      next?['contents']?['singleColumnMusicWatchNextResultsRenderer']?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'];
  if (tabs is! List) return null;
  for (final tab in tabs) {
    if (tab?['tabRenderer']?['unselectable'] != null) continue;
    final endpoint = tab?['tabRenderer']?['endpoint']?['browseEndpoint'];
    if (endpoint?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType'] ==
        'MUSIC_PAGE_TYPE_TRACK_RELATED') {
      return endpoint['browseId'] as String?;
    }
  }
  return null;
}

void main(List<String> args) async {
  if (args.isEmpty) {
    print(
      'Usage: dart run tool/dump_raw.dart '
      '<search|player|next|browse|home|suggestions|charts|moods|new-releases|lyrics|related|search-filter> [arg] [query]',
    );
    exit(64);
  }

  final endpoint = args[0];
  final arg = args.length > 1 ? args[1] : null;
  final arg2 = args.length > 2 ? args[2] : null;

  final yt = await YTMusic().initialize();

  dynamic data;
  switch (endpoint) {
    case 'search':
      if (arg == null) {
        throw ArgumentError('search requires a query');
      }
      data = await yt.constructRequest(
        'search',
        body: {'query': arg, 'params': null},
      );
      break;
    case 'search-filter':
      if (arg == null || arg2 == null) {
        throw ArgumentError(
          'search-filter requires params and query, e.g. dart run tool/dump_raw.dart search-filter "Eg-..." "query"',
        );
      }
      data = await yt.constructRequest(
        'search',
        body: {'query': arg2, 'params': arg},
      );
      break;
    case 'player':
      if (arg == null) throw ArgumentError('player requires a videoId');
      data = await yt.constructRequest('player', body: {'videoId': arg});
      break;
    case 'next':
      if (arg == null) throw ArgumentError('next requires a videoId');
      data = await yt.constructRequest(
        'next',
        body: {'videoId': arg, 'playlistId': 'RDAMVM$arg', 'isAudioOnly': true},
      );
      break;
    case 'browse':
      if (arg == null) {
        throw ArgumentError('browse requires a browseId');
      }
      data = await yt.constructRequest('browse', body: {'browseId': arg});
      break;
    case 'home':
      data = await yt.constructRequest(
        'browse',
        body: {'browseId': feMusicHome},
      );
      break;
    case 'suggestions':
      if (arg == null) throw ArgumentError('suggestions requires a query');
      data = await yt.constructRequest(
        'music/get_search_suggestions',
        body: {'input': arg},
      );
      break;
    case 'charts':
      final country = arg ?? 'ZZ';
      data = await yt.constructRequest(
        'browse',
        body: {
          'browseId': feMusicCharts,
          'formData': {
            'selectedValues': [country],
          },
        },
      );
      break;
    case 'moods':
      data = await yt.constructRequest(
        'browse',
        body: {'browseId': feMusicMoodsAndGenres},
      );
      break;
    case 'new-releases':
      data = await yt.constructRequest(
        'browse',
        body: {'browseId': feMusicNewReleases},
      );
      break;
    case 'lyrics':
      if (arg == null) throw ArgumentError('lyrics requires a videoId');
      final browseId = await _lyricsBrowseId(yt, arg);
      if (browseId == null) throw StateError('No lyrics tab for $arg');
      data = await yt.constructRequest('browse', body: {'browseId': browseId});
      break;
    case 'related':
      if (arg == null) throw ArgumentError('related requires a videoId');
      final browseId = await _relatedBrowseId(yt, arg);
      if (browseId == null) throw StateError('No related tab for $arg');
      data = await yt.constructRequest('browse', body: {'browseId': browseId});
      break;
    default:
      throw ArgumentError('Unknown endpoint: $endpoint');
  }

  final suffix = switch (endpoint) {
    'search-filter' => '${arg}_${arg2 ?? 'raw'}',
    'charts' => arg ?? 'ZZ',
    _ => arg ?? 'raw',
  };
  await _writeJson('${endpoint}_$suffix', data);
}
