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
