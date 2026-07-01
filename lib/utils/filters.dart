import 'package:dart_ytmusic_api/utils/traverse.dart';

bool isTitle(dynamic data) {
  return traverseString(data, [
        "musicVideoType",
      ])?.startsWith("MUSIC_VIDEO_TYPE_") ??
      false;
}

/// Verifica se um objeto representa um artista.
bool isArtist(dynamic data) {
  final pageType = traverseString(data, ["pageType"]);
  return [
    "MUSIC_PAGE_TYPE_USER_CHANNEL",
    "MUSIC_PAGE_TYPE_ARTIST",
  ].contains(pageType);
}

/// Verifica se um objeto representa um álbum.
bool isAlbum(dynamic data) {
  return traverseString(data, ["pageType"]) == "MUSIC_PAGE_TYPE_ALBUM";
}

/// Verifica se um objeto representa uma duração.
bool isDuration(dynamic data) {
  final text = traverseString(data, ["text"]);
  return RegExp(r"(\d{1,2}:)?\d{1,2}:\d{1,2}").hasMatch(text ?? '');
}

/// Verifica se um item carrega o selo de conteúdo "Explicit" do YouTube Music.
///
/// O badge de conteúdo explícito aparece sob chaves diferentes dependendo do
/// contexto da resposta:
/// - `badges` nos itens de lista (resultados de busca, faixas de álbum,
///   faixas de playlist, top songs de artista);
/// - `subtitleBadges` (plural) nos carrosséis de duas linhas (home,
///   álbuns/singles de artista, related releases);
/// - `subtitleBadge` (singular) no cabeçalho de página (álbum, playlist).
bool hasExplicitBadge(dynamic data) {
  const badgeKeys = ["badges", "subtitleBadges", "subtitleBadge"];

  for (final key in badgeKeys) {
    final iconTypes = traverseList(data, [
      key,
      "musicInlineBadgeRenderer",
      "icon",
      "iconType",
    ]);
    if (iconTypes.contains("MUSIC_EXPLICIT_BADGE")) {
      return true;
    }
  }

  return false;
}
