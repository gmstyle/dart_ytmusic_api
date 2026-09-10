// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';

void main(List<String> args) async {
  final yt = YTMusic();
  await yt.initialize();

  String artistId;
  if (args.isNotEmpty) {
    artistId = args.first;
  } else {
    final artists = await yt.searchArtists('Coldplay');
    artistId = artists.first.artistId;
    print('Using ${artists.first.name} → $artistId');
  }

  final artistData = await yt.constructRequest(
    'browse',
    body: {'browseId': artistId},
  );
  final carousels = traverseList(artistData, ['musicCarouselShelfRenderer']);
  final videosCarousels = ArtistParser.findAllCarousels(
    carousels,
    ArtistParser.isVideos,
  );
  print('videos carousels: ${videosCarousels.length}');
  for (final c in videosCarousels) {
    print('  title: ${ArtistParser.carouselTitle(c)}');
    print('  contents: ${ArtistParser.parseCarouselContents(c).length}');
  }

  if (videosCarousels.isEmpty) {
    print('No video carousels');
    exit(1);
  }

  final browseBody = traverse(videosCarousels.first, [
    'moreContentButton',
    'browseEndpoint',
  ]);
  print('browseBody runtimeType: ${browseBody.runtimeType}');
  if (browseBody is Map) {
    print('browseBody keys: ${browseBody.keys.toList()}');
    print(const JsonEncoder.withIndent('  ').convert(browseBody));
  } else {
    print('browseBody: $browseBody');
  }

  if (browseBody is Map<String, dynamic>) {
    final videosData = await yt.constructRequest('browse', body: browseBody);
    final twoRow = traverseList(videosData, ['musicTwoRowItemRenderer']);
    final responsive = traverseList(videosData, [
      'musicResponsiveListItemRenderer',
    ]);
    print('musicTwoRowItemRenderer: ${twoRow.length}');
    print('musicResponsiveListItemRenderer: ${responsive.length}');

    // Collect top-level renderer type keys under contents
    final keys = <String>{};
    void walk(dynamic n, [int depth = 0]) {
      if (depth > 12) return;
      if (n is Map) {
        for (final e in n.entries) {
          final k = e.key.toString();
          if (k.endsWith('Renderer') || k.endsWith('Item')) keys.add(k);
          walk(e.value, depth + 1);
        }
      } else if (n is List) {
        for (final v in n.take(30)) {
          walk(v, depth + 1);
        }
      }
    }

    walk(videosData);
    final interesting = keys.where(
      (k) =>
          k.contains('music') ||
          k.contains('Video') ||
          k.contains('Grid') ||
          k.contains('Shelf') ||
          k.contains('Item'),
    );
    print('renderer keys: ${interesting.toList()..sort()}');

    final dir = Directory('tool/output');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    await File(
      'tool/output/artist_videos_browse_$artistId.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(videosData));
    print('wrote tool/output/artist_videos_browse_$artistId.json');
  }

  final parsed = await yt.getArtistVideos(artistId);
  print('getArtistVideos → ${parsed.length}');
  for (final v in parsed.take(5)) {
    print('  ${v.name} (${v.videoId})');
  }

  final artist = await yt.getArtist(artistId);
  print('artist.topVideos → ${artist.topVideos.length}');
}
