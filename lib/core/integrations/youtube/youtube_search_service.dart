import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/models.dart';

abstract class SearchSongsService {
  Future<List<RemoteSearchResult>> searchSongs(String query, {int limit = 10});
}

class RemoteSearchException implements Exception {
  final String message;
  final Object? cause;

  const RemoteSearchException(this.message, [this.cause]);

  @override
  String toString() => 'RemoteSearchException: $message';
}

class YoutubeSearchService implements SearchSongsService {
  const YoutubeSearchService();

  @override
  Future<List<RemoteSearchResult>> searchSongs(
    String query, {
    int limit = 10,
  }) async {
    final yt = YoutubeExplode();
    try {
      final videos = await yt.search.search(query);
      return videos
          .take(limit)
          .map(RemoteSearchResultMapper.fromVideo)
          .toList(growable: false);
    } catch (error) {
      throw RemoteSearchException('Remote search failed', error);
    } finally {
      yt.close();
    }
  }
}

class RemoteSearchResultMapper {
  const RemoteSearchResultMapper._();

  static RemoteSearchResult fromVideo(Video video) {
    final id = video.id.value;
    return fromFields(
      id: id,
      title: video.title,
      artist: video.author,
      duration: video.duration,
      thumbnailUrl: video.thumbnails.highResUrl,
      sourceUrl: 'https://www.youtube.com/watch?v=$id',
    );
  }

  static RemoteSearchResult fromFields({
    required String id,
    required String title,
    required String artist,
    required Duration? duration,
    required String? thumbnailUrl,
    required String sourceUrl,
  }) {
    final normalizedArtist = artist.trim();
    return RemoteSearchResult(
      id: id,
      title: title,
      artist: normalizedArtist.isEmpty ? 'Desconocido' : normalizedArtist,
      duration: duration,
      thumbnailUrl: thumbnailUrl,
      sourceUrl: sourceUrl,
    );
  }
}
