import 'package:flutter_test/flutter_test.dart';
import 'package:monolith/core/data/models.dart';
import 'package:monolith/core/integrations/youtube/youtube_link_resolver_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  const videoId = 'dQw4w9WgXcQ';
  const defaultResult = RemoteSearchResult(
    id: videoId,
    title: 'Mock title',
    artist: 'Mock artist',
    sourceUrl: 'https://www.youtube.com/watch?v=$videoId',
  );

  YoutubeLinkResolverService buildService({
    void Function(String id)? captureInto,
    Object? throwError,
    RemoteSearchResult? returns,
  }) {
    return YoutubeLinkResolverService(
      testLookup: (id) async {
        captureInto?.call(id);
        if (throwError != null) throw throwError;
        return returns ?? defaultResult;
      },
    );
  }

  group('VideoId extraction', () {
    test('extracts ID from youtube.com/watch?v=ID', () async {
      String? captured;
      final service = buildService(captureInto: (id) => captured = id);
      await service.resolve('https://www.youtube.com/watch?v=$videoId');
      expect(captured, videoId);
    });

    test('extracts ID from youtu.be/ID', () async {
      String? captured;
      final service = buildService(captureInto: (id) => captured = id);
      await service.resolve('https://youtu.be/$videoId');
      expect(captured, videoId);
    });

    test('extracts ID from music.youtube.com/watch?v=ID', () async {
      String? captured;
      final service = buildService(captureInto: (id) => captured = id);
      await service.resolve('https://music.youtube.com/watch?v=$videoId');
      expect(captured, videoId);
    });

    test('extracts ID from youtube.com/shorts/ID', () async {
      String? captured;
      final service = buildService(captureInto: (id) => captured = id);
      await service.resolve('https://www.youtube.com/shorts/$videoId');
      expect(captured, videoId);
    });

    test(
      'extracts ID when extra query parameters are present (si, t, feature, list)',
      () async {
        final inputs = [
          'https://www.youtube.com/watch?v=$videoId&si=abc123',
          'https://www.youtube.com/watch?v=$videoId&t=42',
          'https://www.youtube.com/watch?v=$videoId&feature=share',
          'https://www.youtube.com/watch?v=$videoId&list=PLabcDEF12',
        ];
        for (final input in inputs) {
          String? captured;
          final service = buildService(captureInto: (id) => captured = id);
          await service.resolve(input);
          expect(captured, videoId, reason: 'failed for $input');
        }
      },
    );

    test('returns the resolved RemoteSearchResult from the lookup', () async {
      final service = buildService(returns: defaultResult);
      final actual = await service.resolve(
        'https://www.youtube.com/watch?v=$videoId',
      );
      expect(actual, same(defaultResult));
    });
  });

  group('Playlist-only classification', () {
    test('rejects youtube.com/playlist?list=PL... as playlistOnly', () async {
      final service = const YoutubeLinkResolverService();
      try {
        await service.resolve(
          'https://www.youtube.com/playlist?list=PLabcDEF12',
        );
        fail('expected LinkResolutionException');
      } on LinkResolutionException catch (e) {
        expect(e.kind, LinkResolutionExceptionKind.playlistOnly);
        expect(e.cause, isNull);
      }
    });

    test('rejects watch?list=PL... without v= as playlistOnly', () async {
      final service = const YoutubeLinkResolverService();
      try {
        await service.resolve(
          'https://www.youtube.com/watch?list=PLabcDEF12',
        );
        fail('expected LinkResolutionException');
      } on LinkResolutionException catch (e) {
        expect(e.kind, LinkResolutionExceptionKind.playlistOnly);
        expect(e.cause, isNull);
      }
    });
  });

  group('Invalid input', () {
    test('throws invalid for empty string', () async {
      final service = const YoutubeLinkResolverService();
      try {
        await service.resolve('');
        fail('expected LinkResolutionException');
      } on LinkResolutionException catch (e) {
        expect(e.kind, LinkResolutionExceptionKind.invalid);
        expect(e.cause, isNull);
      }
    });

    test('throws invalid for whitespace-only input', () async {
      final service = const YoutubeLinkResolverService();
      try {
        await service.resolve('   ');
        fail('expected LinkResolutionException');
      } on LinkResolutionException catch (e) {
        expect(e.kind, LinkResolutionExceptionKind.invalid);
        expect(e.cause, isNull);
      }
    });

    test('throws invalid for non-YouTube URLs', () async {
      final service = const YoutubeLinkResolverService();
      try {
        await service.resolve('https://example.com/song');
        fail('expected LinkResolutionException');
      } on LinkResolutionException catch (e) {
        expect(e.kind, LinkResolutionExceptionKind.invalid);
        expect(e.cause, isNull);
      }
    });

    test('throws invalid for arbitrary plain text', () async {
      final service = const YoutubeLinkResolverService();
      try {
        await service.resolve('not a url at all');
        fail('expected LinkResolutionException');
      } on LinkResolutionException catch (e) {
        expect(e.kind, LinkResolutionExceptionKind.invalid);
        expect(e.cause, isNull);
      }
    });
  });

  group('Lookup failure mapping', () {
    test(
      'maps VideoUnplayableException to LinkResolutionException(unavailable)',
      () async {
        final cause = VideoUnplayableException('Video is private');
        final service = buildService(throwError: cause);
        try {
          await service.resolve(
            'https://www.youtube.com/watch?v=$videoId',
          );
          fail('expected LinkResolutionException');
        } on LinkResolutionException catch (e) {
          expect(e.kind, LinkResolutionExceptionKind.unavailable);
          expect(e.cause, same(cause));
        }
      },
    );

    test(
      'maps VideoUnavailableException (subtype) to unavailable',
      () async {
        final cause = VideoUnavailableException('Video has been removed');
        final service = buildService(throwError: cause);
        try {
          await service.resolve(
            'https://www.youtube.com/watch?v=$videoId',
          );
          fail('expected LinkResolutionException');
        } on LinkResolutionException catch (e) {
          expect(e.kind, LinkResolutionExceptionKind.unavailable);
          expect(e.cause, same(cause));
        }
      },
    );

    test('maps generic exceptions to network', () async {
      final cause = Exception('network down');
      final service = buildService(throwError: cause);
      try {
        await service.resolve('https://www.youtube.com/watch?v=$videoId');
        fail('expected LinkResolutionException');
      } on LinkResolutionException catch (e) {
        expect(e.kind, LinkResolutionExceptionKind.network);
        expect(e.cause, same(cause));
      }
    });
  });
}
