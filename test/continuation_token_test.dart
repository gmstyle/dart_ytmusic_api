import 'package:dart_ytmusic_api/utils/continuation_token.dart';
import 'package:test/test.dart';

void main() {
  group('longestContinuationToken', () {
    test('prefers the longest string among mixed continuation values', () {
      final short = 'x' * 80;
      final long = 'y' * 510;
      final mixed = [
        {'reloadContinuationData': short},
        short,
        long,
        short,
        {'reloadContinuationData': 'z' * 72},
      ];

      expect(longestContinuationToken(mixed), long);
    });

    test('ignores maps and empty strings', () {
      expect(
        longestContinuationToken([
          {'reloadContinuationData': 'abc'},
          '',
          {'continuation': 'nested-map-ignored'},
        ]),
        isNull,
      );
    });

    test('returns null when continuation is absent', () {
      expect(longestContinuationToken(null), isNull);
      expect(longestContinuationToken([]), isNull);
    });

    test('unwraps a single string', () {
      expect(longestContinuationToken('only-token'), 'only-token');
    });

    test('nested lists are flattened', () {
      expect(
        longestContinuationToken([
          [
            'short',
            ['much-longer-token'],
          ],
        ]),
        'much-longer-token',
      );
    });
  });

  group('shouldFollowContinuationToken', () {
    test('stops the loop on a repeated token', () {
      const token = 'same-token';
      expect(shouldFollowContinuationToken(token, token), isFalse);
    });

    test('continues when the token is new', () {
      expect(shouldFollowContinuationToken('next', 'prev'), isTrue);
      expect(shouldFollowContinuationToken('first', null), isTrue);
    });

    test('stops when the token is missing', () {
      expect(shouldFollowContinuationToken(null, 'prev'), isFalse);
      expect(shouldFollowContinuationToken('', 'prev'), isFalse);
    });
  });
}
