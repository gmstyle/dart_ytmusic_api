// ignore_for_file: public_member_api_docs, sort_constructors_first
class ClientRequestOptions {
  final String? clientName;
  final String? clientVersion;

  ClientRequestOptions({this.clientName, this.clientVersion});
}

class CueRangeMetadata {
  final String id;

  CueRangeMetadata({required this.id});

  factory CueRangeMetadata.fromMap(Map<String, dynamic> json) {
    return CueRangeMetadata(id: json['id'] as String);
  }

  @override
  String toString() => 'CueRangeMetadata(id: $id)';
}

class CueRange {
  final int startTimeMilliseconds;
  final int endTimeMilliseconds;
  final CueRangeMetadata metadata;

  CueRange({
    required this.startTimeMilliseconds,
    required this.endTimeMilliseconds,
    required this.metadata,
  });

  factory CueRange.fromMap(Map<String, dynamic> json) {
    return CueRange(
      startTimeMilliseconds: int.parse(json['startTimeMilliseconds'] as String),
      endTimeMilliseconds: int.parse(json['endTimeMilliseconds'] as String),
      metadata: CueRangeMetadata.fromMap(
        json['metadata'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  String toString() =>
      'CueRange(startTimeMilliseconds: $startTimeMilliseconds, endTimeMilliseconds: $endTimeMilliseconds, metadata: $metadata)';
}

class TimedLyricsData {
  final String? lyricLine;
  final CueRange? cueRange;

  TimedLyricsData({this.lyricLine, required this.cueRange});

  factory TimedLyricsData.fromMap(Map<String, dynamic> json) {
    return TimedLyricsData(
      lyricLine: json['lyricLine'] as String?,
      cueRange: json['cueRange'] == null
          ? null
          : CueRange.fromMap(json['cueRange'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() =>
      'TimedLyricsData(lyricLine: $lyricLine, cueRange: $cueRange)';
}

class TimedLyricsRes {
  final List<TimedLyricsData> timedLyricsData;
  final String sourceMessage;

  TimedLyricsRes({required this.timedLyricsData, required this.sourceMessage});

  factory TimedLyricsRes.fromMap(Map<String, dynamic> map) {
    return TimedLyricsRes(
      timedLyricsData: List<TimedLyricsData>.from(
        (map['timedLyricsData'] as List).map<TimedLyricsData>(
          (x) => TimedLyricsData.fromMap(x as Map<String, dynamic>),
        ),
      ),
      sourceMessage: map['sourceMessage'] as String,
    );
  }

  @override
  String toString() =>
      'TimedLyricsRes(timedLyricsData: $timedLyricsData, sourceMessage: $sourceMessage)';
}

class ThumbnailFull {
  final String url;
  final int width;
  final int height;

  ThumbnailFull({required this.url, required this.width, required this.height});

  // Construtor nomeado para criar uma ThumbnailFull a partir de um mapa
  ThumbnailFull.fromMap(Map<String, dynamic> map)
    : url = map['url'] as String,
      width = map['width'] as int,
      height = map['height'] as int;
}

class ArtistBasic {
  final String? artistId;
  final String name;

  ArtistBasic({this.artistId, required this.name});

  // Construtor nomeado para criar uma ArtistBasic a partir de um mapa
  ArtistBasic.fromMap(Map<String, dynamic> map)
    : artistId = map['artistId'] as String?,
      name = map['name'] as String;

  @override
  String toString() => 'ArtistBasic(artistId: $artistId, name: $name)';
}

class AlbumBasic {
  final String albumId;
  final String name;

  AlbumBasic({required this.albumId, required this.name});

  // Construtor nomeado para criar uma AlbumBasic a partir de um mapa
  AlbumBasic.fromMap(Map<String, dynamic> map)
    : albumId = map['albumId'] as String,
      name = map['name'] as String;

  @override
  String toString() => 'AlbumBasic(albumId: $albumId, name: $name)';
}

class SongDetailed implements SearchResult {
  @override
  final String type;
  final String videoId;
  final String name;
  final ArtistBasic artist;
  final AlbumBasic? album;
  final int? duration;
  final List<ThumbnailFull> thumbnails;
  final String? playCount;
  final String? albumId;

  /// Whether YouTube Music marks this song with the "Explicit" content badge.
  final bool isExplicit;

  SongDetailed({
    required this.type,
    required this.videoId,
    required this.name,
    required this.artist,
    this.album,
    this.duration,
    required this.thumbnails,
    this.playCount,
    this.albumId,
    this.isExplicit = false,
  });

  SongDetailed.fromMap(Map<String, dynamic> map)
    : type = map['type'] as String,
      videoId = map['videoId'] as String,
      name = map['name'] as String,
      artist = ArtistBasic.fromMap(map['artist']),
      album = map['album'] != null ? AlbumBasic.fromMap(map['album']) : null,
      duration = map['duration'] as int?,
      thumbnails = (map['thumbnails'] as List)
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
      playCount = map['playCount'] as String?,
      albumId = map['albumId'] as String?,
      isExplicit = map['isExplicit'] as bool? ?? false;
}

class VideoDetailed implements SearchResult {
  @override
  final String type;
  final String videoId;
  final String name;
  final ArtistBasic artist;
  final int? duration;
  final List<ThumbnailFull> thumbnails;
  final String? viewCount;

  /// Whether YouTube Music marks this video with the "Explicit" content badge.
  final bool isExplicit;

  VideoDetailed({
    required this.type,
    required this.videoId,
    required this.name,
    required this.artist,
    this.duration,
    required this.thumbnails,
    this.viewCount,
    this.isExplicit = false,
  });

  VideoDetailed.fromMap(Map<String, dynamic> map)
    : type = map['type'] as String,
      videoId = map['videoId'] as String,
      name = map['name'] as String,
      artist = ArtistBasic.fromMap(map['artist']),
      duration = map['duration'] as int?,
      thumbnails = (map['thumbnails'] as List)
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
      viewCount = map['viewCount'] as String?,
      isExplicit = map['isExplicit'] as bool? ?? false;
}

class ArtistDetailed implements SearchResult {
  final String artistId;
  final String name;
  @override
  final String type;
  final List<ThumbnailFull> thumbnails;
  final String? monthlyListeners;

  ArtistDetailed({
    required this.artistId,
    required this.name,
    required this.type,
    required this.thumbnails,
    this.monthlyListeners,
  });

  ArtistDetailed.fromMap(Map<String, dynamic> map)
    : artistId = map['artistId'] as String,
      name = map['name'] as String,
      type = map['type'] as String,
      thumbnails = (map['thumbnails'] as List)
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
      monthlyListeners = map['monthlyListeners'] as String?;
}

class AlbumDetailed implements SearchResult {
  @override
  final String type;
  final String albumId;
  final String playlistId;
  final String name;
  final ArtistBasic artist;
  final int? year;
  final List<ThumbnailFull> thumbnails;

  /// Whether YouTube Music marks this album with the "Explicit" content badge.
  final bool isExplicit;

  AlbumDetailed({
    required this.type,
    required this.albumId,
    required this.playlistId,
    required this.name,
    required this.artist,
    this.year,
    required this.thumbnails,
    this.isExplicit = false,
  });

  // Construtor nomeado para criar uma AlbumDetailed a partir de um mapa
  AlbumDetailed.fromMap(Map<String, dynamic> map)
    : type = map['type'] as String,
      albumId = map['albumId'] as String,
      playlistId = map['playlistId'] as String,
      name = map['name'] as String,
      artist = ArtistBasic.fromMap(map['artist']),
      year = map['year'] as int?,
      thumbnails = (map['thumbnails'] as List)
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
      isExplicit = map['isExplicit'] as bool? ?? false;
}

class PlaylistDetailed implements SearchResult {
  @override
  final String type;
  final String playlistId;
  final String name;
  final ArtistBasic artist;
  final List<ThumbnailFull> thumbnails;

  /// Whether YouTube Music marks this playlist with the "Explicit" content badge.
  final bool isExplicit;

  PlaylistDetailed({
    required this.type,
    required this.playlistId,
    required this.name,
    required this.artist,
    required this.thumbnails,
    this.isExplicit = false,
  });

  // Construtor nomeado para criar uma PlaylistDetailed a partir de um mapa
  PlaylistDetailed.fromMap(Map<String, dynamic> map)
    : type = map['type'] as String,
      playlistId = map['playlistId'] as String,
      name = map['name'] as String,
      artist = ArtistBasic.fromMap(map['artist']),
      thumbnails = (map['thumbnails'] as List)
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
      isExplicit = map['isExplicit'] as bool? ?? false;
}

class SongFull implements SearchResult {
  @override
  final String type;
  final String videoId;
  final String name;
  final ArtistBasic artist;
  final int duration;
  final List<ThumbnailFull> thumbnails;
  final List<dynamic> formats;
  final List<dynamic> adaptiveFormats;
  final int? viewCount;
  final String? channelId;
  final String? publishDate;
  final String? category;
  final AlbumBasic? album;

  /// Whether YouTube Music marks this song with the "Explicit" content badge.
  ///
  /// Derived from the `/next` (watch queue) lookup already performed
  /// internally by [YTMusic.getSong] to resolve [album], since the `/player`
  /// endpoint itself does not expose explicit-content badges.
  final bool isExplicit;

  SongFull({
    required this.type,
    required this.videoId,
    required this.name,
    required this.artist,
    required this.duration,
    required this.thumbnails,
    required this.formats,
    required this.adaptiveFormats,
    this.viewCount,
    this.channelId,
    this.publishDate,
    this.category,
    this.album,
    this.isExplicit = false,
  });

  SongFull.fromMap(Map<String, dynamic> map)
    : type = map['type'] as String,
      videoId = map['videoId'] as String,
      name = map['name'] as String,
      artist = ArtistBasic.fromMap(map['artist']),
      duration = map['duration'] as int,
      thumbnails = (map['thumbnails'] as List)
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
      formats = map['formats'] as List<dynamic>,
      adaptiveFormats = map['adaptiveFormats'] as List<dynamic>,
      viewCount = map['viewCount'] as int?,
      channelId = map['channelId'] as String?,
      publishDate = map['publishDate'] as String?,
      category = map['category'] as String?,
      album = map['album'] != null ? AlbumBasic.fromMap(map['album']) : null,
      isExplicit = map['isExplicit'] as bool? ?? false;

  @override
  String toString() {
    return 'SongFull(type: $type, videoId: $videoId, name: $name, artist: $artist, duration: $duration, thumbnails: $thumbnails, formats: $formats, adaptiveFormats: $adaptiveFormats, album: $album)';
  }
}

class VideoFull {
  final String type;
  final String videoId;
  final String name;
  final ArtistBasic artist;
  final int duration;
  final List<ThumbnailFull> thumbnails;
  final bool unlisted;
  final bool familySafe;
  final bool paid;
  final List<String> tags;
  final int? viewCount;
  final String? publishDate;
  final String? category;
  final String? uploadDate;
  final String? musicVideoType;

  /// Whether YouTube Music marks this video with the "Explicit" content badge.
  final bool isExplicit;

  VideoFull({
    required this.type,
    required this.videoId,
    required this.name,
    required this.artist,
    required this.duration,
    required this.thumbnails,
    required this.unlisted,
    required this.familySafe,
    required this.paid,
    required this.tags,
    this.viewCount,
    this.publishDate,
    this.category,
    this.uploadDate,
    this.musicVideoType,
    this.isExplicit = false,
  });

  VideoFull.fromMap(Map<String, dynamic> map)
    : type = map['type'] as String,
      videoId = map['videoId'] as String,
      name = map['name'] as String,
      artist = ArtistBasic.fromMap(map['artist']),
      duration = map['duration'] as int,
      thumbnails = (map['thumbnails'] as List)
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
      unlisted = map['unlisted'] as bool,
      familySafe = map['familySafe'] as bool,
      paid = map['paid'] as bool,
      tags = (map['tags'] as List).cast<String>(),
      viewCount = map['viewCount'] as int?,
      publishDate = map['publishDate'] as String?,
      category = map['category'] as String?,
      uploadDate = map['uploadDate'] as String?,
      musicVideoType = map['musicVideoType'] as String?,
      isExplicit = map['isExplicit'] as bool? ?? false;
}

class ArtistFull implements SearchResult {
  final String artistId;
  final String name;
  @override
  final String type;
  final List<ThumbnailFull> thumbnails;
  final List<SongDetailed> topSongs;
  final List<AlbumDetailed> topAlbums;
  final List<AlbumDetailed> topSingles;
  final List<VideoDetailed> topVideos;
  final List<PlaylistDetailed> featuredOn;
  final List<ArtistDetailed> similarArtists;
  final String? subscriberCount;
  final String? monthlyListeners;
  final String? totalViews;
  final String? description;
  final String? channelId;

  /// Watch playlist id for artist radio (`RDEM…`), from the header radio button.
  final String? radioId;

  /// Watch playlist id for artist shuffle (`RDAO…`), from the header shuffle button.
  final String? shuffleId;

  ArtistFull({
    required this.artistId,
    required this.name,
    required this.type,
    required this.thumbnails,
    required this.topSongs,
    required this.topAlbums,
    required this.topSingles,
    required this.topVideos,
    required this.featuredOn,
    required this.similarArtists,
    this.subscriberCount,
    this.monthlyListeners,
    this.totalViews,
    this.description,
    this.channelId,
    this.radioId,
    this.shuffleId,
  });

  ArtistFull.fromMap(Map<String, dynamic> map)
    : artistId = map['artistId'] as String,
      name = map['name'] as String,
      type = map['type'] as String,
      thumbnails = (map['thumbnails'] as List)
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
      topSongs = (map['topSongs'] as List)
          .map((item) => SongDetailed.fromMap(item))
          .toList(),
      topAlbums = (map['topAlbums'] as List)
          .map((item) => AlbumDetailed.fromMap(item))
          .toList(),
      topSingles = (map['topSingles'] as List)
          .map((item) => AlbumDetailed.fromMap(item))
          .toList(),
      topVideos = (map['topVideos'] as List)
          .map((item) => VideoDetailed.fromMap(item))
          .toList(),
      featuredOn = (map['featuredOn'] as List)
          .map((item) => PlaylistDetailed.fromMap(item))
          .toList(),
      similarArtists = (map['similarArtists'] as List)
          .map((item) => ArtistDetailed.fromMap(item))
          .toList(),
      subscriberCount = map['subscriberCount'] as String?,
      monthlyListeners = map['monthlyListeners'] as String?,
      totalViews = map['totalViews'] as String?,
      description = map['description'] as String?,
      channelId = map['channelId'] as String?,
      radioId = map['radioId'] as String?,
      shuffleId = map['shuffleId'] as String?;
}

class AlbumFull {
  final String type;
  final String albumId;
  final String playlistId;
  final String name;
  final ArtistBasic artist;
  final int? year;
  final List<ThumbnailFull> thumbnails;
  List<SongDetailed> songs;
  final List<AlbumDetailed> relatedReleases;

  /// Whether YouTube Music marks this album with the "Explicit" content badge.
  final bool isExplicit;

  /// The album description shown on its YouTube Music page, if any.
  final String? description;

  AlbumFull({
    required this.type,
    required this.albumId,
    required this.playlistId,
    required this.name,
    required this.artist,
    this.year,
    required this.thumbnails,
    required this.songs,
    required this.relatedReleases,
    this.isExplicit = false,
    this.description,
  });

  AlbumFull.fromMap(Map<String, dynamic> map)
    : type = map['type'] as String,
      albumId = map['albumId'] as String,
      playlistId = map['playlistId'] as String,
      name = map['name'] as String,
      artist = ArtistBasic.fromMap(map['artist']),
      year = map['year'] as int?,
      thumbnails = (map['thumbnails'] as List)
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
      songs = (map['songs'] as List)
          .map((item) => SongDetailed.fromMap(item))
          .toList(),
      relatedReleases = map['relatedReleases'] != null
          ? (map['relatedReleases'] as List)
                .map((item) => AlbumDetailed.fromMap(item))
                .toList()
          : [],
      isExplicit = map['isExplicit'] as bool? ?? false,
      description = map['description'] as String?;
}

class PlaylistFull {
  final String type;
  final String playlistId;
  final String name;
  final ArtistBasic artist;
  final int videoCount;
  final List<ThumbnailFull> thumbnails;

  /// Whether YouTube Music marks this playlist with the "Explicit" content badge.
  final bool isExplicit;

  /// The playlist description shown on its YouTube Music page, if any.
  final String? description;

  /// Tracks loaded with the playlist (first page + continuations up to [YTMusic.getPlaylist] limit).
  final List<VideoDetailed> tracks;

  PlaylistFull({
    required this.type,
    required this.playlistId,
    required this.name,
    required this.artist,
    required this.videoCount,
    required this.thumbnails,
    this.isExplicit = false,
    this.description,
    this.tracks = const [],
  });

  // Construtor nomeado para criar uma PlaylistFull a partir de um mapa
  PlaylistFull.fromMap(Map<String, dynamic> map)
    : type = map['type'] as String,
      playlistId = map['playlistId'] as String,
      name = map['name'] as String,
      artist = ArtistBasic.fromMap(map['artist']),
      videoCount = map['videoCount'] as int,
      thumbnails = (map['thumbnails'] as List)
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
      isExplicit = map['isExplicit'] as bool? ?? false,
      description = map['description'] as String?,
      tracks = map['tracks'] != null
          ? (map['tracks'] as List)
                .map((item) => VideoDetailed.fromMap(item))
                .toList()
          : const [];
}

// SearchResult é uma union de vários tipos, então é uma interface
abstract class SearchResult {
  String get type;
}

class SongDetailedSearchResult implements SearchResult {
  @override
  final String type = 'SONG';
  final SongDetailed songDetailed;

  SongDetailedSearchResult({required this.songDetailed});
}

class VideoDetailedSearchResult implements SearchResult {
  @override
  final String type = 'VIDEO';
  final VideoDetailed videoDetailed;

  VideoDetailedSearchResult({required this.videoDetailed});
}

class AlbumDetailedSearchResult implements SearchResult {
  @override
  final String type = 'ALBUM';
  final AlbumDetailed albumDetailed;

  AlbumDetailedSearchResult({required this.albumDetailed});
}

class ArtistDetailedSearchResult implements SearchResult {
  @override
  final String type = 'ARTIST';
  final ArtistDetailed artistDetailed;

  ArtistDetailedSearchResult({required this.artistDetailed});
}

class PlaylistDetailedSearchResult implements SearchResult {
  @override
  final String type = 'PLAYLIST';
  final PlaylistDetailed playlistDetailed;

  PlaylistDetailedSearchResult({required this.playlistDetailed});
}

class PodcastDetailed implements SearchResult {
  @override
  final String type;
  final String browseId;
  final String name;
  final String? author;
  final List<ThumbnailFull> thumbnails;

  PodcastDetailed({
    required this.type,
    required this.browseId,
    required this.name,
    this.author,
    required this.thumbnails,
  });
}

class EpisodeDetailed implements SearchResult {
  @override
  final String type;
  final String videoId;
  final String name;
  final String? date;
  final String? podcastName;
  final String? podcastId;
  final List<ThumbnailFull> thumbnails;

  EpisodeDetailed({
    required this.type,
    required this.videoId,
    required this.name,
    this.date,
    this.podcastName,
    this.podcastId,
    required this.thumbnails,
  });
}

class ProfileDetailed implements SearchResult {
  @override
  final String type;
  final String browseId;
  final String name;
  final String? handle;
  final List<ThumbnailFull> thumbnails;

  ProfileDetailed({
    required this.type,
    required this.browseId,
    required this.name,
    this.handle,
    required this.thumbnails,
  });
}

class NewReleasesResult {
  final List<AlbumDetailed> albums;
  final List<VideoDetailed> videos;

  NewReleasesResult({required this.albums, required this.videos});
}

/// Episode row on a podcast page (`musicMultiRowListItemRenderer`).
class PodcastEpisode {
  final String videoId;
  final String browseId;
  final String name;
  final String? description;
  final String? duration;
  final String? date;
  final int? index;
  final List<ThumbnailFull> thumbnails;

  PodcastEpisode({
    required this.videoId,
    required this.browseId,
    required this.name,
    this.description,
    this.duration,
    this.date,
    this.index,
    required this.thumbnails,
  });
}

class PodcastFull {
  final String type;
  final String browseId;
  final String name;
  final ArtistBasic? author;
  final String? description;
  final List<ThumbnailFull> thumbnails;
  final List<PodcastEpisode> episodes;

  PodcastFull({
    this.type = 'PODCAST',
    required this.browseId,
    required this.name,
    this.author,
    this.description,
    required this.thumbnails,
    required this.episodes,
  });
}

class EpisodeFull {
  final String type;
  final String videoId;
  final String browseId;
  final String name;
  final String? date;
  final String? duration;
  final String? description;
  final String? podcastId;
  final String? podcastName;
  final List<ThumbnailFull> thumbnails;

  EpisodeFull({
    this.type = 'EPISODE',
    required this.videoId,
    required this.browseId,
    required this.name,
    this.date,
    this.duration,
    this.description,
    this.podcastId,
    this.podcastName,
    required this.thumbnails,
  });
}

class UserFull {
  final String name;
  final String channelId;
  final String? subscriberCount;
  final List<VideoDetailed> videos;
  final List<PlaylistDetailed> playlists;
  final String? videosParams;
  final String? playlistsParams;

  UserFull({
    required this.name,
    required this.channelId,
    this.subscriberCount,
    required this.videos,
    required this.playlists,
    this.videosParams,
    this.playlistsParams,
  });
}

// Factory per creare un SearchResult a partire da un mapa
SearchResult createSearchResultFromMap(Map<String, dynamic> map) {
  switch (map['type']) {
    case 'SONG':
      return SongDetailedSearchResult(songDetailed: SongDetailed.fromMap(map));
    case 'VIDEO':
      return VideoDetailedSearchResult(
        videoDetailed: VideoDetailed.fromMap(map),
      );
    case 'ALBUM':
      return AlbumDetailedSearchResult(
        albumDetailed: AlbumDetailed.fromMap(map),
      );
    case 'ARTIST':
      return ArtistDetailedSearchResult(
        artistDetailed: ArtistDetailed.fromMap(map),
      );
    case 'PLAYLIST':
      return PlaylistDetailedSearchResult(
        playlistDetailed: PlaylistDetailed.fromMap(map),
      );
    case 'PODCAST':
      return PodcastDetailed(
        type: 'PODCAST',
        browseId: map['browseId'] as String,
        name: map['name'] as String,
        author: map['author'] as String?,
        thumbnails: (map['thumbnails'] as List)
            .map((item) => ThumbnailFull.fromMap(item))
            .toList(),
      );
    case 'EPISODE':
      return EpisodeDetailed(
        type: 'EPISODE',
        videoId: map['videoId'] as String,
        name: map['name'] as String,
        date: map['date'] as String?,
        podcastName: map['podcastName'] as String?,
        podcastId: map['podcastId'] as String?,
        thumbnails: (map['thumbnails'] as List)
            .map((item) => ThumbnailFull.fromMap(item))
            .toList(),
      );
    case 'PROFILE':
      return ProfileDetailed(
        type: 'PROFILE',
        browseId: map['browseId'] as String,
        name: map['name'] as String,
        handle: map['handle'] as String?,
        thumbnails: (map['thumbnails'] as List)
            .map((item) => ThumbnailFull.fromMap(item))
            .toList(),
      );
    default:
      throw ArgumentError('Tipo inválido para SearchResult: ${map['type']}');
  }
}

class UpNextsDetails {
  final String type;
  final String videoId;
  final String title;
  final ArtistBasic artists;
  final AlbumBasic? album;
  final int duration;
  final List<ThumbnailFull> thumbnails;

  /// Whether YouTube Music marks this queued song with the "Explicit" content badge.
  final bool isExplicit;

  UpNextsDetails({
    required this.type,
    required this.videoId,
    required this.title,
    required this.artists,
    this.album,
    required this.duration,
    required this.thumbnails,
    this.isExplicit = false,
  });

  // Construtor nomeado para criar uma UpNextsDetails a partir de um mapa
  UpNextsDetails.fromMap(Map<String, dynamic> map)
    : type = map['type'] as String,
      videoId = map['videoId'] as String,
      title = map['title'] as String,
      artists = ArtistBasic.fromMap(map['artists']),
      album = map['album'] != null ? AlbumBasic.fromMap(map['album']) : null,
      duration = map['duration'] as int,
      thumbnails = (map['thumbnails'] as List)
          .map((item) => ThumbnailFull.fromMap(item))
          .toList(),
      isExplicit = map['isExplicit'] as bool? ?? false;

  @override
  String toString() {
    return 'UpNextsDetails(type: $type, videoId: $videoId, title: $title, artists: $artists, album: $album, duration: $duration, thumbnails: $thumbnails, isExplicit: $isExplicit)';
  }
}

class HomeSection {
  final String title;
  final List<dynamic> contents;
  final String? shelfId;
  final String? browseId;
  final String? browseParams;

  HomeSection({
    required this.title,
    required this.contents,
    this.shelfId,
    this.browseId,
    this.browseParams,
  });

  HomeSection.fromMap(Map<String, dynamic> map)
    : title = map['title'] as String,
      contents = map['contents'] as List<dynamic>,
      shelfId = map['shelfId'] as String?,
      browseId = map['browseId'] as String?,
      browseParams = map['browseParams'] as String?;
}

class BrowseChip {
  final String title;
  final String params;
  final bool isSelected;

  BrowseChip({
    required this.title,
    required this.params,
    required this.isSelected,
  });

  factory BrowseChip.fromMap(Map<String, dynamic> map) {
    final renderer = map['chipCloudChipRenderer'] as Map<String, dynamic>;
    return BrowseChip(
      title: (renderer['text']['runs'] as List)[0]['text'] as String,
      params:
          (renderer['navigationEndpoint']['browseEndpoint']['params']
              as String?) ??
          '',
      isSelected: renderer['isSelected'] as bool? ?? false,
    );
  }
}

class BrowseHomeResult {
  final List<BrowseChip> chips;
  final List<HomeSection> sections;
  final String? backgroundUrl;

  BrowseHomeResult({
    required this.chips,
    required this.sections,
    this.backgroundUrl,
  });
}

class WatchTrack {
  final String videoId;
  final String title;
  final ArtistBasic artist;
  final AlbumBasic? album;
  final int duration;
  final List<ThumbnailFull> thumbnails;
  final bool isExplicit;
  final WatchTrack? counterpart;

  WatchTrack({
    required this.videoId,
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    required this.thumbnails,
    this.isExplicit = false,
    this.counterpart,
  });
}

class WatchPlaylistResult {
  final List<WatchTrack> tracks;
  final String? playlistId;
  final String? lyricsBrowseId;
  final String? relatedBrowseId;

  WatchPlaylistResult({
    required this.tracks,
    this.playlistId,
    this.lyricsBrowseId,
    this.relatedBrowseId,
  });
}

class RelatedSection {
  final String title;
  final List<dynamic> contents;

  RelatedSection({required this.title, required this.contents});
}

class MoodCategory {
  final String title;
  final String params;

  MoodCategory({required this.title, required this.params});
}

class MoodCategoriesResult {
  final Map<String, List<MoodCategory>> sections;

  MoodCategoriesResult({required this.sections});
}

class ChartPlaylist {
  final String title;
  final String playlistId;
  final List<ThumbnailFull> thumbnails;

  ChartPlaylist({
    required this.title,
    required this.playlistId,
    required this.thumbnails,
  });
}

class ChartArtist {
  final String title;
  final String browseId;
  final String? subscribers;
  final List<ThumbnailFull> thumbnails;
  final String? rank;
  final String? trend;

  ChartArtist({
    required this.title,
    required this.browseId,
    this.subscribers,
    required this.thumbnails,
    this.rank,
    this.trend,
  });
}

class ChartsCountries {
  final String selected;
  final List<String> options;

  ChartsCountries({required this.selected, required this.options});
}

class ChartsResult {
  final ChartsCountries countries;
  final List<ChartPlaylist> videos;
  final List<ChartArtist> artists;
  final List<ChartPlaylist>? daily;
  final List<ChartPlaylist>? weekly;
  final List<ChartPlaylist>? genres;
  final List<ChartPlaylist>? languages;

  ChartsResult({
    required this.countries,
    required this.videos,
    required this.artists,
    this.daily,
    this.weekly,
    this.genres,
    this.languages,
  });
}
