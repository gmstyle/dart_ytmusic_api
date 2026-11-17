import 'package:cookie_jar/cookie_jar.dart';
import 'package:dart_ytmusic_api/parsers/parser.dart';
import 'package:dart_ytmusic_api/parsers/song_parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/auth_cookies.dart';
import 'package:dart_ytmusic_api/utils/sapisid.dart';
import 'package:test/test.dart';

void main() {
  group('authorizationHeader', () {
    test('returns null without SAPISID', () {
      expect(authorizationHeader({}, 'https://music.youtube.com'), isNull);
    });

    test('builds SAPISIDHASH for a known vector', () {
      final header = authorizationHeader({
        'SAPISID': 'test-sapisid',
      }, 'https://music.youtube.com');
      expect(header, isNotNull);
      expect(header!.startsWith('SAPISIDHASH '), isTrue);
      final body = header.substring('SAPISIDHASH '.length);
      final parts = body.split('_');
      expect(parts.length, 2);
      expect(int.tryParse(parts[0]), isNotNull);
      expect(parts[1].length, 40);
    });

    test('includes 1P and 3P hashes when present', () {
      final header = authorizationHeader({
        'SAPISID': 'a',
        '__Secure-1PAPISID': 'b',
        '__Secure-3PAPISID': 'c',
      }, 'https://www.youtube.com')!;
      expect(header.contains('SAPISIDHASH '), isTrue);
      expect(header.contains('SAPISID1PHASH '), isTrue);
      expect(header.contains('SAPISID3PHASH '), isTrue);
    });

    test('appends _u when userSessionId is set', () {
      final header = authorizationHeader(
        {'SAPISID': 'a'},
        'https://music.youtube.com',
        userSessionId: '123',
      )!;
      expect(header.contains('_u'), isTrue);
    });
  });

  group('jarHasAuth', () {
    test('detects SAPISID', () {
      expect(jarHasAuth({'SAPISID': 'x'}), isTrue);
      expect(jarHasAuth({'SOCS': 'CAI'}), isFalse);
    });
  });

  group('jarHasLoginInfo', () {
    test('requires non-empty LOGIN_INFO', () {
      expect(jarHasLoginInfo({'SAPISID': 'x'}), isFalse);
      expect(jarHasLoginInfo({'LOGIN_INFO': ''}), isFalse);
      expect(jarHasLoginInfo({'LOGIN_INFO': 'token'}), isTrue);
    });
  });

  group('filterYoutubeSessionCookies', () {
    test('keeps SAPISID and drops Google Accounts cookies', () {
      final filtered = filterYoutubeSessionCookies([
        Cookie('SAPISID', 'a')..domain = '.youtube.com',
        Cookie('LOGIN_INFO', 'b')..domain = '.youtube.com',
        Cookie('LSID', 'c')..domain = '.youtube.com',
        Cookie('ACCOUNT_CHOOSER', 'd')..domain = '.youtube.com',
        Cookie('__Host-GAPS', 'e')..domain = '.youtube.com',
      ]);
      expect(filtered.map((c) => c.name), ['SAPISID', 'LOGIN_INFO']);
    });
  });

  group('applyAuthCookies SOCS', () {
    test('forces SOCS=CAI over a login-exported value', () async {
      final jar = CookieJar();
      await applyAuthCookies(jar, [
        Cookie('SAPISID', 'x')..domain = '.youtube.com',
        Cookie('SOCS', 'CAAaBgiAj-nXBg')..domain = '.youtube.com',
      ]);
      final music = await loadCookieMap(jar, kMusicOrigin);
      expect(music['SOCS'], kYtSocsConsentValue);
      expect(music['SAPISID'], 'x');
    });
  });

  group('parseCookieHeader', () {
    test('splits name=value pairs', () {
      final cookies = parseCookieHeader('SAPISID=abc; SOCS=CAI');
      expect(cookies.map((c) => c.name), containsAll(['SAPISID', 'SOCS']));
    });
  });

  group('parseSetCookieHeaders', () {
    test('parses multiple Set-Cookie values including LOGIN_INFO', () {
      final cookies = parseSetCookieHeaders([
        'LOGIN_INFO=abc; Path=/; Domain=.youtube.com; Secure; HttpOnly',
        'SAPISID=xyz; Path=/; Domain=.youtube.com; Secure',
        'YSC=token; Path=/; Domain=.youtube.com',
      ]);
      expect(
        cookies.map((c) => c.name),
        containsAll(['LOGIN_INFO', 'SAPISID', 'YSC']),
      );
    });

    test('skips malformed entries', () {
      final cookies = parseSetCookieHeaders(['not-a-cookie', 'OK=1; Path=/']);
      expect(cookies.map((c) => c.name), ['OK']);
    });

    test('usableSetCookies drops empty and Max-Age=0 auth wipes', () {
      final cookies = parseSetCookieHeaders([
        'SAPISID=; Path=/; Domain=.youtube.com; Max-Age=0',
        'SAPISID=keepme; Path=/; Domain=.youtube.com; Secure',
        'SID=; Max-Age=0; Path=/',
      ]);
      final usable = usableSetCookies(cookies);
      expect(usable.map((c) => c.name), ['SAPISID']);
      expect(usable.single.value, 'keepme');
    });
  });

  group('AccountInfo.fromAccountMenu', () {
    test('parses activeAccountHeaderRenderer', () {
      final info = AccountInfo.fromAccountMenu({
        'actions': [
          {
            'openPopupAction': {
              'popup': {
                'multiPageMenuRenderer': {
                  'header': {
                    'activeAccountHeaderRenderer': {
                      'accountName': {'simpleText': 'Mock Account'},
                      'email': {'simpleText': 'mock@test.dev'},
                      'channelHandle': {'simpleText': '@mocktest'},
                      'accountPhoto': {
                        'thumbnails': [
                          {'url': 'https://yt3.ggpht.com/photo=s88'},
                        ],
                      },
                    },
                  },
                },
              },
            },
          },
        ],
      });
      expect(info, isNotNull);
      expect(info!.name, 'Mock Account');
      expect(info.email, 'mock@test.dev');
      expect(info.channelHandle, '@mocktest');
      expect(info.photoUrl, 'https://yt3.ggpht.com/photo=s88');
    });

    test('returns null without header', () {
      expect(AccountInfo.fromAccountMenu({'actions': []}), isNull);
    });

    test('toMap/fromMap round-trip', () {
      final info = AccountInfo(
        name: 'Gabriele',
        email: 'g@example.com',
        channelHandle: '@g',
        photoUrl: 'https://yt3.ggpht.com/x',
      );
      final again = AccountInfo.fromMap(info.toMap());
      expect(again?.name, 'Gabriele');
      expect(again?.email, 'g@example.com');
      expect(again?.channelHandle, '@g');
      expect(again?.photoUrl, 'https://yt3.ggpht.com/x');
    });
  });

  group('SongParser home two-row', () {
    test('parses musicTwoRowItemRenderer without flexColumns', () {
      final item = {
        'musicTwoRowItemRenderer': {
          'title': {
            'runs': [
              {
                'text': 'Test Song',
                'navigationEndpoint': {
                  'watchEndpoint': {'videoId': 'abcdefghijk'},
                },
              },
            ],
          },
          'subtitle': {
            'runs': [
              {
                'text': 'Artist',
                'navigationEndpoint': {
                  'browseEndpoint': {
                    'browseId': 'UCxxxxxxxx',
                    'browseEndpointContextSupportedConfigs': {
                      'browseEndpointContextMusicConfig': {
                        'pageType': 'MUSIC_PAGE_TYPE_ARTIST',
                      },
                    },
                  },
                },
              },
            ],
          },
          'thumbnailRenderer': {
            'musicThumbnailRenderer': {
              'thumbnail': {
                'thumbnails': [
                  {
                    'url': 'https://example.com/t.jpg',
                    'width': 60,
                    'height': 60,
                  },
                ],
              },
            },
          },
          'navigationEndpoint': {
            'watchEndpoint': {'videoId': 'abcdefghijk'},
          },
        },
      };
      final song = SongParser.parseHomeSection(item);
      expect(song.videoId, 'abcdefghijk');
      expect(song.name, 'Test Song');
      expect(song.artists.map((a) => a.name), ['Artist']);
    });

    test('home shelf skips empty song shape without crashing', () {
      final section = Parser.parseHomeSection({
        'header': {
          'title': {
            'runs': [
              {'text': 'Quick picks'},
            ],
          },
        },
        'contents': [
          {
            'musicTwoRowItemRenderer': {
              'title': {
                'runs': [
                  {
                    'text': 'Ok',
                    'navigationEndpoint': {
                      'watchEndpoint': {'videoId': 'abcdefghijk'},
                    },
                  },
                ],
              },
              'navigationEndpoint': {
                'watchEndpoint': {'videoId': 'abcdefghijk'},
              },
            },
          },
        ],
      });
      expect(section.title, 'Quick picks');
      expect(section.contents, isNotEmpty);
    });
  });
}
