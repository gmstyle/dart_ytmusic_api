import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/filters.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';

/// Collects every credited artist from Innertube `runs` (flex columns, bylines,
/// straplines, subtitles).
///
/// YouTube Music encodes collaborations as consecutive runs with
/// `MUSIC_PAGE_TYPE_ARTIST` (or `MUSIC_PAGE_TYPE_USER_CHANNEL`), separated by
/// plain text runs such as `" & "` and `", "`.
List<ArtistBasic> parseArtistRuns(dynamic runs) {
  final list = runs is List
      ? runs.expand((e) => e is Iterable ? e : [e]).toList()
      : (runs == null ? const <dynamic>[] : [runs]);

  final artists = <ArtistBasic>[];
  final seen = <String>{};
  for (final run in list) {
    if (!isArtist(run)) continue;
    final name = traverseString(run, ['text']) ?? '';
    if (name.isEmpty) continue;
    final artistId = traverseString(run, ['browseId']);
    final key = '${artistId ?? ''}|$name';
    if (!seen.add(key)) continue;
    artists.add(ArtistBasic(name: name, artistId: artistId));
  }
  return artists;
}

/// Artists listed in `flexColumns` of a `musicResponsiveListItemRenderer`.
List<ArtistBasic> parseArtistsFromFlexColumns(dynamic item) {
  return parseArtistRuns(traverseList(item, ['flexColumns', 'runs']));
}

/// Artists listed in a two-row card `subtitle`.
List<ArtistBasic> parseArtistsFromSubtitle(dynamic item) {
  return parseArtistRuns(traverseList(item, ['subtitle', 'runs']));
}

/// Artists listed in an album/playlist header strapline.
List<ArtistBasic> parseArtistsFromStrapline(dynamic data) {
  return parseArtistRuns(traverseList(data, ['straplineTextOne', 'runs']));
}

/// Prefers parsed [artists], otherwise a single [fallback] (page owner, etc.).
List<ArtistBasic> artistsOrFallback(
  List<ArtistBasic> artists,
  ArtistBasic fallback,
) {
  return artists.isNotEmpty ? artists : [fallback];
}
