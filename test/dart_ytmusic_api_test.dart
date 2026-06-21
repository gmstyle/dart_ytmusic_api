import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:dart_ytmusic_api/parsers/playlist_parser.dart';

void main() {
  test(
    'Playlist parser should parse playlist details and video counts correctly',
    () async {
      final file1 = File('example/getPlaylistRaw1.txt');
      final content1 = await file1.readAsString();
      final lines1 = content1.split('\n');
      final jsonStartIndex1 = lines1.indexWhere(
        (line) => line.trim().startsWith('{'),
      );
      final jsonContent1 = lines1.sublist(jsonStartIndex1).join('\n');
      final data1 = jsonDecode(jsonContent1);
      final playlist1 = PlaylistParser.parse(
        data1,
        'PLKTP4Gcm8E4Z1dlZuBHP-W94yN3kqR3t0',
      );

      expect(playlist1.videoCount, equals(91));
      expect(
        playlist1.name,
        equals(
          'Best Of R&B MIX 90s 2000s - 2023 | Rihanna, Usher, Chris Brown, Beyonce, Ne Yo, Nelly',
        ),
      );

      final file2 = File('example/getPlaylistRaw2.txt');
      final content2 = await file2.readAsString();
      final lines2 = content2.split('\n');
      final jsonStartIndex2 = lines2.indexWhere(
        (line) => line.trim().startsWith('{'),
      );
      final jsonContent2 = lines2.sublist(jsonStartIndex2).join('\n');
      final data2 = jsonDecode(jsonContent2);
      final playlist2 = PlaylistParser.parse(
        data2,
        'RDCLAK5uy_mX4JK0m7lhZ8Egv1E7bbXox_e0k6rGejo',
      );

      expect(playlist2.videoCount, equals(117));
      expect(playlist2.name, equals('Chill R&B'));
    },
  );
}
