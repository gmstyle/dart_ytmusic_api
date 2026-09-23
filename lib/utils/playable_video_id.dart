/// Extracts a redirected playable video id from a YouTube Music watch HTML page.
///
/// YouTube Music serves a `rel="canonical"` link that may point at a different
/// 11-character video id when the requested id is unavailable (geo / distributor
/// replacement). Returns that id when it differs from [requestedVideoId],
/// otherwise `null`.
String? playableVideoIdFromWatchHtml(String html, String requestedVideoId) {
  if (requestedVideoId.isEmpty) return null;

  // href may appear before or after rel="canonical".
  final patterns = <RegExp>[
    RegExp(
      r'''rel=["']canonical["'][^>]*href=["']https://music\.youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})''',
      caseSensitive: false,
    ),
    RegExp(
      r'''href=["']https://music\.youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})["'][^>]*rel=["']canonical["']''',
      caseSensitive: false,
    ),
  ];

  for (final re in patterns) {
    final match = re.firstMatch(html);
    final id = match?.group(1);
    if (id != null && id != requestedVideoId) return id;
  }
  return null;
}
