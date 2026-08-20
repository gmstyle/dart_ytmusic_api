import 'dart:convert';
import 'dart:isolate';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dart_ytmusic_api/enums.dart';
import 'package:dart_ytmusic_api/parsers/album_parser.dart';
import 'package:dart_ytmusic_api/parsers/artist_parser.dart';
import 'package:dart_ytmusic_api/parsers/explore_parser.dart';
import 'package:dart_ytmusic_api/parsers/parser.dart';
import 'package:dart_ytmusic_api/parsers/playlist_parser.dart';
import 'package:dart_ytmusic_api/parsers/podcast_parser.dart';
import 'package:dart_ytmusic_api/parsers/related_parser.dart';
import 'package:dart_ytmusic_api/parsers/search_parser.dart';
import 'package:dart_ytmusic_api/parsers/song_parser.dart';
import 'package:dart_ytmusic_api/parsers/user_parser.dart';
import 'package:dart_ytmusic_api/parsers/video_parser.dart';
import 'package:dart_ytmusic_api/parsers/watch_parser.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:dart_ytmusic_api/utils/filters.dart';
import 'package:dart_ytmusic_api/utils/traverse.dart';
import 'package:http/http.dart' as http;

class YTMusic {
  static final YTMusic _instance = YTMusic._internal();

  factory YTMusic() {
    return _instance;
  }

  YTMusic._internal() {
    cookieJar = CookieJar();
    config = {};
    _client = http.Client();
    _baseHeaders = {
      "User-Agent":
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36",
      "Accept":
          "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      "Accept-Language": "en-US,en;q=0.9",
      "sec-ch-ua":
          '"Chromium";v="148", "Google Chrome";v="148", "Not/A)Brand";v="99"',
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": '"Linux"',
    };
  }

  late CookieJar cookieJar;
  late Map<String, String> config;
  late http.Client _client;
  late Map<String, String> _baseHeaders;
  bool hasInitialized = false;
  String? ytMusicHomeRawHtml;

  /// Initializes the YTMusic instance with provided cookies, geolocation, and language.
  Future<YTMusic> initialize({
    String? cookies,
    String? gl,
    String? hl,
    String? ytMusicHomeRawHtml,
  }) async {
    // Start initialization

    if (hasInitialized) {
      return this;
    }

    // Accept optional pre-fetched HTML
    this.ytMusicHomeRawHtml = ytMusicHomeRawHtml;
    if (ytMusicHomeRawHtml != null) {}

    // Process incoming cookies string if provided
    if (cookies != null) {
      for (final cookieString in cookies.split('; ')) {
        try {
          final cookie = Cookie.fromSetCookieValue(cookieString);
          cookieJar.saveFromResponse(Uri.parse('https://www.youtube.com/'), [
            cookie,
          ]);
        } catch (e) {
          //
        }
      }
    } else {}

    // Fetch configuration from YouTube Music homepage (or provided HTML)
    await fetchConfig();

    // Override GL/HL if user supplied them explicitly
    if (gl != null) {
      config['GL'] = gl;
    }
    if (hl != null) {
      config['HL'] = hl;
    }

    hasInitialized = true;

    return this;
  }

  /// Fetches the configuration data required for API requests.
  Future<void> fetchConfig() async {
    // Hardcoded fallbacks — stable values that rarely/never change.
    // INNERTUBE_CLIENT_VERSION is the only one that drifts; we try to extract
    // it from the homepage HTML below and fall back to this known-good value.
    config['INNERTUBE_API_VERSION'] = 'v1';
    config['INNERTUBE_CLIENT_NAME'] = 'WEB_REMIX';
    config['INNERTUBE_CONTEXT_CLIENT_NAME'] = '67';
    config['INNERTUBE_CLIENT_VERSION'] = '1.20260505.09.00';
    config['INNERTUBE_API_KEY'] = '';
    config['VISITOR_DATA'] = '';
    config['GL'] = 'US';
    config['HL'] = 'en';
    config['DEVICE'] = '';
    config['PAGE_CL'] = '';
    config['PAGE_BUILD_LABEL'] = '';

    late final String html;
    final uri = Uri.parse("https://music.youtube.com/");
    if (ytMusicHomeRawHtml != null) {
      html = ytMusicHomeRawHtml!;
    } else {
      final cookies = await cookieJar.loadForRequest(uri);
      final cookieString = cookies
          .map((cookie) => '${cookie.name}=${cookie.value}')
          .join('; ');
      final headers = {
        ..._baseHeaders,
        'upgrade-insecure-requests': '1',
        'sec-fetch-dest': 'document',
        'sec-fetch-mode': 'navigate',
        'sec-fetch-site': 'none',
        'sec-fetch-user': '?1',
      };
      // SOCS=CAI bypasses Google's cookie-consent gate, which otherwise
      // causes YouTube Music to serve the "deprecated browser" fallback page.
      const socsCookie = 'SOCS=CAI';
      headers['cookie'] = cookieString.isNotEmpty
          ? '$cookieString; $socsCookie'
          : socsCookie;
      try {
        final response = await _client.get(uri, headers: headers);
        _saveCookiesFromHeaders(uri, response.headers);
        html = response.body;
      } catch (e) {
        print('Warning: failed to fetch YouTube Music homepage: $e');
        return; // use fallback config as-is
      }
    }

    if (html.contains('not optimized for your browser')) {
      print(
        'Warning: YouTube Music returned a compatibility warning page — using hardcoded fallback config',
      );
      return; // fallbacks already set above
    }

    final ytcfg = _parseAllYtcfgBlocks(html);
    for (final key in const [
      'VISITOR_DATA',
      'INNERTUBE_CONTEXT_CLIENT_NAME',
      'INNERTUBE_CLIENT_VERSION',
      'DEVICE',
      'PAGE_CL',
      'PAGE_BUILD_LABEL',
      'INNERTUBE_API_KEY',
      'INNERTUBE_API_VERSION',
      'INNERTUBE_CLIENT_NAME',
      'GL',
      'HL',
    ]) {
      final v = ytcfg[key];
      if (v != null) config[key] = v.toString();
    }
  }

