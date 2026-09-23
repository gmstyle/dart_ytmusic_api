import 'dart:convert';
import 'dart:io';

import 'package:dart_ytmusic_api/parsers/song_parser.dart';
import 'package:dart_ytmusic_api/parsers/video_parser.dart';
import 'package:dart_ytmusic_api/parsers/watch_parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/artists.dart';
import 'package:test/test.dart';

dynamic _json(String name) =>
    json.decode(File('test/fixtures/$name').readAsStringSync());

List<String> _names(List<ArtistBasic> artists) =>
    artists.map((a) => a.name).toList();

void main() {
  group('ArtistBasic.formatNames', () {
    test('joins collaborations like YouTube Music', () {
      expect(ArtistBasic.formatNames(const []), '');
      expect(ArtistBasic.formatNames([ArtistBasic(name: 'Emma')]), 'Emma');
      expect(
        ArtistBasic.formatNames([
          ArtistBasic(name: 'Emma'),
          ArtistBasic(name: 'Fabri Fibra'),
        ]),
        'Emma & Fabri Fibra',
      );
      expect(
        ArtistBasic.formatNames([
          ArtistBasic(name: 'Ernia'),
          ArtistBasic(name: 'Bresh'),
          ArtistBasic(name: 'Fabri Fibra'),
        ]),
        'Ernia, Bresh & Fabri Fibra',
      );
    });
  });

  group('artistsFromMap', () {
    test('reads a list of artists', () {
      final artists = artistsFromMap({
        'artists': [
          {'name': 'Emma', 'artistId': 'UC1'},
          {'name': 'Fabri Fibra', 'artistId': 'UC2'},
        ],
      });
      expect(_names(artists), ['Emma', 'Fabri Fibra']);
    });

    test('falls back to legacy singular artist', () {
      final artists = artistsFromMap({
        'artist': {'name': 'Emma', 'artistId': 'UC1'},
      });
      expect(_names(artists), ['Emma']);
    });

    test('falls back to legacy singular UpNextsDetails.artists map', () {
      final artists = artistsFromMap({
        'artists': {'name': 'Emma', 'artistId': 'UC1'},
      });
      expect(_names(artists), ['Emma']);
    });
  });

  group('search parsers', () {
    test('ANTIDROGA search result exposes Emma and Fabri Fibra', () {
      final wrapped = _json('search_song_antidroga.json');
      final item = wrapped['musicResponsiveListItemRenderer'];
      final song = SongParser.parseSearchResult(item);
      expect(song.name, 'ANTIDROGA');
      expect(_names(song.artists), ['Emma', 'Fabri Fibra']);
      expect(song.artists[0].artistId, 'UCzH13CnhFKwTJ1i0A2394ew');
      expect(song.artists[1].artistId, 'UCugfYxXut2pGCiYtDIiI81Q');
      // ignore: deprecated_member_use_from_same_package
      expect(song.artist.name, 'Emma');
    });

    test('Propaganda search result exposes three artists', () {
      final wrapped = _json('search_song_propaganda.json');
      final item = wrapped['musicResponsiveListItemRenderer'];
      final song = SongParser.parseSearchResult(item);
      expect(song.name, 'Propaganda');
      expect(_names(song.artists), ['Fabri Fibra', 'Colapesce', 'Dimartino']);
    });
  });

  group('watch parser', () {
    test('parses collaborations from longBylineText', () {
      final tracks = (_json('next_tracks_sample.json') as List)
          .map(WatchParser.parseWatchTrack)
          .whereType<WatchTrack>()
          .toList();
      expect(tracks, isNotEmpty);
      expect(tracks[0].title, 'ANTIDROGA');
      expect(_names(tracks[0].artists), ['Emma', 'Fabri Fibra']);
      expect(_names(tracks[1].artists), ['Emma', 'Rkomi']);
      expect(_names(tracks[2].artists), ['Ernia', 'Bresh', 'Fabri Fibra']);
    });
  });

  group('album parser', () {
    test('strapline and inherited track credits', () {
      final fixture = _json('album_antidroga_header_and_track.json');
      final headerArtists = parseArtistsFromStrapline(fixture['header']);
      expect(_names(headerArtists), ['Emma', 'Fabri Fibra']);

      final track = SongParser.parseAlbumSong(
        fixture['track'],
        headerArtists,
        AlbumBasic(albumId: 'MPREb_L3vxjEHJMsL', name: 'ANTIDROGA'),
        const [],
      );
      expect(track.name, 'ANTIDROGA');
      expect(_names(track.artists), ['Emma', 'Fabri Fibra']);
      expect(track.isPlayable, isTrue);
    });

    test('greyed-out track keeps title and artist without album fallback', () {
      final item = _json('album_greyed_out_track.json');
      final track = SongParser.parseAlbumSong(
        item,
        [
          ArtistBasic(
            name: "Dawson's Creek (Television Soundtrack)",
            artistId: 'UC_album',
          ),
        ],
        AlbumBasic(
          albumId: 'MPREb_3yuzFdjEJfI',
          name: "Songs from Dawson's Creek",
        ),
        const [],
      );
      expect(track.name, 'Kiss Me');
      expect(track.videoId, 'LS3BFjgkou8');
      expect(_names(track.artists), ['Sixpence None The Richer']);
      expect(track.artists.single.artistId, isNull);
      expect(track.isPlayable, isFalse);
      expect(track.duration, 198);
    });
  });

  group('playlist parser', () {
    test('greyed-out row keeps playlistItemData videoId', () {
      final item = _json('playlist_greyed_out_track.json');
      final video = VideoParser.parsePlaylistVideo(item);
      expect(video, isNotNull);
      expect(video!.name, 'Unavailable Track');
      expect(video.videoId, 'abcdefghijk');
      expect(_names(video.artists), ['Some Artist']);
      expect(video.isPlayable, isFalse);
    });
  });

  group('artist page parsers', () {
    test('top songs keep featured artists', () {
      final shelf = _json('artist_emma_top_songs.json');
      final pageArtist = ArtistBasic(
        name: 'Emma',
        artistId: 'UCzH13CnhFKwTJ1i0A2394ew',
      );
      final songs = (shelf['contents'] as List)
          .map(
            (item) => SongParser.parseArtistTopSong(
              item['musicResponsiveListItemRenderer'],
              pageArtist,
            ),
          )
          .toList();
      final byName = {for (final s in songs) s.name: s};
      expect(_names(byName['ANTIDROGA']!.artists), ['Emma', 'Fabri Fibra']);
      expect(_names(byName['Juste un peu']!.artists), ['Jungeli', 'EMMA']);
      expect(_names(byName["L'Amore Non Mi Basta"]!.artists), ['Emma']);
    });

    test('top video subtitle lists collaborators', () {
      final item = _json('artist_emma_video_antidroga.json');
      final video = VideoParser.parseArtistTopVideo(
        item,
        ArtistBasic(name: 'Emma', artistId: 'UCzH13CnhFKwTJ1i0A2394ew'),
      );
      expect(video.name, 'ANTIDROGA');
      expect(_names(video.artists), ['Emma', 'Fabri Fibra']);
    });
  });

  test('deprecated constructor artist still fills artists', () {
    final song = SongDetailed(
      type: 'SONG',
      videoId: 'abc',
      name: 'x',
      // ignore: deprecated_member_use_from_same_package
      artist: ArtistBasic(name: 'Emma'),
      thumbnails: const [],
    );
    expect(_names(song.artists), ['Emma']);
  });
}
