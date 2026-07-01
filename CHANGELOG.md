## 1.5.0

**New Features**
- Added `isExplicit` field to `SongDetailed`, `SongFull`, `VideoDetailed`, `AlbumDetailed`, `AlbumFull`, `PlaylistDetailed`, `PlaylistFull` and `UpNextsDetails`, reflecting YouTube Music's "Explicit" content badge. Populated for free from data already present in `search`, `browse` (artist/album/playlist/home) and `next` responses; also added to `VideoFull` for API consistency, though it currently always evaluates to `false` since `getVideo` only calls the `/player` endpoint, which does not expose this badge.
- Added `description` field to `AlbumFull` and `PlaylistFull`, extracted from the same `musicDescriptionShelfRenderer` structure already used for `ArtistFull.description`.
- Added `tool/dump_raw.dart`, a small CLI utility to dump raw Innertube JSON responses (search/player/next/browse/home) for inspection, formalizing the previously disabled `_writeRawResponse` debug helper.

## 1.4.0

**New Features**
- Added `getHome` method with support for filter chips.
- Added `getHome` method with support for shelfId, browseId, and browseParams.

**Fixes**
- Fixed song parser to properly extract videoId.
- Fixed parsing of artist top songs.
- Fixed album pagination and song retrieval.

**Enhancements**
- Added `AlbumBasic` field to `SongFull` type.
- Added additional data to `SongDetailed`, `VideoDetailed`, and `ArtistDetailed` types.

## 1.3.6
**Fix**
- Critical API crash on non-English systems: Resolved a FormatException that prevented the application from working on operating systems with non-English locales (e.g., Portuguese, Spanish). The issue was caused by an invalid timezone format in API request headers.

**Refactor**
- Dependency Migration: Replaced the dio package with the standard http package for all network requests.

## 1.3.5

**Fix**
- Removed package versions from pubspec

## 1.3.4

**Chore**
- Removed unused `intl` dependency.

## 1.3.3

**Fix**
- Fixed `parseDuration` to handle duration strings with extra text/metadata using regex extraction.

## 1.3.2

**Fix**
- Fixed `getUpNexts` to properly parse artist ID from `longBylineText` instead of `shortBylineText`.
- Added album support to `getUpNexts` with optional `AlbumBasic` field.

## 1.3.1

**Fix**
- Fixed `getUpNexts` return type to properly match original implementation with correct data structure (artists as ArtistBasic object, duration as int in seconds, thumbnails as array).

## 1.3.0

**New Feature**
- Added `getUpNexts(String videoId)`: Retrieve suggested up next songs for a given video.

## 1.2.1

**Fix**
- Removed exit(1)

## 1.2.0

**New Feature**
- Added ytMusicHomeRawHtml property to add credentials externally

## 1.1.1

**Fixes**
- Fix exeption when timed lyrics is not found

## 1.1.0

**New Feature**
- getTimedLyrics(String videoId): New method to retrieve timed lyrics for a song. This allows developers to access lyrics synchronized with audio playback times.

## 1.0.8
**Fixes**
- Fix search method: fixed search method returns empty results.

## 1.0.7

- **Fixes**
- Some songs were not found.

## 1.0.6

**Fixes**
- Fixed song duration handler

## 1.0.5

**Fixes**
- Fixed albumParser: Fixed bad element when ids array is empty.
- Fixed artistPaser: Fixed filters to prevent return items where albumId is empty.
- Fixed songParser: Fixed duration parser.

## 1.0.4

- Fixed no songs in some albums

## 1.0.3

- Fixed album songs

## 1.0.2

- Return artist songs instead of album songs in getAlbum to increase lyrics search.

## 1.0.0

- Initial version.
