import 'dart:convert';

import 'package:crypto/crypto.dart';

const _papisid1p = '__Secure-1PAPISID';
const _papisid3p = '__Secure-3PAPISID';

/// Origin (scheme + host) the SAPISIDHASH is bound to.
String originOf(String url) {
  final match = RegExp(r'^(https?://[^/]+)').firstMatch(url);
  return match?.group(1) ?? url;
}

String? _nonEmpty(String? value) {
  if (value == null || value.isEmpty) return null;
  return value;
}

void _pushHash(
  List<String> out,
  String label,
  int ts,
  String? value,
  String origin,
  String? userSessionId,
) {
  if (value == null || value.isEmpty) return;
  final authed = userSessionId != null && userSessionId.isNotEmpty;
  final input = '${authed ? '$userSessionId ' : ''}$ts $value $origin';
  final digest = sha1.convert(utf8.encode(input)).toString();
  out.add('$label ${ts}_$digest${authed ? '_u' : ''}');
}

/// `Authorization` header for authenticated youtubei calls, or `null` when
/// there is no SAPISID (guest). Multi-hash form matching the web client.
String? authorizationHeader(
  Map<String, String> cookies,
  String origin, {
  String? userSessionId,
}) {
  final sapisid =
      _nonEmpty(cookies['SAPISID']) ??
      _nonEmpty(cookies[_papisid3p]) ??
      _nonEmpty(cookies[_papisid1p]);
  if (sapisid == null) return null;
  final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final parts = <String>[];
  _pushHash(parts, 'SAPISIDHASH', ts, sapisid, origin, userSessionId);
  _pushHash(
    parts,
    'SAPISID1PHASH',
    ts,
    cookies[_papisid1p],
    origin,
    userSessionId,
  );
  _pushHash(
    parts,
    'SAPISID3PHASH',
    ts,
    cookies[_papisid3p],
    origin,
    userSessionId,
  );
  return parts.join(' ');
}
