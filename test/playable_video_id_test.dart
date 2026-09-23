import 'package:dart_ytmusic_api/utils/playable_video_id.dart';
import 'package:test/test.dart';

void main() {
  group('playableVideoIdFromWatchHtml', () {
    test('returns redirected id from rel=canonical before href', () {
      const html = '''
<html><head>
<link rel="canonical" href="https://music.youtube.com/watch?v=K2tbQ_g2VbQ">
</head></html>
''';
      expect(
        playableVideoIdFromWatchHtml(html, 'LS3BFjgkou8'),
        'K2tbQ_g2VbQ',
      );
    });

    test('returns redirected id from href before rel=canonical', () {
      const html = '''
<link href="https://music.youtube.com/watch?v=K2tbQ_g2VbQ" rel="canonical">
''';
      expect(
        playableVideoIdFromWatchHtml(html, 'LS3BFjgkou8'),
        'K2tbQ_g2VbQ',
      );
    });

    test('returns null when canonical matches requested id', () {
      const html = '''
<link rel="canonical" href="https://music.youtube.com/watch?v=LS3BFjgkou8">
''';
      expect(playableVideoIdFromWatchHtml(html, 'LS3BFjgkou8'), isNull);
    });

    test('returns null when canonical is missing', () {
      const html = '<html><head></head></html>';
      expect(playableVideoIdFromWatchHtml(html, 'LS3BFjgkou8'), isNull);
    });
  });
}
