import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/models.dart';

abstract class DownloadOptionsService {
  Future<List<DownloadOption>> fetchOptions(RemoteSearchResult result);
}

class DownloadOptionsException implements Exception {
  final String message;
  final Object? cause;

  const DownloadOptionsException(this.message, [this.cause]);

  @override
  String toString() => 'DownloadOptionsException: $message';
}

class YoutubeDownloadOptionsService implements DownloadOptionsService {
  const YoutubeDownloadOptionsService();

  @override
  Future<List<DownloadOption>> fetchOptions(RemoteSearchResult result) async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streams.getManifest(result.id);
      return DownloadOptionMapper.fromAudioOnlyStreams(
        videoId: result.id,
        sourceUrl: result.sourceUrl,
        streams: manifest.audioOnly.map(
          (stream) => DownloadOptionStreamData(
            container: stream.container.name,
            bitrateKbps: stream.bitrate.kiloBitsPerSecond.round(),
            sizeBytes: stream.size.totalBytes,
            streamTag: stream.tag,
          ),
        ),
      );
    } catch (error) {
      throw DownloadOptionsException('Download options fetch failed', error);
    } finally {
      yt.close();
    }
  }
}

class DownloadOptionStreamData {
  final String container;
  final int bitrateKbps;
  final int sizeBytes;
  final int streamTag;

  const DownloadOptionStreamData({
    required this.container,
    required this.bitrateKbps,
    required this.sizeBytes,
    required this.streamTag,
  });
}

class DownloadOptionMapper {
  const DownloadOptionMapper._();

  static List<DownloadOption> fromAudioOnlyStreams({
    required String videoId,
    required String sourceUrl,
    required Iterable<DownloadOptionStreamData> streams,
  }) {
    final selected = <_BucketKey, DownloadOptionStreamData>{};

    for (final stream in streams) {
      final format = _formatForContainer(stream.container);
      final quality = _qualityForBitrate(stream.bitrateKbps);
      if (format == null || quality == null) continue;

      final key = _BucketKey(format, quality);
      final current = selected[key];
      if (current == null || _isBetter(stream, current, quality)) {
        selected[key] = stream;
      }
    }

    final realOptions = selected.entries
        .map(
          (entry) => _toOption(
            videoId: videoId,
            sourceUrl: sourceUrl,
            format: entry.key.format,
            quality: entry.key.quality,
            stream: entry.value,
          ),
        )
        .toList()
      ..sort(_compareOptions);

    return [
      ...realOptions,
      DownloadOption(
        id: '$videoId:${DownloadFormat.mp3.label}:conversion-required',
        videoId: videoId,
        sourceUrl: sourceUrl,
        format: DownloadFormat.mp3,
        disabled: true,
        disabledReason: 'Requiere conversion',
      ),
    ];
  }

  static DownloadFormat? _formatForContainer(String container) {
    final normalized = container.trim().toLowerCase();
    if (normalized == 'mp4') return DownloadFormat.m4a;
    if (normalized == 'webm') return DownloadFormat.opus;
    return null;
  }

  static DownloadQuality? _qualityForBitrate(int bitrateKbps) {
    if (bitrateKbps >= 96 && bitrateKbps <= 160) {
      return DownloadQuality.kbps128;
    }
    if (bitrateKbps >= 161 && bitrateKbps <= 288) {
      return DownloadQuality.kbps256;
    }
    if (bitrateKbps > 288) return DownloadQuality.kbps320;
    return null;
  }

  static bool _isBetter(
    DownloadOptionStreamData candidate,
    DownloadOptionStreamData current,
    DownloadQuality quality,
  ) {
    final candidateDistance =
        (candidate.bitrateKbps - quality.targetKbps).abs();
    final currentDistance = (current.bitrateKbps - quality.targetKbps).abs();
    if (candidateDistance != currentDistance) {
      return candidateDistance < currentDistance;
    }
    if (candidate.sizeBytes != current.sizeBytes) {
      return candidate.sizeBytes > current.sizeBytes;
    }
    return candidate.streamTag < current.streamTag;
  }

  static DownloadOption _toOption({
    required String videoId,
    required String sourceUrl,
    required DownloadFormat format,
    required DownloadQuality quality,
    required DownloadOptionStreamData stream,
  }) {
    return DownloadOption(
      id: '$videoId:${format.label}:${quality.label}:${stream.streamTag}',
      videoId: videoId,
      sourceUrl: sourceUrl,
      format: format,
      quality: quality,
      bitrateKbps: stream.bitrateKbps,
      sizeBytes: stream.sizeBytes <= 0 ? null : stream.sizeBytes,
      streamTag: stream.streamTag,
      disabled: false,
    );
  }

  static int _compareOptions(DownloadOption a, DownloadOption b) {
    final formatOrder = a.format.index.compareTo(b.format.index);
    if (formatOrder != 0) return formatOrder;
    return (a.quality?.index ?? 999).compareTo(b.quality?.index ?? 999);
  }
}

class _BucketKey {
  final DownloadFormat format;
  final DownloadQuality quality;

  const _BucketKey(this.format, this.quality);

  @override
  bool operator ==(Object other) =>
      other is _BucketKey &&
      other.format == format &&
      other.quality == quality;

  @override
  int get hashCode => Object.hash(format, quality);
}
