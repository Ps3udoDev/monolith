import 'package:flutter_test/flutter_test.dart';
import 'package:monolith/core/data/models.dart';
import 'package:monolith/core/integrations/youtube/youtube_download_options_service.dart';

void main() {
  const videoId = 'abc123def45';
  const sourceUrl = 'https://www.youtube.com/watch?v=abc123def45';

  List<DownloadOption> map(List<DownloadOptionStreamData> streams) {
    return DownloadOptionMapper.fromAudioOnlyStreams(
      videoId: videoId,
      sourceUrl: sourceUrl,
      streams: streams,
    );
  }

  test('maps mp4 container to M4A', () {
    final options = map(const [
      DownloadOptionStreamData(
        container: 'mp4',
        bitrateKbps: 128,
        sizeBytes: 3000000,
        streamTag: 140,
      ),
    ]);

    expect(options.first.format, DownloadFormat.m4a);
    expect(options.first.quality, DownloadQuality.kbps128);
  });

  test('maps webm container to Opus', () {
    final options = map(const [
      DownloadOptionStreamData(
        container: 'webm',
        bitrateKbps: 128,
        sizeBytes: 3000000,
        streamTag: 251,
      ),
    ]);

    expect(options.first.format, DownloadFormat.opus);
    expect(options.first.quality, DownloadQuality.kbps128);
  });

  test('ignores unsupported containers', () {
    final options = map(const [
      DownloadOptionStreamData(
        container: 'flac',
        bitrateKbps: 128,
        sizeBytes: 3000000,
        streamTag: 1,
      ),
    ]);

    expect(options.where((option) => !option.disabled), isEmpty);
  });

  test('maps bitrate ranges to quality labels', () {
    final options = map(const [
      DownloadOptionStreamData(
        container: 'mp4',
        bitrateKbps: 96,
        sizeBytes: 1000000,
        streamTag: 1,
      ),
      DownloadOptionStreamData(
        container: 'webm',
        bitrateKbps: 161,
        sizeBytes: 2000000,
        streamTag: 2,
      ),
      DownloadOptionStreamData(
        container: 'mp4',
        bitrateKbps: 289,
        sizeBytes: 3000000,
        streamTag: 3,
      ),
    ]);

    expect(
      options.where((option) => !option.disabled).map((option) => option.quality),
      containsAll([
        DownloadQuality.kbps128,
        DownloadQuality.kbps256,
        DownloadQuality.kbps320,
      ]),
    );
  });

  test('ignores bitrates below 96 kbps', () {
    final options = map(const [
      DownloadOptionStreamData(
        container: 'mp4',
        bitrateKbps: 95,
        sizeBytes: 1000000,
        streamTag: 1,
      ),
    ]);

    expect(options.where((option) => !option.disabled), isEmpty);
  });

  test('keeps one closest option per format and quality bucket', () {
    final options = map(const [
      DownloadOptionStreamData(
        container: 'mp4',
        bitrateKbps: 110,
        sizeBytes: 1000000,
        streamTag: 1,
      ),
      DownloadOptionStreamData(
        container: 'mp4',
        bitrateKbps: 127,
        sizeBytes: 2000000,
        streamTag: 2,
      ),
    ]);

    final realOptions = options.where((option) => !option.disabled).toList();

    expect(realOptions, hasLength(1));
    expect(realOptions.single.bitrateKbps, 127);
    expect(realOptions.single.streamTag, 2);
  });

  test('breaks ties by larger size and then lower stream tag', () {
    final largerSize = map(const [
      DownloadOptionStreamData(
        container: 'mp4',
        bitrateKbps: 126,
        sizeBytes: 1000000,
        streamTag: 10,
      ),
      DownloadOptionStreamData(
        container: 'mp4',
        bitrateKbps: 130,
        sizeBytes: 2000000,
        streamTag: 11,
      ),
    ]).first;

    final lowerTag = map(const [
      DownloadOptionStreamData(
        container: 'mp4',
        bitrateKbps: 126,
        sizeBytes: 1000000,
        streamTag: 10,
      ),
      DownloadOptionStreamData(
        container: 'mp4',
        bitrateKbps: 130,
        sizeBytes: 1000000,
        streamTag: 9,
      ),
    ]).first;

    expect(largerSize.streamTag, 11);
    expect(lowerTag.streamTag, 9);
  });

  test('maps zero-byte size to nullable sizeBytes', () {
    final options = map(const [
      DownloadOptionStreamData(
        container: 'mp4',
        bitrateKbps: 128,
        sizeBytes: 0,
        streamTag: 140,
      ),
    ]);

    expect(options.first.sizeBytes, isNull);
  });

  test('always appends disabled MP3 option', () {
    final options = map(const []);
    final mp3 = options.single;

    expect(mp3.format, DownloadFormat.mp3);
    expect(mp3.disabled, isTrue);
    expect(mp3.disabledReason, 'Requiere conversion');
    expect(mp3.streamTag, isNull);
  });

  test('builds deterministic option IDs', () {
    final options = map(const [
      DownloadOptionStreamData(
        container: 'mp4',
        bitrateKbps: 128,
        sizeBytes: 3000000,
        streamTag: 140,
      ),
    ]);

    expect(options.first.id, '$videoId:M4A:128 kbps:140');
    expect(options.last.id, '$videoId:MP3:conversion-required');
  });
}
