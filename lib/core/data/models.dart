class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int year;
  final String genre;
  final int duration;
  final double size;
  final String bitrate;
  final String format;
  final int seed;
  final String cover;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.year,
    required this.genre,
    required this.duration,
    required this.size,
    required this.bitrate,
    required this.format,
    required this.seed,
    required this.cover,
  });
}

class Album {
  final String id;
  final String title;
  final String artist;
  final int year;
  final String cover;
  final List<String> trackIds;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.year,
    required this.cover,
    required this.trackIds,
  });
}

class Artist {
  final String id;
  final String name;
  final int trackCount;
  final String genre;
  final String cover;

  const Artist({
    required this.id,
    required this.name,
    required this.trackCount,
    required this.genre,
    required this.cover,
  });
}

class RemoteSearchResult {
  final String id;
  final String title;
  final String artist;
  final Duration? duration;
  final String? thumbnailUrl;
  final String sourceUrl;

  const RemoteSearchResult({
    required this.id,
    required this.title,
    required this.artist,
    required this.sourceUrl,
    this.duration,
    this.thumbnailUrl,
  });
}

enum DownloadFormat {
  m4a('M4A'),
  opus('Opus'),
  mp3('MP3');

  final String label;
  const DownloadFormat(this.label);
}

enum DownloadQuality {
  kbps128('128 kbps', 128),
  kbps256('256 kbps', 256),
  kbps320('320 kbps', 320);

  final String label;
  final int targetKbps;
  const DownloadQuality(this.label, this.targetKbps);
}

class DownloadOption {
  final String id;
  final String videoId;
  final String sourceUrl;
  final DownloadFormat format;
  final DownloadQuality? quality;
  final int? bitrateKbps;
  final int? sizeBytes;
  final int? streamTag;
  final bool disabled;
  final String? disabledReason;

  const DownloadOption({
    required this.id,
    required this.videoId,
    required this.sourceUrl,
    required this.format,
    required this.disabled,
    this.quality,
    this.bitrateKbps,
    this.sizeBytes,
    this.streamTag,
    this.disabledReason,
  });
}
