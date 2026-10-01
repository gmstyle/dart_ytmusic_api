/// Selects the next-page Innertube continuation token from mixed
/// `continuation` values returned by [traverse].
///
/// Artist discography grids expose both short tracking strings (~70–90 chars)
/// and, when another page exists, a much longer token. Maps such as
/// `reloadContinuationData` are ignored. Returns the longest non-empty string,
/// or `null` when none are present.
String? longestContinuationToken(dynamic continuation) {
  final tokens = <String>[];

  void collect(dynamic value) {
    if (value is String) {
      if (value.isNotEmpty) tokens.add(value);
      return;
    }
    if (value is List) {
      for (final item in value) {
        collect(item);
      }
    }
    // Maps and other types are ignored (tracking / reload payloads).
  }

  collect(continuation);
  if (tokens.isEmpty) return null;

  var best = tokens.first;
  for (var i = 1; i < tokens.length; i++) {
    if (tokens[i].length > best.length) best = tokens[i];
  }
  return best;
}

/// Whether [token] should trigger another browse continuation request.
///
/// Returns `false` when the token is missing/empty or unchanged from the
/// previous page (repeated token stops the loop).
bool shouldFollowContinuationToken(String? token, String? previousToken) {
  return token != null && token.isNotEmpty && token != previousToken;
}
