// ignore_for_file: avoid_print
//
// Debug utility to inspect the *raw* Innertube JSON responses returned by
// YouTube Music, so new/undocumented fields can be discovered and compared
// against what the parsers in lib/parsers currently extract.
//
// This formalizes the same idea as the disabled `_writeRawResponse` calls
// found throughout lib/yt_music.dart, but as a standalone script that
// doesn't need to be wired into (and temporarily un-commented from) the
// library itself.
//
// Usage (run from the package root):
//   dart run tool/dump_raw.dart search "Eminem Kill You"
//   dart run tool/dump_raw.dart player dQw4w9WgXcQ
//   dart run tool/dump_raw.dart next dQw4w9WgXcQ
//   dart run tool/dump_raw.dart browse UCuAXFkgsw1L7xaCfnd5JJOw   # artist/album/playlist browseId
//   dart run tool/dump_raw.dart home
//
// Output is written as pretty-printed JSON to tool/output/<endpoint>_<arg>.json
// (the output/ directory is gitignored and safe to delete at any time).
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

void main(List<String> args) async {
  if (args.isEmpty) {
    print(
      'Usage: dart run tool/dump_raw.dart <search|player|next|browse|home> [arg]',
    );
    exit(64);
  }

  final endpoint = args[0];
  final arg = args.length > 1 ? args[1] : null;

  final yt = await YTMusic().initialize();

  dynamic data;
  switch (endpoint) {
    case 'search':
      if (arg == null)
        throw ArgumentError(
          'search requires a query, e.g. dart run tool/dump_raw.dart search "query"',
        );
      data = await yt.constructRequest(
        'search',
        body: {'query': arg, 'params': null},
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
      if (arg == null)
        throw ArgumentError(
          'browse requires a browseId (artist/album/playlist)',
        );
      data = await yt.constructRequest('browse', body: {'browseId': arg});
      break;
    case 'home':
      data = await yt.constructRequest(
        'browse',
        body: {'browseId': feMusicHome},
      );
      break;
    default:
      throw ArgumentError('Unknown endpoint: $endpoint');
  }

  await _writeJson('${endpoint}_${arg ?? 'raw'}', data);
}
