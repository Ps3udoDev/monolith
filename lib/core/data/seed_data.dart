import 'models.dart';

const List<Track> kLibrary = [
  Track(id: 'a1', title: 'Midnight Fold', artist: 'Lianne Hoffmann', album: 'Softcore Cartography', year: 2024, genre: 'Ambient', duration: 247, size: 6.2, bitrate: '256 kbps', format: 'M4A', seed: 11, cover: 'c-indigo'),
  Track(id: 'a2', title: 'Paper Radio', artist: 'Lianne Hoffmann', album: 'Softcore Cartography', year: 2024, genre: 'Ambient', duration: 198, size: 4.9, bitrate: '256 kbps', format: 'M4A', seed: 27, cover: 'c-indigo'),
  Track(id: 'a3', title: 'Slow Orbit', artist: 'Lianne Hoffmann', album: 'Softcore Cartography', year: 2024, genre: 'Ambient', duration: 314, size: 7.8, bitrate: '256 kbps', format: 'M4A', seed: 41, cover: 'c-indigo'),
  Track(id: 'b1', title: 'Terracotta', artist: 'Pendant', album: 'Interior Weather', year: 2023, genre: 'Electronic', duration: 221, size: 8.8, bitrate: '320 kbps', format: 'MP3', seed: 7, cover: 'c-clay'),
  Track(id: 'b2', title: 'Warm Front', artist: 'Pendant', album: 'Interior Weather', year: 2023, genre: 'Electronic', duration: 284, size: 11.3, bitrate: '320 kbps', format: 'MP3', seed: 19, cover: 'c-clay'),
  Track(id: 'b3', title: 'Low Ceiling', artist: 'Pendant', album: 'Interior Weather', year: 2023, genre: 'Electronic', duration: 192, size: 7.7, bitrate: '320 kbps', format: 'MP3', seed: 33, cover: 'c-clay'),
  Track(id: 'c1', title: 'Tidewater', artist: 'Moss & Rail', album: 'Kiln', year: 2022, genre: 'Post-Rock', duration: 412, size: 9.6, bitrate: '256 kbps', format: 'Opus', seed: 5, cover: 'c-moss'),
  Track(id: 'c2', title: 'The Cartographer Sleeps', artist: 'Moss & Rail', album: 'Kiln', year: 2022, genre: 'Post-Rock', duration: 376, size: 8.7, bitrate: '256 kbps', format: 'Opus', seed: 23, cover: 'c-moss'),
  Track(id: 'd1', title: 'Sodium Lights', artist: 'Brume', album: 'Late Shift', year: 2025, genre: 'Electronic', duration: 233, size: 9.3, bitrate: '320 kbps', format: 'MP3', seed: 15, cover: 'c-sodium'),
  Track(id: 'd2', title: 'Ferry Terminal', artist: 'Brume', album: 'Late Shift', year: 2025, genre: 'Electronic', duration: 301, size: 12.0, bitrate: '320 kbps', format: 'MP3', seed: 29, cover: 'c-sodium'),
  Track(id: 'e1', title: 'Vantablack Sonata', artist: 'Ilmatar', album: 'Negatives', year: 2024, genre: 'Classical', duration: 506, size: 10.1, bitrate: '192 kbps', format: 'Opus', seed: 3, cover: 'c-bone'),
  Track(id: 'e2', title: 'Marginalia', artist: 'Ilmatar', album: 'Negatives', year: 2024, genre: 'Classical', duration: 289, size: 5.8, bitrate: '192 kbps', format: 'Opus', seed: 37, cover: 'c-bone'),
];

const List<Album> kAlbums = [
  Album(id: 'alb1', title: 'Softcore Cartography', artist: 'Lianne Hoffmann', year: 2024, cover: 'c-indigo', trackIds: ['a1', 'a2', 'a3']),
  Album(id: 'alb2', title: 'Interior Weather', artist: 'Pendant', year: 2023, cover: 'c-clay', trackIds: ['b1', 'b2', 'b3']),
  Album(id: 'alb3', title: 'Kiln', artist: 'Moss & Rail', year: 2022, cover: 'c-moss', trackIds: ['c1', 'c2']),
  Album(id: 'alb4', title: 'Late Shift', artist: 'Brume', year: 2025, cover: 'c-sodium', trackIds: ['d1', 'd2']),
  Album(id: 'alb5', title: 'Negatives', artist: 'Ilmatar', year: 2024, cover: 'c-bone', trackIds: ['e1', 'e2']),
];

const List<Artist> kArtists = [
  Artist(id: 'art1', name: 'Lianne Hoffmann', trackCount: 3, genre: 'Ambient', cover: 'c-indigo'),
  Artist(id: 'art2', name: 'Pendant', trackCount: 3, genre: 'Electronic', cover: 'c-clay'),
  Artist(id: 'art3', name: 'Moss & Rail', trackCount: 2, genre: 'Post-Rock', cover: 'c-moss'),
  Artist(id: 'art4', name: 'Brume', trackCount: 2, genre: 'Electronic', cover: 'c-sodium'),
  Artist(id: 'art5', name: 'Ilmatar', trackCount: 2, genre: 'Classical', cover: 'c-bone'),
];

Track? lookupTrack(String id) {
  for (final t in kLibrary) {
    if (t.id == id) return t;
  }
  return null;
}

List<Track> tracksByArtist(String name) =>
    kLibrary.where((t) => t.artist == name).toList();

List<Track> tracksByAlbum(String albumId) {
  final alb = kAlbums.where((a) => a.id == albumId).cast<Album?>().firstWhere(
        (a) => a != null,
        orElse: () => null,
      );
  if (alb == null) return [];
  return alb.trackIds.map(lookupTrack).whereType<Track>().toList();
}

List<Track> recommendations(String currentId) {
  final cur = lookupTrack(currentId);
  if (cur == null) return [];
  final scored = kLibrary
      .where((t) => t.id != cur.id)
      .map((t) {
        final score = (t.genre == cur.genre ? 2.0 : 0.0) +
            (t.artist == cur.artist ? 1.5 : 0.0);
        return MapEntry(t, score);
      })
      .where((e) => e.value > 0)
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return scored.take(6).map((e) => e.key).toList();
}
