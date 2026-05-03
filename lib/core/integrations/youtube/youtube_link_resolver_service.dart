import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/models.dart';
import 'youtube_search_service.dart' show RemoteSearchResultMapper;

enum LinkResolutionExceptionKind {
  invalid,
  playlistOnly,
  unavailable,
  network,
}

class LinkResolutionException implements Exception {
  final LinkResolutionExceptionKind kind;
  final String message;
  final Object? cause;

  const LinkResolutionException._({
    required this.kind,
    required this.message,
    this.cause,
  });

  const LinkResolutionException.invalid()
      : this._(
          kind: LinkResolutionExceptionKind.invalid,
          message: 'Link is not a valid YouTube video URL',
        );

  const LinkResolutionException.playlistOnly()
      : this._(
          kind: LinkResolutionExceptionKind.playlistOnly,
          message: 'Link points to a playlist without a video',
        );

  const LinkResolutionException.unavailable(Object cause)
      : this._(
          kind: LinkResolutionExceptionKind.unavailable,
          message: 'Video is unavailable',
          cause: cause,
        );

  const LinkResolutionException.network(Object cause)
      : this._(
          kind: LinkResolutionExceptionKind.network,
          message: 'Could not resolve link',
          cause: cause,
        );

  @override
  String toString() =>
      'LinkResolutionException(kind: $kind, message: $message)';
}

abstract class LinkResolverService {
  Future<RemoteSearchResult> resolve(String rawUrl);
}

typedef VideoLookup = Future<RemoteSearchResult> Function(String videoId);

class YoutubeLinkResolverService implements LinkResolverService {
  final VideoLookup? _testLookup;

  const YoutubeLinkResolverService({VideoLookup? testLookup})
      : _testLookup = testLookup;

  @override
  Future<RemoteSearchResult> resolve(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw const LinkResolutionException.invalid();
    }
    if (_isPlaylistOnly(trimmed)) {
      throw const LinkResolutionException.playlistOnly();
    }
    final videoId = VideoId.parseVideoId(trimmed);
    if (videoId == null) {
      throw const LinkResolutionException.invalid();
    }
    final lookup = _testLookup ?? _defaultLookup;
    try {
      return await lookup(videoId);
    } on LinkResolutionException {
      rethrow;
    } catch (error) {
      throw _classify(error);
    }
  }

  static bool _isPlaylistOnly(String url) {
    Uri? uri;
    try {
      uri = Uri.parse(_ensureScheme(url));
    } catch (_) {
      return false;
    }
    final pathLower = uri.path.toLowerCase();
    if (pathLower.endsWith('/playlist')) return true;
    final hasList = uri.queryParameters.containsKey('list');
    final hasV = uri.queryParameters.containsKey('v');
    return hasList && !hasV;
  }

  static String _ensureScheme(String url) {
    final lower = url.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return url;
    }
    return 'https://$url';
  }

  static LinkResolutionException _classify(Object error) {
    if (error is VideoUnplayableException) {
      return LinkResolutionException.unavailable(error);
    }
    return LinkResolutionException.network(error);
  }

  static Future<RemoteSearchResult> _defaultLookup(String videoId) async {
    final yt = YoutubeExplode();
    try {
      final video = await yt.videos.get(VideoId(videoId));
      return RemoteSearchResultMapper.fromVideo(video);
    } finally {
      yt.close();
    }
  }
}
