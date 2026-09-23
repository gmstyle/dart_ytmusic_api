# Dart YouTube Music API

This package allows you to interact with YouTube Music data in Dart. You can search for songs, albums, artists, and playlists, retrieve detailed information, and get suggestions.

> **Note:** This package is ported from [ts-npm-ytmusic-api](https://github.com/zS1L3NT/ts-npm-ytmusic-api). Credits to the original author.

## Getting Started

### Installation

You can install the package in your Dart project using the following methods:

#### 1. Using `flutter pub` (for Flutter projects)

```bash
flutter pub add dart_ytmusic_api
```

#### 2. Using `dart pub` (for general Dart projects)

```bash
dart pub add dart_ytmusic_api
```

#### 3. Modifying `pubspec.yaml`

Add the following line to your `pubspec.yaml` file under the `dependencies` section:

```yaml
dependencies:
  dart_ytmusic_api: ^1.3.5
```

Then, run `flutter pub get` (for Flutter projects) or `dart pub get` (for general Dart projects) to install the package.

### Usage
Here's a basic example of how to use the YouTube Music API in Dart:

```dart
import 'package:dart_ytmusic_api/yt_music.dart';

void main() async {
  // Create an instance of the YouTube Music API
  final ytmusic = YTMusic();

  // Initialize the API
  await ytmusic.initialize();

  // There's how you can use a method
  final albumResults = await ytmusic.searchAlbums('query');
}
```

## API Methods

The following methods are available in the `YTMusic` class:

**Initialization**

- `initialize(cookies: String, gl: String, hl: String)`: Initializes the API with the provided cookies, geolocation, and language.

**Search**

- `getSearchSuggestions(query: String)`: Retrieves search suggestions for a given query.
- `search(query: String, {limit})`: Performs a general search for music with the given query.
- `searchSongs(query: String, {limit})`: Performs a search specifically for songs.
- `searchVideos(query: String, {limit})`: Performs a search specifically for videos.
- `searchArtists(query: String, {limit})`: Performs a search specifically for artists.
- `searchAlbums(query: String, {limit})`: Performs a search specifically for albums.
- `searchPlaylists(query: String, {limit})`: Performs a search specifically for playlists.
- `searchPodcasts(query: String, {limit})`: Performs a search specifically for podcasts.
- `searchEpisodes(query: String, {limit})`: Performs a search specifically for podcast episodes.
- `searchProfiles(query: String, {limit})`: Performs a search specifically for user profiles.

**Retrieve Details**

- `getSong(videoId: String)`: Retrieves detailed information about a song given its video ID.
- `getVideo(videoId: String)`: Retrieves detailed information about a video given its video ID.
- `getLyrics(videoId: String)`: Retrieves the lyrics of a song given its video ID.
- `getTimedLyrics(String videoId)`: Retrieves the timed lyrics (lyrics synchronized with audio playback times) for a song given its video ID.
- `getUpNexts(String videoId)`: Retrieves a list of suggested up next songs for a given video ID.
- `getWatchPlaylist({videoId, playlistId, radio, shuffle})`: Retrieves the watch queue playlist.
- `getSongRelated(String browseId)`: Retrieves related content for a track.
- `getArtist(artistId: String)`: Retrieves detailed information about an artist given its artist ID.
- `getAlbum(albumId: String)`: Retrieves detailed information about an album given its album ID. Greyed-out tracks are resolved via watch-page canonical redirects when available.
- `resolvePlayableVideoId(videoId: String)`: Returns the YouTube Music canonical replacement id when [videoId] redirects, otherwise `null`.
- `getPlaylist(playlistId: String, {limit})`: Playlist metadata plus tracks (default limit 100).
- `getPlaylistVideos(playlistId: String)`: Full track list for a playlist.
- `getAlbumBrowseId(audioPlaylistId: String)`: Resolves an album audio playlist id (`OLAK5uy_…`) to its browse id (`MPREb_…`).
- `getPodcast(playlistId: String, {limit})`: Podcast show metadata and episodes (`MPSP…` / `PL…`).
- `getEpisode(videoId: String)`: Single episode page (`MPED…` / video id).
- `getUser(channelId: String)`: Retrieves a non-artist user channel (videos and playlists).
- `getUserPlaylists(channelId: String, params: String)`: Full playlist list for a user (`params` from `UserFull.playlistsParams`).
- `getUserVideos(channelId: String, params: String)`: Full video list for a user (`params` from `UserFull.videosParams`).

**Artist Methods**

- `getArtistSongs(artistId: String)`: Retrieves a list of songs by a specific artist.
- `getArtistAlbums(artistId: String)`: Retrieves a list of albums by a specific artist.
- `getArtistSingles(artistId: String)`: Retrieves a list of singles by a specific artist.
- `getArtistVideos(artistId: String)`: Retrieves a list of videos by a specific artist.

**Playlist Methods**

- `getPlaylistVideos(playlistId: String)`: Full track list (all pages) for a playlist.

**Home Section**

- `getHome({params?, browseId?})`: Retrieves the home page with mood chips and sections.
- `getHomeSections()`: Deprecated — use `getHome()`.

**Explore**

- `getMoodCategories()`: Moods & Genres category tree.
- `getMoodPlaylists(params)`: Playlists for a mood category.
- `getCharts({country})`: Chart video playlists and top artists.
- `getNewReleases()`: Latest albums/singles and music videos.

**Watch**

- `getWatchPlaylist({videoId?, playlistId?, radio?, shuffle?})`: Full watch queue with lyrics/related browse ids.
- `getSongRelated(browseId)`: Related tab content for a track.

## Data Fields

- **`artists`**: `List<ArtistBasic>` of credited artists on `SongDetailed`, `SongFull`, `VideoDetailed`, `VideoFull`, `AlbumDetailed`, `AlbumFull`, `PlaylistDetailed`, `PlaylistFull`, `WatchTrack` and `UpNextsDetails`. YouTube Music collaborations (e.g. ANTIDROGA → Emma & Fabri Fibra) are separate Innertube runs, each with a name and `artistId`. Use `ArtistBasic.formatNames(artists)` for the `A & B` / `A, B & C` display string. The former singular **`artist`** getter is deprecated and returns `artists.first`. `getSong` / `getVideo` resolve credits from `/next` (the `/player` endpoint only has a single channel author). Album tracks without per-row credits inherit the album header artists; greyed-out album rows still expose the plain-text artist name from the second column when no browse endpoint is present.
- **`isExplicit`**: Available on `SongDetailed`, `SongFull`, `VideoDetailed`, `VideoFull`, `AlbumDetailed`, `AlbumFull`, `PlaylistDetailed`, `PlaylistFull` and `UpNextsDetails`. Reflects YouTube Music's "Explicit" content badge. Not every context exposes this badge (e.g. some playlists don't), in which case it defaults to `false`. `getSong` / `getVideo` resolve it via `/next`.
- **`isPlayable`**: Available on `SongDetailed` and `VideoDetailed`. `false` when the list row has `MUSIC_ITEM_RENDERER_DISPLAY_POLICY_GREY_OUT` (unavailable in catalog but still listed). Defaults to `true`. Album, playlist, artist song/video, search and home list parsers set it from browse data without calling `/player`. Greyed-out album/playlist rows still return title, artist text and `videoId` when present. `getAlbum` then tries YouTube Music watch-page canonical redirects for greyed-out songs and, on success, replaces `videoId`, sets `isPlayable` to `true`, and stores the catalog id in `originalVideoId`.
- **`originalVideoId`**: On `SongDetailed`, set by `getAlbum` when `videoId` was replaced by a playable redirect. Otherwise `null`.
- **`description`**: Available on `ArtistFull`, `AlbumFull` and `PlaylistFull`, containing the description text shown on the item's YouTube Music page, if any.
- **`radioId` / `shuffleId`**: On `ArtistFull`, watch-playlist ids for Start radio (`RDEM…`) and Shuffle (`RDAO…`).
- **`tracks`**: On `PlaylistFull`, loaded with `getPlaylist({limit})` (default 100).

## Contributing

Contributions are welcome! Please feel free to open issues, submit pull requests, or reach out if you have any questions.

## License

This project is licensed under the GNU General Public License version 3. See the [LICENSE](LICENSE) file for details.
