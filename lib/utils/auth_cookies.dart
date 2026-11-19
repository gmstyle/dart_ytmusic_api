import 'package:cookie_jar/cookie_jar.dart';
import 'package:http/http.dart' as http;

/// Cookie names that mark a completed YouTube sign-in.
const kYtAuthCookieNames = <String>{
  'LOGIN_INFO',
  'SAPISID',
  'APISID',
  'HSID',
  'SSID',
  'SIDCC',
  '__Secure-1PAPISID',
  '__Secure-3PAPISID',
};

/// Session cookies YouTube rotates on the Music homepage; keep www/music aligned.
const kYtSessionMirrorCookieNames = <String>{
  ...kYtAuthCookieNames,
  'SID',
  '__Secure-1PSID',
  '__Secure-3PSID',
  '__Secure-1PSIDCC',
  '__Secure-3PSIDCC',
  '__Secure-1PSIDTS',
  '__Secure-3PSIDTS',
};

/// Kept on logout — anonymous identity YouTube needs for a logged-out feed.
const kYtKeepOnLogoutCookieNames = <String>{
  'PREF',
  'VISITOR_INFO1_LIVE',
  'YSC',
  'SOCS',
  'CONSENT',
};

final Uri kYoutubeOrigin = Uri.parse('https://www.youtube.com/');
final Uri kMusicOrigin = Uri.parse('https://music.youtube.com/');
final Uri kYoutubeMobileOrigin = Uri.parse('https://m.youtube.com/');

/// True when [map] holds at least one non-empty auth cookie.
bool jarHasAuth(Map<String, String> map) {
  for (final name in kYtAuthCookieNames) {
    final value = map[name];
    if (value != null && value.isNotEmpty) return true;
  }
  return false;
}

/// True when [map] has a non-empty `LOGIN_INFO`.
///
/// Catalog personalization can work with SAPISID alone, but
/// `account/account_menu` and `LOGGED_IN` / `USER_SESSION_ID` need this
/// cookie. Login UIs should wait for it before the first authenticated
/// HTTP call — hitting Music with a half-set jar can revoke the session.
bool jarHasLoginInfo(Map<String, String> map) {
  final value = map['LOGIN_INFO'];
  return value != null && value.isNotEmpty;
}

/// Cookie names safe to persist for YouTube Music / stream clients.
///
/// WebView login also surfaces Google Accounts cookies (`LSID`,
/// `ACCOUNT_CHOOSER`, `__Host-GAPS`, …). Rewriting those onto
/// `.youtube.com` pollutes the jar and can trip bot checks on `/player`.
bool isYoutubeSessionCookieName(String name) {
  if (kYtSessionMirrorCookieNames.contains(name)) return true;
  if (kYtKeepOnLogoutCookieNames.contains(name)) return true;
  const extra = <String>{
    'VISITOR_PRIVACY_METADATA',
    '__Secure-YENID',
    '__Secure-YNID',
    '__Secure-ROLLOUT_TOKEN',
    '__Secure-ENID',
  };
  return extra.contains(name);
}

/// Drops non-YouTube cookies (e.g. Google Accounts) from a login export.
List<Cookie> filterYoutubeSessionCookies(Iterable<Cookie> cookies) {
  return [
    for (final c in cookies)
      if (isYoutubeSessionCookieName(c.name) && c.value.isNotEmpty) c,
  ];
}

/// Deduplicates [cookies] into a name → value map, skipping empty values.
///
/// Keeps the first occurrence of each name because [CookieJar.loadForRequest]
/// yields more-specific host/path cookies before domain-wide ones.
Map<String, String> cleanCookieMap(Iterable<Cookie> cookies) {
  final map = <String, String>{};
  for (final c in cookies) {
    if (c.value.isEmpty) continue;
    map.putIfAbsent(c.name, () => c.value);
  }
  return map;
}

/// Formats a cookie name → value map into a `Cookie` HTTP header value.
String formatCookieHeader(Map<String, String> cookies) =>
    cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

