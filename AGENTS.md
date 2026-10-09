# dart_ytmusic_api

Unofficial YouTube Music Innertube client. **Pure Dart package** — `example/` is a separate Flutter app; do not add a Flutter dependency to this package. SDK and dependency versions live in `pubspec.yaml`. No codegen (`freezed`, `json_serializable`, `build_runner`).

`lib/` is the source of truth. `.github/copilot-instructions.md` is a longer overview and can lag.

## Verify

| Command | When |
|---|---|
| `dart pub get` | After dependency changes |
| `dart analyze` | After every `lib/` change (`package:lints/recommended.yaml`) |
| `dart fix --apply` | Mechanical lint fixes only |
| `dart test` | Parser and util logic. Coverage is fixture-based, not live API |
| `dart pub publish --dry-run` | Before a publish |

CI publishes on tags `v[0-9]+.[0-9]+.[0-9]+*` (`.github/workflows/publish.yml`).

Capture a live payload with `dart run tool/dump_raw.dart <endpoint> [arg]` (writes `tool/output/`). Use that JSON as a test fixture; do not commit secrets.

## Where a change goes

1. **HTTP** only through `YTMusic.constructRequest` in `lib/yt_music.dart`. It always POSTs `https://music.youtube.com/youtubei/{version}/{endpoint}`. Call `await initialize()` first (`hasInitialized` skips a second init). Pass `ytMusicHomeRawHtml` (see `page.html`) to skip the homepage fetch.
2. **Parse** in a static class under `lib/parsers/`. Walk JSON with `traverse` / `traverseList` / `traverseString` (`lib/utils/traverse.dart`). The last key is a dead end: it is returned, not recursed into. `traverseList` always returns a `List`.
3. **Types** go in `lib/types.dart` with a `fromMap` constructor. Search rows implement `SearchResult`. Credited people are `List<ArtistBasic>` via the `HasArtists` mixin — fill the list with `parseArtistRuns` (`lib/utils/artists.dart`). The singular `artist` getter is deprecated and returns the first credit.
4. **Export** any new library from `lib/dart_ytmusic_api.dart`. In-package imports use `package:dart_ytmusic_api/...`.
5. **Search labels** are registered in `SearchParser.parse`. Unknown labels and unresolvable ids return `null`; callers drop nulls. Do not throw for a missing field — use `?` / `??` / empty defaults. The exception is an invalid video id (`^[a-zA-Z0-9_-]{11}$`), which throws before the network call.
6. **User-visible behavior** gets a `CHANGELOG.md` entry.

New comments in English.

## Invariants

- **Config** is scraped from `ytcfg.set({...})` in the homepage HTML, with hardcoded fallbacks. `SOCS=CAI` is set in `initialize()` to skip the Google consent gate. Large bodies are decoded with `Isolate.run`.
- **`getTimedLyrics`** overrides the client with `androidClientName` / `androidClientVersion` (`lib/enums.dart`). A malformed body returns `null`.
- **Browse id prefixes are idempotent.** Strip then re-add: playlists `VL`, podcasts `MPSP`, episodes `MPED`. `RDAMVM…` song radios have no browse shelf — load them with `getWatchPlaylist`, not `browse`.
- **`getPlaylist` / `getPodcast`** default `limit` is 100 and follow continuations. `getPlaylistVideos` is the uncapped track list.
- **Continuations are not one shape.** Search and playlist shelves: `continuation` may be a `String` or a `List` (take the first string). Artist album/single grids: `longestContinuationToken` (longest string; ignore maps) and `shouldFollowContinuationToken` (stop on empty or repeated token), capped at 10 pages, deduped by `albumId`.
- **Greyed-out rows** (`MUSIC_ITEM_RENDERER_DISPLAY_POLICY_GREY_OUT` → `isPlayable: false`) still have a title, but often lack `musicVideoType` and artist browse endpoints. Playlist rows keep `playlistItemData.videoId`. Unavailable album tracks are resolved with `resolvePlayableVideoId` (watch-page `rel=canonical`); the playable id replaces `videoId`, the catalog id goes to `originalVideoId`.
- **Explicit badge** is `hasExplicitBadge` (`badges`, `subtitleBadges`, or `subtitleBadge`). `getSong` / `getVideo` read the badge and full credits from `/next`, because `/player` does not expose them.
- **`ArtistFull.radioId`** (`RDEM…`) and **`shuffleId`** (`RDAO…`) come from the header Start radio / Shuffle buttons.
- **`getMoodPlaylists`** 404s on stale `params`; load them from `getMoodCategories`. `getCharts` country defaults to `ZZ`.
- **`Parser.parseDuration`** extracts `H:MM:SS` or `MM:SS` from strings that also contain other metadata. It returns seconds, or `null`.

## Files

| File | Touch when |
|---|---|
| `lib/yt_music.dart` | Public methods, request body, pagination |
| `lib/types.dart` | Models |
| `lib/enums.dart` | `PageType`, browse ids (`FEmusic_*`), search `params`, Android client |
| `lib/dart_ytmusic_api.dart` | Public exports |
| `lib/parsers/search_parser.dart` | Search type routing (`Song`, `Video`, `Artist`, `EP`, `Single`, `Album`, `Playlist`, `Podcast(s)`, `Episode(s)`, `Profile`, plus podcast/profile `pageType` fallbacks) |
| `lib/parsers/parser.dart` | Duration, counts, home-section item routing |
| `lib/utils/filters.dart` | `isTitle` / `isArtist` / `isAlbum` / `isDuration` / grey-out / explicit |
| `lib/utils/artists.dart` | Collaboration credits from `runs` |
| `lib/utils/continuation_token.dart` | Next-page token selection |
| `lib/utils/playable_video_id.dart` | Canonical redirect id |
| `page.html` | Offline `initialize` fixture |
