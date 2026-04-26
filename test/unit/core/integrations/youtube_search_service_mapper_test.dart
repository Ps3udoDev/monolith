import 'package:flutter_test/flutter_test.dart';
import 'package:monolith/core/integrations/youtube/youtube_search_service.dart';

void main() {
  test('maps required remote search fields deterministically', () {
    final result = RemoteSearchResultMapper.fromFields(
      id: 'abc123def45',
      title: 'Midnight Signal',
      artist: 'Lianne Hoffmann',
      duration: const Duration(minutes: 3, seconds: 41),
      thumbnailUrl: 'https://img.youtube.com/vi/abc123def45/hqdefault.jpg',
      sourceUrl: 'https://www.youtube.com/watch?v=abc123def45',
    );

    expect(result.id, 'abc123def45');
    expect(result.title, 'Midnight Signal');
    expect(result.artist, 'Lianne Hoffmann');
    expect(result.duration, const Duration(minutes: 3, seconds: 41));
    expect(
      result.thumbnailUrl,
      'https://img.youtube.com/vi/abc123def45/hqdefault.jpg',
    );
    expect(result.sourceUrl, 'https://www.youtube.com/watch?v=abc123def45');
  });

  test('maps empty artist to Spanish fallback', () {
    final result = RemoteSearchResultMapper.fromFields(
      id: 'abc123def45',
      title: 'Midnight Signal',
      artist: '   ',
      duration: null,
      thumbnailUrl: null,
      sourceUrl: 'https://www.youtube.com/watch?v=abc123def45',
    );

    expect(result.artist, 'Desconocido');
  });

  test('keeps canonical source URL unchanged', () {
    final result = RemoteSearchResultMapper.fromFields(
      id: 'abc123def45',
      title: 'Midnight Signal',
      artist: 'Lianne Hoffmann',
      duration: null,
      thumbnailUrl: null,
      sourceUrl: 'https://www.youtube.com/watch?v=abc123def45',
    );

    expect(result.sourceUrl, 'https://www.youtube.com/watch?v=abc123def45');
  });
}