Future<Map<String, String>> loadCookieMap(CookieJar jar, Uri uri) async {
  return cleanCookieMap(await jar.loadForRequest(uri));
}

/// Signed in when an auth cookie is present for both www and music origins.
Future<bool> isSignedIn(CookieJar jar) async {
  final www = await loadCookieMap(jar, kYoutubeOrigin);
  final music = await loadCookieMap(jar, kMusicOrigin);
  return jarHasAuth(www) && jarHasAuth(music);
}

/// Consent cookie that bypasses Google's Music "unsupported browser" interstitial.
///
/// WebView / Google login often writes a different `SOCS` value (e.g. `CAAa…`).
/// Sending that with auth cookies makes Music return the tiny compatibility
/// HTML stub — no `VISITOR_DATA` / `ytcfg` — and stream clients then fail with
/// "Sign in to confirm you're not a bot". Always force this value.
const kYtSocsConsentValue = 'CAI';

/// Saves [cookies] onto the www and music jars (and mobile when present).
///
/// Normalizes cookies onto `.youtube.com` (`/` path) and always ends by writing
/// [kYtSocsConsentValue] so a login export cannot leave a Music-breaking `SOCS`.
Future<void> applyAuthCookies(CookieJar jar, Iterable<Cookie> cookies) async {
  final list = <Cookie>[
    for (final c in cookies)
      if (c.name != 'SOCS' && c.value.isNotEmpty)
        Cookie(c.name, c.value)
          ..domain = '.youtube.com'
          ..path = '/'
          ..secure = c.secure
          ..httpOnly = c.httpOnly
          ..expires = c.expires
          ..maxAge = c.maxAge,
  ];
  if (list.isNotEmpty) {
    await jar.saveFromResponse(kYoutubeOrigin, list);
    await jar.saveFromResponse(kMusicOrigin, list);
    await jar.saveFromResponse(kYoutubeMobileOrigin, list);
  }
  await ensureMusicConsentCookies(jar);
}

/// Forces `SOCS=CAI` on www / music / mobile origins.
Future<void> ensureMusicConsentCookies(CookieJar jar) async {
  final socs = Cookie('SOCS', kYtSocsConsentValue)..domain = '.youtube.com';
  await jar.saveFromResponse(kYoutubeOrigin, [socs]);
  await jar.saveFromResponse(kMusicOrigin, [socs]);
  await jar.saveFromResponse(kYoutubeMobileOrigin, [socs]);
}

/// Drops auth cookies, keeping anonymous identity cookies.
Future<void> clearAuthCookies(CookieJar jar) async {
  for (final uri in [kYoutubeOrigin, kMusicOrigin, kYoutubeMobileOrigin]) {
    final existing = await jar.loadForRequest(uri);
    final keep = existing
        .where((c) => kYtKeepOnLogoutCookieNames.contains(c.name))
        .toList();
    await jar.delete(uri, true);
    if (keep.isNotEmpty) {
      await jar.saveFromResponse(uri, keep);
    }
  }
}

/// Parses a `name=value; name2=value2` cookie header into [Cookie]s.
List<Cookie> parseCookieHeader(String header) {
  final out = <Cookie>[];
  for (final part in header.split(';')) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    final eq = trimmed.indexOf('=');
    if (eq <= 0) continue;
    final name = trimmed.substring(0, eq).trim();
    final value = trimmed.substring(eq + 1).trim();
    if (name.isEmpty) continue;
    try {
      out.add(Cookie(name, value)..domain = '.youtube.com');
    } catch (_) {}
  }
  return out;
}

/// Parses raw `Set-Cookie` header values into [Cookie]s (skips malformed).
List<Cookie> parseSetCookieHeaders(Iterable<String> values) {
  final out = <Cookie>[];
  for (final raw in values) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    try {
      out.add(Cookie.fromSetCookieValue(trimmed));
    } catch (_) {}
  }
  return out;
}

