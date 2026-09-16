# YTMusic API Example App

Manual tester for every public method in `dart_ytmusic_api`. Use it to verify API responses against real YouTube Music data.

Default search/song/album/artist inputs are set to **ANTIDROGA** (Emma & Fabri Fibra) so multiple credited artists are visible immediately (`artists` / `ArtistBasic.formatNames`).

## Run

From this directory:

```bash
flutter pub get
flutter run
```

Or with Dart only (if you have a Flutter device connected):

```bash
cd example && flutter run -d linux
```

## Screens

| Menu item | API method |
|-----------|------------|
| Search * | `searchSongs`, `searchVideos`, `searchPodcasts`, `searchEpisodes`, `searchProfiles`, … (default query `ANTIDROGA`) |
| Get Song / Watch / Up Nexts | `getSong`, `getWatchPlaylist`, `getUpNexts` (default `noOdrqwqft0`) |
| Get Album | `getAlbum` (default `MPREb_L3vxjEHJMsL`) |
| Get Artist * | `getArtist`, `getArtistSongs`, `getArtistVideos`, … (default Emma `UCzH13CnhFKwTJ1i0A2394ew`) |
| Get Watch Playlist | `getWatchPlaylist` |
| Get Song Related | `getSongRelated` (via watch playlist related tab) |
| Get Artist Videos | `getArtistVideos` |
| Get Album Browse ID | `getAlbumBrowseId` (accepts `MPREb_…` or `OLAK5uy_…`) |
| Get Podcast | `getPodcast` (`MPSP…` / `PL…`) |
| Get Episode | `getEpisode` (`MPED…` / video id) |
| Get User / Videos / Playlists | `getUser`, `getUserVideos`, `getUserPlaylists` |
| Mood Categories | `getMoodCategories` |
| Mood Playlists | Pick a category (params loaded live from `getMoodCategories`) |
| Charts | `getCharts` (country code, e.g. `US`, `ZZ`) |
| New Releases | `getNewReleases` |
| Home (with chips) | `getHome` with chip filter and shelf navigation |

## Offline initialization

For development without network, pass a saved YouTube Music homepage HTML snapshot to `YTMusic().initialize(ytMusicHomeRawHtml: html)` (see the root `page.html` fixture mentioned in `AGENTS.md`).

## Debug raw JSON

From the package root, dump Innertube responses for parser work:

```bash
dart run tool/dump_raw.dart search "query"
dart run tool/dump_raw.dart charts US
dart run tool/dump_raw.dart moods
```

Output goes to `tool/output/` (gitignored).
