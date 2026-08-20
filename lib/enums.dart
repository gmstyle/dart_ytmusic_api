enum PageType {
  musicPageTypeAlbum,
  musicPageTypePlaylist,
  musicVideoTypeOmv;

  static String string(PageType pageType) {
    switch (pageType) {
      case PageType.musicPageTypeAlbum:
        return 'MUSIC_PAGE_TYPE_ALBUM';
      case PageType.musicPageTypePlaylist:
        return 'MUSIC_PAGE_TYPE_PLAYLIST';
      case PageType.musicVideoTypeOmv:
        return 'MUSIC_VIDEO_TYPE_OMV';
    }
  }
}

const String feMusicHome = "FEmusic_home";
const String feMusicCharts = "FEmusic_charts";
const String feMusicMoodsAndGenres = "FEmusic_moods_and_genres";
const String feMusicMoodsAndGenresCategory =
    "FEmusic_moods_and_genres_category";
const String feMusicNewReleases = "FEmusic_new_releases";

const String androidClientName = 'ANDROID_MUSIC';
const String androidClientVersion = '8.05.50';

/// Innertube `search` params (protobuf) for typed catalogue searches.
const String searchParamsSongs = 'Eg-KAQwIARAAGAAgACgAMABqChAEEAMQCRAFEAo%3D';
const String searchParamsVideos = 'Eg-KAQwIABABGAAgACgAMABqChAEEAMQCRAFEAo%3D';
const String searchParamsArtists = 'Eg-KAQwIABAAGAAgASgAMABqChAEEAMQCRAFEAo%3D';
const String searchParamsAlbums = 'Eg-KAQwIABAAGAEgACgAMABqChAEEAMQCRAFEAo%3D';
const String searchParamsPlaylists =
    'Eg-KAQwIABAAGAAgACgBMABqChAEEAMQCRAFEAo%3D';
const String searchParamsPodcasts = 'EgWKAQJQAWoMEA4QChADEAQQCRAF';
const String searchParamsEpisodes = 'EgWKAQJIAWoMEA4QChADEAQQCRAF';
const String searchParamsProfiles = 'EgWKAQJYAWoMEA4QChADEAQQCRAF';