/// Keeps only usable session cookies from a `Set-Cookie` batch.
///
/// YouTube often sends `Max-Age=0` / empty values that would wipe `SAPISID` /
/// `SID` from the jar while leaving `__Secure-3*`. Catalog may still look
/// signed-in, but stream clients then hit "Sign in to confirm you're not a
/// bot". Never apply those deletions for [kYtSessionMirrorCookieNames].
List<Cookie> usableSetCookies(Iterable<Cookie> cookies) {
  final out = <Cookie>[];
  for (final c in cookies) {
    if (c.value.isEmpty) continue;
    if (c.maxAge != null && c.maxAge! <= 0) continue;
    if (c.expires != null && !c.expires!.isAfter(DateTime.now())) continue;
    out.add(c);
  }
  return out;
}

/// Returns `true` when any raw `Set-Cookie` header explicitly wipes `LOGIN_INFO`.
///
/// Server-side `LOGIN_INFO` expiry / deletion is the authoritative remote logout
/// signal from YouTube.
bool isLoginInfoWipeSetCookies(Iterable<String> rawSetCookies) {
  final now = DateTime.now();
  for (final raw in rawSetCookies) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    try {
      final c = Cookie.fromSetCookieValue(trimmed);
      if (c.name != 'LOGIN_INFO') continue;
      if (c.value.isEmpty) return true;
      if (c.maxAge != null && c.maxAge! <= 0) return true;
      if (c.expires != null && !c.expires!.isAfter(now)) return true;
    } catch (_) {
      final eq = trimmed.indexOf('=');
      if (eq <= 0 || trimmed.substring(0, eq).trim() != 'LOGIN_INFO') {
        continue;
      }
      final rest = trimmed.substring(eq + 1);
      final semi = rest.indexOf(';');
      final value = (semi < 0 ? rest : rest.substring(0, semi)).trim();
      if (value.isEmpty) return true;
      if (RegExp(
            r';\s*max-age\s*=\s*-?\d+',
            caseSensitive: false,
          ).firstMatch(trimmed)
          case final m?) {
        final age = int.tryParse(m.group(0)!.split('=').last.trim());
        if (age != null && age <= 0) return true;
      }
    }
  }
  return false;
}

/// Saves every `Set-Cookie` from [response] into [jar].
///
/// Auth/session cookies with a non-empty value are mirrored onto www, music,
/// and mobile origins so catalog and stream clients share login state.
Future<void> saveSetCookiesFromResponse(
  CookieJar jar,
  Uri uri,
  http.BaseResponse response, {
  void Function()? onSessionCookiesChanged,
  Future<void> Function()? onLoginInfoWiped,
}) async {
  final raw = response.headersSplitValues['set-cookie'] ?? const <String>[];
  await saveSetCookieHeaderValues(
    jar,
    uri,
    raw,
    onSessionCookiesChanged: onSessionCookiesChanged,
    onLoginInfoWiped: onLoginInfoWiped,
  );
}

/// Same as [saveSetCookiesFromResponse] from already-split header strings.
Future<void> saveSetCookieHeaderValues(
  CookieJar jar,
  Uri uri,
  Iterable<String> values, {
  void Function()? onSessionCookiesChanged,
  Future<void> Function()? onLoginInfoWiped,
}) async {
  if (isLoginInfoWipeSetCookies(values)) {
    await clearAuthCookies(jar);
    if (onLoginInfoWiped != null) {
      await onLoginInfoWiped();
    }
    return;
  }

  final usable = [
    for (final c in usableSetCookies(parseSetCookieHeaders(values)))
      if (c.name != 'SOCS') c,
  ];
  if (usable.isEmpty) return;

  final sessionCookies = <Cookie>[];
  final otherCookies = <Cookie>[];
  for (final c in usable) {
    if (kYtSessionMirrorCookieNames.contains(c.name)) {
      sessionCookies.add(c);
    } else {
      otherCookies.add(c);
    }
  }

  if (otherCookies.isNotEmpty) {
    await jar.saveFromResponse(uri, otherCookies);
  }
  if (sessionCookies.isNotEmpty) {
    await applyAuthCookies(jar, sessionCookies);
    onSessionCookiesChanged?.call();
  }
}