  /// Parses all `ytcfg.set({...})` blocks in [html] and merges their entries.
  /// Blocks that are not valid JSON (e.g. single-quoted JS objects) are skipped.
  Map<String, dynamic> _parseAllYtcfgBlocks(String html) {
    final result = <String, dynamic>{};
    const marker = 'ytcfg.set(';
    var pos = 0;
    while (true) {
      final idx = html.indexOf(marker, pos);
      if (idx == -1) break;
      final start = idx + marker.length;
      if (start >= html.length || html[start] != '{') {
        pos = idx + 1;
        continue;
      }
      var depth = 0;
      var inString = false;
      var escaped = false;
      int? end;
      for (var i = start; i < html.length; i++) {
        final c = html[i];
        if (escaped) {
          escaped = false;
          continue;
        }
        if (c == '\\' && inString) {
          escaped = true;
          continue;
        }
        if (c == '"') {
          inString = !inString;
          continue;
        }
        if (inString) continue;
        if (c == '{') {
          depth++;
        } else if (c == '}' && --depth == 0) {
          end = i;
          break;
        }
      }
      if (end != null) {
        try {
          final block = json.decode(html.substring(start, end + 1));
          if (block is Map<String, dynamic>) result.addAll(block);
        } catch (_) {}
      }
      pos = (end ?? idx) + 1;
    }
    return result;
  }

