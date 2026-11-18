import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  group('YTMusic session config and auth headers', () {
    const sampleHtml = '''
<!doctype html><html><head><script>
ytcfg.set({
  "VISITOR_DATA": "CgtsZWFk",
  "USER_SESSION_ID": "12345",
  "SESSION_INDEX": 2,
  "DELEGATED_SESSION_ID": "delegated-page-id",
  "DATASYNC_ID": "ds-1",
  "LOGGED_IN": true,
  "STS": 20123,
  "INNERTUBE_API_KEY": "test-key",
  "INNERTUBE_CLIENT_VERSION": "1.20260707.12.00"
});
</script></head><body></body></html>
''';

    test(
      'extracts session fields and sends auth headers when signed in',
      () async {
        final recordedRequests = <http.Request>[];
        final mockClient = MockClient((req) async {
          recordedRequests.add(req);
          if (req.url.path.endsWith('/player')) {
            return http.Response(
              jsonEncode({
                'videoDetails': {
                  'videoId': 'abcdefghijk',
                  'title': 'Song',
                  'author': 'Artist',
                  'lengthSeconds': '180',
                  'channelId': 'UC123',
                },
              }),
              200,
              headers: {
                'set-cookie':
                    'SAPISID=; Max-Age=0; Path=/; Domain=.youtube.com, '
                    'SIDCC=rotated-sidcc; Path=/; Domain=.youtube.com; Secure',
              },
            );
          }
          return http.Response('{}', 200);
        });

        final yt = YTMusic.withClient(httpClient: mockClient);
        await applyAuthCookies(yt.cookieJar, [
          Cookie('SAPISID', 'secret-sapisid')..domain = '.youtube.com',
          Cookie('LOGIN_INFO', 'login-token')..domain = '.youtube.com',
        ]);
        await yt.initialize(ytMusicHomeRawHtml: sampleHtml);

        expect(yt.config['SESSION_INDEX'], '2');
        expect(yt.config['DELEGATED_SESSION_ID'], 'delegated-page-id');
        expect(yt.config['DATASYNC_ID'], 'ds-1');
        expect(yt.config['LOGGED_IN'], 'true');
        expect(yt.config['STS'], '20123');

        await yt.getSong('abcdefghijk');

        final playerReq = recordedRequests.firstWhere(
          (r) => r.url.path.endsWith('/player'),
        );
        expect(playerReq.headers['Authorization'], contains('SAPISIDHASH '));
        expect(playerReq.headers['Authorization'], contains('_u'));
        expect(playerReq.headers['X-Youtube-Bootstrap-Logged-In'], 'true');
        expect(playerReq.headers['X-Goog-AuthUser'], '2');
        expect(playerReq.headers['X-Goog-PageId'], 'delegated-page-id');

        final playerBody = jsonDecode(playerReq.body) as Map<String, dynamic>;
        expect(playerBody['contentCheckOk'], isTrue);
        expect(playerBody['racyCheckOk'], isTrue);

        final updatedCookies = await loadCookieMap(yt.cookieJar, kMusicOrigin);
        expect(updatedCookies['SAPISID'], 'secret-sapisid');
        expect(updatedCookies['SIDCC'], 'rotated-sidcc');
      },
    );

    test('omits auth headers when signed out', () async {
      final recordedRequests = <http.Request>[];
      final mockClient = MockClient((req) async {
        recordedRequests.add(req);
        return http.Response('{}', 200);
      });

      final yt = YTMusic.withClient(httpClient: mockClient);
      await yt.initialize(ytMusicHomeRawHtml: sampleHtml);
      await yt.constructRequest('browse', body: {'browseId': 'FEmusic_home'});

      final req = recordedRequests.single;
      expect(req.headers.containsKey('Authorization'), isFalse);
      expect(req.headers.containsKey('X-Youtube-Bootstrap-Logged-In'), isFalse);
      expect(req.headers.containsKey('x-goog-authuser'), isFalse);
      expect(req.headers.containsKey('X-Goog-AuthUser'), isFalse);
      expect(req.headers.containsKey('X-Goog-PageId'), isFalse);
    });
  });
}