  /// Constructs and performs an API request to the specified endpoint with optional body and query parameters.
  Future<dynamic> constructRequest(
    String endpoint, {
    Map<String, dynamic> body = const {},
    Map<String, String> query = const {},
    ClientRequestOptions? options,
  }) async {
    final baseUrl = "https://music.youtube.com/";
    final fullQuery = {...query, "prettyPrint": "false"};
    final apiKey = config['INNERTUBE_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      fullQuery["key"] = apiKey;
    }

    final uri = Uri.parse(baseUrl).replace(
      path: "youtubei/${config['INNERTUBE_API_VERSION']}/$endpoint",
      queryParameters: fullQuery,
    );

    final cookies = await cookieJar.loadForRequest(uri);
    final cookieString = cookies
        .map((cookie) => '${cookie.name}=${cookie.value}')
        .join('; ');

    final headers = <String, String>{
      ..._baseHeaders,
      "accept": "*/*",
      "content-type": "application/json",
      "origin": "https://music.youtube.com",
      "referer": "https://music.youtube.com/",
      "x-origin": "https://music.youtube.com",
      "x-goog-authuser": "0",
      "X-Goog-Visitor-Id": config['VISITOR_DATA'] ?? "",
      "X-YouTube-Client-Name": config['INNERTUBE_CONTEXT_CLIENT_NAME'] ?? '',
      "X-YouTube-Client-Version": config['INNERTUBE_CLIENT_VERSION'] ?? '',
      "X-YouTube-Device": config['DEVICE'] ?? '',
      "X-YouTube-Page-CL": config['PAGE_CL'] ?? '',
      "X-YouTube-Page-Label": config['PAGE_BUILD_LABEL'] ?? '',
      "X-YouTube-Utc-Offset": (-DateTime.now().timeZoneOffset.inMinutes)
          .toString(),
      "sec-fetch-dest": "empty",
      "sec-fetch-mode": "same-origin",
      "sec-fetch-site": "same-origin",
    };

    if (cookieString.isNotEmpty) {
      headers['cookie'] = cookieString;
    }

    final requestBody = {
      "context": {
        "capabilities": {},
        "client": {
          "clientName": options?.clientName ?? config['INNERTUBE_CLIENT_NAME'],
          "clientVersion":
              options?.clientVersion ?? config['INNERTUBE_CLIENT_VERSION'],
          "experimentIds": [],
          "experimentsToken": "",
          "gl": config['GL'],
          "hl": config['HL'],
          "locationInfo": {
            "locationPermissionAuthorizationStatus":
                "LOCATION_PERMISSION_AUTHORIZATION_STATUS_UNSUPPORTED",
          },
          "musicAppInfo": {
            "musicActivityMasterSwitch":
                "MUSIC_ACTIVITY_MASTER_SWITCH_INDETERMINATE",
            "musicLocationMasterSwitch":
                "MUSIC_LOCATION_MASTER_SWITCH_INDETERMINATE",
            "pwaInstallabilityStatus": "PWA_INSTALLABILITY_STATUS_UNKNOWN",
          },
          "utcOffsetMinutes": -DateTime.now().timeZoneOffset.inMinutes,
        },
        "request": {
          "internalExperimentFlags": [
            {
              "key": "force_music_enable_outertube_tastebuilder_browse",
              "value": "true",
            },
            {
              "key": "force_music_enable_outertube_playlist_detail_browse",
              "value": "true",
            },
            {
              "key": "force_music_enable_outertube_search_suggestions",
              "value": "true",
            },
          ],
          "sessionIndex": {},
        },
        "user": {"enableSafetyMode": false},
      },
      ...body,
    };

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      _saveCookiesFromHeaders(uri, response.headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Decode JSON in a separate isolate to avoid blocking the main thread
        // on large responses (e.g. playlists with hundreds of tracks).
        final jsonData = await Isolate.run(() => json.decode(response.body));
        return jsonData;
      } else {
        throw Exception(
          'Failed to make request to $uri - ${response.statusCode} - [${response.body}]',
        );
      }
    } on http.ClientException catch (e) {
      print('HTTP Client Exception during request to $uri: $e');
      rethrow;
    } catch (e) {
      print('Error during request to $uri: $e');
      rethrow;
    }
  }

  void _saveCookiesFromHeaders(Uri uri, Map<String, String> headers) {
    final setCookieHeader = headers['set-cookie'];
    if (setCookieHeader == null) return;
    try {
      final cookie = Cookie.fromSetCookieValue(setCookieHeader);
      cookieJar.saveFromResponse(uri, [cookie]);
    } catch (e) {
      //
    }
  }

  /// Retrieves search suggestions for a given query.
  Future<List<String>> getSearchSuggestions(String query) async {
    final response = await constructRequest(
      "music/get_search_suggestions",
      body: {"input": query},
    );

    return traverseList(response, ["query"]).whereType<String>().toList();
  }

  /// Performs a search for music with the given query and returns a list of search results.
  ///
  /// [limit] caps how many parsed items to return from the first page
  /// (generic search is not paginated by YouTube Music).
  Future<List<SearchResult>> search(String query, {int limit = 20}) async {
    final items = await _searchRaw(query, null, limit);
    return items
        .map(SearchParser.parse)
        .whereType<SearchResult>()
        .take(limit)
        .toList();
  }

  /// Performs a search specifically for songs with the given query and returns a list of song details.
  Future<List<SongDetailed>> searchSongs(String query, {int limit = 20}) async {
    final items = await _searchRaw(query, searchParamsSongs, limit);
    return items.map(SongParser.parseSearchResult).take(limit).toList();
  }

  /// Performs a search specifically for videos with the given query and returns a list of video details.
  Future<List<VideoDetailed>> searchVideos(
    String query, {
    int limit = 20,
  }) async {
    final items = await _searchRaw(query, searchParamsVideos, limit);
    return items.map(VideoParser.parseSearchResult).take(limit).toList();
  }

  /// Performs a search specifically for artists with the given query and returns a list of artist details.
  Future<List<ArtistDetailed>> searchArtists(
    String query, {
    int limit = 20,
  }) async {
    final items = await _searchRaw(query, searchParamsArtists, limit);
    return items.map(ArtistParser.parseSearchResult).take(limit).toList();
  }

  /// Performs a search specifically for albums with the given query and returns a list of album details.
  Future<List<AlbumDetailed>> searchAlbums(
    String query, {
    int limit = 20,
  }) async {
    final items = await _searchRaw(query, searchParamsAlbums, limit);
    return items.map(AlbumParser.parseSearchResult).take(limit).toList();
  }

  /// Performs a search specifically for playlists with the given query and returns a list of playlist details.
  Future<List<PlaylistDetailed>> searchPlaylists(
    String query, {
    int limit = 20,
  }) async {
    final items = await _searchRaw(query, searchParamsPlaylists, limit);
    return items.map(PlaylistParser.parseSearchResult).take(limit).toList();
  }

  /// Performs a search specifically for podcasts.
  Future<List<PodcastDetailed>> searchPodcasts(
    String query, {
    int limit = 20,
  }) async {
    final items = await _searchRaw(query, searchParamsPodcasts, limit);
    return items.map(PodcastParser.parseSearchResult).take(limit).toList();
  }

  /// Performs a search specifically for podcast episodes.
  Future<List<EpisodeDetailed>> searchEpisodes(
    String query, {
    int limit = 20,
  }) async {
    final items = await _searchRaw(query, searchParamsEpisodes, limit);
    return items
        .map(PodcastParser.parseEpisodeSearchResult)
        .take(limit)
        .toList();
  }

  /// Performs a search specifically for user profiles.
  Future<List<ProfileDetailed>> searchProfiles(
    String query, {
    int limit = 20,
  }) async {
    final items = await _searchRaw(query, searchParamsProfiles, limit);
    return items
        .map(PodcastParser.parseProfileSearchResult)
        .take(limit)
        .toList();
  }

  Future<List<dynamic>> _searchRaw(
    String query,
    String? params,
    int limit,
  ) async {
    final body = <String, dynamic>{'query': query};
    if (params != null) {
      body['params'] = params;
    }
    final searchData = await constructRequest('search', body: body);
    final items = List<dynamic>.from(
      traverseList(searchData, ['musicResponsiveListItemRenderer']),
    );
    if (params == null || items.length >= limit) {
      return items.take(limit).toList();
    }

    dynamic continuation = traverse(searchData, ['continuation']);
    if (continuation is List && continuation.isNotEmpty) {
      continuation = continuation[0];
    }
    while (continuation is String &&
        continuation.isNotEmpty &&
        items.length < limit) {
      final more = await constructRequest(
        'search',
        query: {'continuation': continuation},
      );
      items.addAll(traverseList(more, ['musicResponsiveListItemRenderer']));
      final next = traverse(more, ['continuation']);
      if (next is String) {
        continuation = next;
      } else if (next is List && next.isNotEmpty) {
        continuation = next[0];
      } else {
        break;
      }
    }
    return items.take(limit).toList();
  }

  /// Retrieves detailed information about a song given its video ID.
  Future<SongFull> getSong(String videoId) async {
    if (!RegExp(r"^[a-zA-Z0-9-_]{11}$").hasMatch(videoId)) {
      throw Exception("Invalid videoId");
    }

    final data = await constructRequest("player", body: {"videoId": videoId});
    final nextInfo = await _getCurrentTrackInfoFromNext(videoId);
    final song = SongParser.parse(
      data,
      album: nextInfo.album,
      isExplicit: nextInfo.isExplicit,
    );
    if (song.videoId != videoId) {
      throw Exception("Invalid videoId");
    }
    return song;
  }

  /// Calls the `/next` endpoint to extract album info and the "Explicit"
  /// badge for the current song.
  ///
  /// The `/player` endpoint used by [getSong] does not expose the explicit
  /// content badge, so it is resolved here using the same `/next` (watch
  /// queue) call that is already made to resolve the album, avoiding an
  /// extra network request.
  Future<({AlbumBasic? album, bool isExplicit})> _getCurrentTrackInfoFromNext(
    String videoId,
  ) async {
    try {
      final nextData = await constructRequest(
        "next",
        body: {
          "videoId": videoId,
          "playlistId": "RDAMVM$videoId",
          "isAudioOnly": true,
        },
      );

      final playlistPanelRenderer =
          nextData?['contents']?['singleColumnMusicWatchNextResultsRenderer']?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['musicQueueRenderer']?['content']?['playlistPanelRenderer'];

      final contents = playlistPanelRenderer?['contents'] as List<dynamic>?;
      if (contents == null || contents.isEmpty) {
        return (album: null, isExplicit: false);
      }

      final current = contents[0]?['playlistPanelVideoRenderer'];
      final isExplicit = hasExplicitBadge(current);
      final bylineRuns = current?['longBylineText']?['runs'] as List<dynamic>?;
      if (bylineRuns != null) {
        for (final run in bylineRuns) {
          final pageType =
              run?['navigationEndpoint']?['browseEndpoint']?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType']
                  as String?;
          if (pageType == 'MUSIC_PAGE_TYPE_ALBUM') {
            final albumName = run['text'] as String?;
            final albumId =
                run['navigationEndpoint']?['browseEndpoint']?['browseId']
                    as String?;
            if (albumName != null && albumId != null) {
              return (
                album: AlbumBasic(name: albumName, albumId: albumId),
                isExplicit: isExplicit,
              );
            }
          }
        }
      }

      // Fallback: use playlistId if it's an album ID (OLAK5uy_...)
      final playlistId = playlistPanelRenderer?['playlistId'] as String?;
      if (playlistId != null &&
          playlistId.startsWith('OLAK5uy_') &&
          contents.isNotEmpty) {
        final name =
            current?['longBylineText']?['runs']?.firstWhere(
                  (r) =>
                      r?['navigationEndpoint']?['browseEndpoint']?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType'] ==
                      'MUSIC_PAGE_TYPE_ALBUM',
                  orElse: () => null,
                )?['text']
                as String? ??
            current?['title']?['runs']?[0]?['text'] as String?;
        if (name != null) {
          return (
            album: AlbumBasic(name: name, albumId: playlistId),
            isExplicit: isExplicit,
          );
        }
      }

      return (album: null, isExplicit: isExplicit);
    } catch (_) {
      return (album: null, isExplicit: false);
    }
  }

  /// Retrieves a watch playlist (queue) for a video and/or playlist.
  Future<WatchPlaylistResult> getWatchPlaylist({
    String? videoId,
    String? playlistId,
    bool radio = false,
    bool shuffle = false,
  }) async {
    if (videoId == null && playlistId == null) {
      throw Exception('You must provide either a videoId or a playlistId');
    }

    if (videoId != null && !RegExp(r"^[a-zA-Z0-9-_]{11}$").hasMatch(videoId)) {
      throw Exception('Invalid videoId');
    }

    final body = <String, dynamic>{
      'enablePersistentPlaylistPanel': true,
      'isAudioOnly': true,
      'tunerSettingValue': 'AUTOMIX_SETTING_NORMAL',
    };

    if (videoId != null) {
      body['videoId'] = videoId;
    }

    var resolvedPlaylistId = playlistId;
    if (resolvedPlaylistId == null && videoId != null) {
      resolvedPlaylistId = 'RDAMVM$videoId';
    }
    if (resolvedPlaylistId != null) {
      body['playlistId'] = resolvedPlaylistId;
    }

    if (!radio && !shuffle) {
      body['watchEndpointMusicSupportedConfigs'] = {
        'watchEndpointMusicConfig': {
          'hasPersistentPlaylistPanel': true,
          'musicVideoType': 'MUSIC_VIDEO_TYPE_ATV',
        },
      };
    }
    if (shuffle && resolvedPlaylistId != null) {
      body['params'] = 'wAEB8gECKAE%3D';
    }
    if (radio) {
      body['params'] = 'wAEB';
    }

    final data = await constructRequest('next', body: body);
    final panel = WatchParser.playlistPanelContents(data);
    final contents = panel?['contents'] as List<dynamic>?;
    if (contents == null || contents.isEmpty) {
      throw Exception('Invalid response structure');
    }

    final tabBrowseIds = WatchParser.tabBrowseIds(data);
    return WatchPlaylistResult(
      tracks: WatchParser.parseWatchPlaylist(contents),
      playlistId:
          panel?['playlistId'] as String? ??
          WatchParser.playlistIdFromContents(contents),
      lyricsBrowseId: tabBrowseIds['MUSIC_PAGE_TYPE_TRACK_LYRICS'],
      relatedBrowseId: tabBrowseIds['MUSIC_PAGE_TYPE_TRACK_RELATED'],
    );
  }

  /// Retrieves a list of up next songs for a given video ID.
  Future<List<UpNextsDetails>> getUpNexts(String videoId) async {
    final result = await getWatchPlaylist(videoId: videoId);
    return result.tracks.skip(1).map(_watchTrackToUpNext).toList();
  }

  UpNextsDetails _watchTrackToUpNext(WatchTrack track) {
    return UpNextsDetails(
      type: 'SONG',
      videoId: track.videoId,
      title: track.title,
      artists: track.artist,
      album: track.album,
      duration: track.duration,
      thumbnails: track.thumbnails,
      isExplicit: track.isExplicit,
    );
  }

  /// Gets related content for a song from the Related tab browse id.
  Future<List<RelatedSection>> getSongRelated(String browseId) async {
    if (browseId.isEmpty) {
      throw Exception('Invalid browseId');
    }
    final data = await constructRequest('browse', body: {'browseId': browseId});
    return RelatedParser.parseSections(data);
  }

  /// Retrieves detailed information about a video given its video ID.
  Future<VideoFull> getVideo(String videoId) async {
    if (!RegExp(r"^[a-zA-Z0-9-_]{11}$").hasMatch(videoId)) {
      throw Exception("Invalid videoId");
    }

    final data = await constructRequest("player", body: {"videoId": videoId});
    final video = VideoParser.parse(data);
    if (video.videoId != videoId) {
      throw Exception("Invalid videoId");
    }
    return video;
  }

  /// Retrieves the lyrics of a song given its video ID.
  Future<String?> getLyrics(String videoId) async {
    if (!RegExp(r"^[a-zA-Z0-9-_]{11}$").hasMatch(videoId)) {
      throw Exception("Invalid videoId");
    }

    final data = await constructRequest("next", body: {"videoId": videoId});
    final browseId = traverse(traverseList(data, ["tabs", "tabRenderer"])[1], [
      "browseId",
    ]);

    final lyricsData = await constructRequest(
      "browse",
      body: {"browseId": browseId},
    );
    final lyrics = traverseString(lyricsData, [
      "description",
      "runs",
      "text",
    ])?.trim();

    return lyrics
        ?.replaceAll("\r", "")
        .split("\n")
        .where((element) => element.isNotEmpty)
        .join("\n");
  }

  Future<TimedLyricsRes?> getTimedLyrics(String videoId) async {
    if (!RegExp(r"^[a-zA-Z0-9-_]{11}$").hasMatch(videoId)) {
      throw Exception("Invalid videoId");
    }

    final data = await constructRequest("next", body: {"videoId": videoId});
    final browseId = traverse(traverseList(data, ["tabs", "tabRenderer"])[1], [
      "browseId",
    ]);

    final lyricsData = await constructRequest(
      "browse",
      body: {"browseId": browseId},
      options: ClientRequestOptions(
        clientName: androidClientName,
        clientVersion: androidClientVersion,
      ),
    );
    final timedLyrics = traverse(lyricsData, [
      'contents',
      'type',
      'lyricsData',
    ]);

    if (timedLyrics == null) {
      return null;
    }

    if (timedLyrics is List) {
      return null;
    }

    return TimedLyricsRes.fromMap(timedLyrics);
  }

  /// Retrieves detailed information about an artist given its artist ID.
  Future<ArtistFull> getArtist(String artistId) async {
    final data = await constructRequest("browse", body: {"browseId": artistId});
    return ArtistParser.parse(data, artistId);
  }

  /// Retrieves a list of songs by a specific artist given the artist's ID.
  Future<List<SongDetailed>> getArtistSongs(String artistId) async {
    final artistData = await constructRequest(
      "browse",
      body: {"browseId": artistId},
    );
    final browseToken = traverse(artistData, [
      "musicShelfRenderer",
      "title",
      "browseId",
    ]);

    if (browseToken is List) {
      return [];
    }

    final songsData = await constructRequest(
      "browse",
      body: {"browseId": browseToken},
    );
    final continueToken = traverse(songsData, ["continuation"]);
    late final Map moreSongsData;

    if (continueToken is String) {
      moreSongsData = await constructRequest(
        "browse",
        query: {"continuation": continueToken},
      );
    } else {
      moreSongsData = {};
    }

    return [
          ...traverseList(songsData, ["musicResponsiveListItemRenderer"]),
          ...traverseList(moreSongsData, ["musicResponsiveListItemRenderer"]),
        ]
        .map(
          (s) => SongParser.parseArtistSong(
            s,
            ArtistBasic(
              artistId: artistId,
              name:
                  traverseString(artistData, ["header", "title", "text"]) ?? '',
            ),
          ),
        )
        .toList();
  }

  /// Retrieves a list of albums by a specific artist given the artist's ID.
  Future<List<AlbumDetailed>> getArtistAlbums(String artistId) async {
    final artistData = await constructRequest(
      "browse",
      body: {"browseId": artistId},
    );
    final carousels = traverseList(artistData, ["musicCarouselShelfRenderer"]);
    final albumsCarousel = ArtistParser.findCarousel(
      carousels,
      ArtistParser.isAlbums,
    );
    final artistAlbumsData = albumsCarousel ?? {};
    final browseBody = traverse(artistAlbumsData, [
      "moreContentButton",
      "browseEndpoint",
    ]);
    if (browseBody is List || artistAlbumsData.isEmpty) {
      return [];
    }
    final albumsData = await constructRequest(
      "browse",
      body: browseBody is List ? {} : browseBody,
    );
    return [
      ...traverseList(albumsData, ["musicTwoRowItemRenderer"])
          .map(
            (item) => AlbumParser.parseArtistAlbum(
              item,
              ArtistBasic(
                artistId: artistId,
                name:
                    traverseString(albumsData, ["header", "runs", "text"]) ??
                    '',
              ),
            ),
          )
          .where((album) => album.artist.artistId == artistId),
    ];
  }

  Future<List<AlbumDetailed>> getArtistSingles(String artistId) async {
    final artistData = await constructRequest(
      "browse",
      body: {"browseId": artistId},
    );

    final carousels = traverseList(artistData, ["musicCarouselShelfRenderer"]);
    final singlesCarousel = ArtistParser.findCarousel(
      carousels,
      ArtistParser.isSingles,
    );
    final artistSinglesData = singlesCarousel ?? {};

    final browseBody = traverse(artistSinglesData, [
      "moreContentButton",
      "browseEndpoint",
    ]);
    if (browseBody is List) {
      return [];
    }

    final singlesData = await constructRequest(
      "browse",
      body: browseBody is List ? {} : browseBody,
    );
    return [
      ...traverseList(singlesData, ["musicTwoRowItemRenderer"])
          .map(
            (item) => AlbumParser.parseArtistAlbum(
              item,
              ArtistBasic(
                artistId: artistId,
                name:
                    traverseString(singlesData, ["header", "runs", "text"]) ??
                    '',
              ),
            ),
          )
          .where((album) => album.artist.artistId == artistId),
    ];
  }

  /// Retrieves a list of videos by a specific artist.
  Future<List<VideoDetailed>> getArtistVideos(String artistId) async {
    final artistData = await constructRequest(
      'browse',
      body: {'browseId': artistId},
    );

    final carousels = traverseList(artistData, ['musicCarouselShelfRenderer']);
    final videosCarousels = ArtistParser.findAllCarousels(
      carousels,
      ArtistParser.isVideos,
    );
    if (videosCarousels.isEmpty) return [];

    final artistBasic = ArtistBasic(
      artistId: artistId,
      name: traverseString(artistData, ['header', 'title', 'text']) ?? '',
    );

    List<VideoDetailed> fromCarousels() {
      final allVideos = <VideoDetailed>[];
      for (final carousel in videosCarousels) {
        for (final item in ArtistParser.parseCarouselContents(carousel)) {
          allVideos.add(VideoParser.parseArtistTopVideo(item, artistBasic));
        }
      }
      return allVideos;
    }

    final browseBody = traverse(videosCarousels.first, [
      'moreContentButton',
      'browseEndpoint',
    ]);
    if (browseBody is! Map<String, dynamic>) {
      return fromCarousels();
    }

    final videosData = await constructRequest('browse', body: browseBody);

    // "Show all" for artist videos is a playlist shelf of list rows.
    final listItems = traverseList(videosData, [
      'musicResponsiveListItemRenderer',
    ]);
    if (listItems.isNotEmpty) {
      return listItems
          .map(VideoParser.parsePlaylistVideo)
          .whereType<VideoDetailed>()
          .toList();
    }

    final gridItems = traverseList(videosData, ['musicTwoRowItemRenderer']);
    if (gridItems.isNotEmpty) {
      return gridItems
          .map((item) => VideoParser.parseArtistTopVideo(item, artistBasic))
          .toList();
    }

    return fromCarousels();
  }

  /// Retrieves detailed information about an album given its album ID.
  Future<AlbumFull> getAlbum(String albumId) async {
    final data = await constructRequest("browse", body: {"browseId": albumId});
    return AlbumParser.parse(data, albumId);
  }

  /// Retrieves detailed information about a playlist given its playlist ID.
  Future<PlaylistFull> getPlaylist(String playlistId) async {
    var id = playlistId;
    if (id.startsWith('VL')) {
      id = id.substring(2);
    }

    // Song-radio chips (RDAMVM…) have no browse playlist header — build
    // metadata from the watch playlist queue instead.
    if (id.startsWith('RDAMVM') && id.length >= 17) {
      final videoId = id.substring(6);
      final watch = await getWatchPlaylist(videoId: videoId, playlistId: id);
      final first = watch.tracks.isNotEmpty ? watch.tracks.first : null;
      return PlaylistFull(
        type: 'PLAYLIST',
        playlistId: 'VL$id',
        name: first?.title ?? id,
        artist: first?.artist ?? ArtistBasic(name: ''),
        videoCount: watch.tracks.length,
        thumbnails: first?.thumbnails ?? const [],
      );
    }

    final browseId = 'VL$id';
    final data = await constructRequest("browse", body: {"browseId": browseId});
    return PlaylistParser.parse(data, browseId);
  }

  /// Retrieves a list of videos from a playlist given its playlist ID.
  Future<List<VideoDetailed>> getPlaylistVideos(String playlistId) async {
    var id = playlistId;
    if (id.startsWith('VL')) {
      id = id.substring(2);
    }

    // Explore mood/genre grids mix curated playlists (RDCLAK5uy_…) with
    // song-radio chips (RDAMVM + videoId). The latter have no playlist shelf
    // on browse — load them via /next instead.
    if (id.startsWith('RDAMVM') && id.length >= 17) {
      final videoId = id.substring(6);
      final watch = await getWatchPlaylist(videoId: videoId, playlistId: id);
      return watch.tracks.map(_watchTrackToVideoDetailed).toList();
    }

    final browseId = 'VL$id';
    final playlistData = await constructRequest(
      "browse",
      body: {"browseId": browseId},
    );
    final songs = traverseList(playlistData, [
      "musicPlaylistShelfRenderer",
      "musicResponsiveListItemRenderer",
    ]);
    dynamic continuation = traverse(playlistData, ["continuation"]);
    if (continuation is List && (continuation).isNotEmpty) {
      continuation = continuation[0];
    }
    while (continuation is String && continuation.isNotEmpty) {
      final songsData = await constructRequest(
        "browse",
        query: {"continuation": continuation},
      );
      songs.addAll(
        traverseList(songsData, ["musicResponsiveListItemRenderer"]),
      );
      final next = traverse(songsData, ["continuation"]);
      if (next is String) {
        continuation = next;
      } else if (next is List && (next).isNotEmpty) {
        continuation = next[0];
      } else {
        break;
      }
    }

    return songs
        .map(VideoParser.parsePlaylistVideo)
        .whereType<VideoDetailed>()
        .toList();
  }

  VideoDetailed _watchTrackToVideoDetailed(WatchTrack track) {
    return VideoDetailed(
      type: 'SONG',
      videoId: track.videoId,
      name: track.title,
      artist: track.artist,
      duration: track.duration,
      thumbnails: track.thumbnails,
      isExplicit: track.isExplicit,
    );
  }

  /// Retrieves the home page sections with optional mood/activity chip filter.
  ///
  /// If [params] is provided (from a [BrowseChip.params]), the home page is
  /// filtered to show content matching that chip (e.g. "Energize", "Relax").
  /// Returns both the available chips and the (optionally filtered) sections.
  Future<BrowseHomeResult> getHome({String? params, String? browseId}) async {
    final data = await constructRequest(
      "browse",
      body: {"browseId": browseId ?? feMusicHome, "params": params},
    );
    final rawChips = traverseList(data, [
      "sectionListRenderer",
      "header",
      "chipCloudRenderer",
      "chips",
    ]);
    final chips = rawChips
        .map((c) => BrowseChip.fromMap(c as Map<String, dynamic>))
        .toList();

    final sections = traverseList(data, ["sectionListRenderer", "contents"]);
    dynamic continuation = traverseString(data, ["continuation"]);
    while (continuation != null) {
      final data = await constructRequest(
        "browse",
        body: {"continuation": continuation},
      );
      sections.addAll(
        traverseList(data, ["sectionListContinuation", "contents"]),
      );
      continuation = traverseString(data, ["continuation"]);
    }

    final bgThumbnails = traverseList(data, [
      "background",
      "musicThumbnailRenderer",
      "thumbnail",
      "thumbnails",
    ]);
    final backgroundUrl = bgThumbnails.isNotEmpty
        ? (bgThumbnails[0] as Map)["url"] as String?
        : null;

    return BrowseHomeResult(
      chips: chips,
      sections: sections.map(Parser.parseHomeSection).toList(),
      backgroundUrl: backgroundUrl,
    );
  }

  /// Fetches "Moods & Genres" categories from YouTube Music Explore.
  Future<MoodCategoriesResult> getMoodCategories() async {
    final data = await constructRequest(
      'browse',
      body: {'browseId': feMusicMoodsAndGenres},
    );
    return ExploreParser.parseMoodCategories(data);
  }

  /// Retrieves playlists for a moods & genres [params] token from [getMoodCategories].
  ///
  /// The [params] value must be copied from a live [getMoodCategories] response;
  /// stale tokens return HTTP 404 from YouTube Music.
  Future<List<PlaylistDetailed>> getMoodPlaylists(String params) async {
    if (params.isEmpty) {
      throw Exception(
        'params is required — obtain it from getMoodCategories()',
      );
    }
    final data = await constructRequest(
      'browse',
      body: {'browseId': feMusicMoodsAndGenresCategory, 'params': params},
    );
    return ExploreParser.parseMoodPlaylists(data);
  }

  /// Gets latest charts: video playlists and top artists for [country] (ISO 3166-1 alpha-2, default `ZZ`).
  Future<ChartsResult> getCharts({String country = 'ZZ'}) async {
    final body = <String, dynamic>{'browseId': feMusicCharts};
    if (country.isNotEmpty) {
      body['formData'] = {
        'selectedValues': [country],
      };
    }
    final data = await constructRequest('browse', body: body);
    return ExploreParser.parseCharts(data, country: country);
  }

  /// Latest albums/singles and music videos from YouTube Music's New Releases page.
  Future<NewReleasesResult> getNewReleases() async {
    final data = await constructRequest(
      'browse',
      body: {'browseId': feMusicNewReleases},
    );
    return ExploreParser.parseNewReleases(data);
  }

  /// Resolves an album audio playlist id (`OLAK5uy_…`) to its browse id (`MPREb_…`).
  Future<String?> getAlbumBrowseId(String audioPlaylistId) async {
    if (!audioPlaylistId.startsWith('OLAK5uy_')) {
      throw Exception('audioPlaylistId must start with OLAK5uy_');
    }

    final uri = Uri.parse(
      'https://music.youtube.com/playlist',
    ).replace(queryParameters: {'list': audioPlaylistId});
    final cookies = await cookieJar.loadForRequest(uri);
    final cookieString = cookies
        .map((cookie) => '${cookie.name}=${cookie.value}')
        .join('; ');
    const socsCookie = 'SOCS=CAI';
    final headers = {
      ..._baseHeaders,
      'cookie': cookieString.isNotEmpty
          ? '$cookieString; $socsCookie'
          : socsCookie,
    };
    final response = await _client.get(uri, headers: headers);
    _saveCookiesFromHeaders(uri, response.headers);
    final match = RegExp(r'MPREb_[a-zA-Z0-9_-]+').firstMatch(response.body);
    return match?.group(0);
  }

  /// Podcast show metadata and episodes.
  ///
  /// [playlistId] may be a bare playlist id (`PL…`) or a browse id (`MPSP…`).
  /// Pass [limit] to cap how many episodes are fetched (follows continuations).
  Future<PodcastFull> getPodcast(String playlistId, {int limit = 100}) async {
    final browseId = playlistId.startsWith('MPSP')
        ? playlistId
        : 'MPSP$playlistId';
    final data = await constructRequest('browse', body: {'browseId': browseId});
    final podcast = PodcastParser.parse(data, browseId);
    final episodes = List<PodcastEpisode>.from(podcast.episodes);
    var continuation = PodcastParser.continuationToken(data);

    while (continuation != null && episodes.length < limit) {
      final more = await constructRequest(
        'browse',
        query: {'continuation': continuation},
      );
      final wrapped = traverseList(more, [
        'musicShelfContinuation',
        'contents',
      ]);
      if (wrapped.isNotEmpty) {
        episodes.addAll(PodcastParser.parseEpisodeItems(wrapped));
      } else {
        episodes.addAll(
          traverseList(more, [
            'musicMultiRowListItemRenderer',
          ]).whereType<Map>().map(PodcastParser.parseEpisodeItem),
        );
      }

      dynamic next = traverse(more, ['continuation']);
      if (next is List && next.isNotEmpty) next = next[0];
      continuation = next is String && next.isNotEmpty ? next : null;
    }

    return PodcastFull(
      browseId: podcast.browseId,
      name: podcast.name,
      author: podcast.author,
      description: podcast.description,
      thumbnails: podcast.thumbnails,
      episodes: episodes.take(limit).toList(),
    );
  }

  /// Single podcast episode page.
  ///
  /// [videoId] may be a bare video id or a browse id (`MPED…`).
  Future<EpisodeFull> getEpisode(String videoId) async {
    final browseId = videoId.startsWith('MPED') ? videoId : 'MPED$videoId';
    final data = await constructRequest('browse', body: {'browseId': browseId});
    return PodcastParser.parseEpisode(data, browseId);
  }

  /// Retrieves a non-artist user channel (videos and playlists).
  Future<UserFull> getUser(String channelId) async {
    final data = await constructRequest(
      'browse',
      body: {'browseId': channelId},
    );
    return UserParser.parse(data, channelId);
  }

  /// Full playlist list for a user. [params] comes from [UserFull.playlistsParams].
  Future<List<PlaylistDetailed>> getUserPlaylists(
    String channelId,
    String params,
  ) async {
    final data = await constructRequest(
      'browse',
      body: {'browseId': channelId, 'params': params},
    );
    final user = UserParser.parse(data, channelId);
    final fromPage = UserParser.parsePlaylistsGrid(data, channelId, user.name);
    return fromPage.isNotEmpty ? fromPage : user.playlists;
  }

  /// Full video list for a user. [params] comes from [UserFull.videosParams].
  Future<List<VideoDetailed>> getUserVideos(
    String channelId,
    String params,
  ) async {
    final data = await constructRequest(
      'browse',
      body: {'browseId': channelId, 'params': params},
    );
    final user = UserParser.parse(data, channelId);
    final fromPage = UserParser.parseVideosGrid(data, channelId, user.name);
    return fromPage.isNotEmpty ? fromPage : user.videos;
  }

  @Deprecated('Use getHome() instead, which also provides available chips.')
  Future<List<HomeSection>> getHomeSections() async {
    final result = await getHome();
    return result.sections;
  }
}
