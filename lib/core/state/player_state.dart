import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models.dart';
import '../data/seed_data.dart';
import '../theme/tokens.dart';
import '../../shared/widgets/visualizer.dart';

enum AppRoute { library, search, download, favorites, album, artist, settings }

class PlayerState extends ChangeNotifier {
  AppRoute route = AppRoute.library;
  bool playerOpen = false;
  String currentTrackId = 'b1';
  bool playing = false;
  double position = 48;
  int duration = 221;
  final Set<String> favorites = {'a1', 'b1', 'c2'};
  bool shuffle = false;
  bool repeat = false;
  bool scrubbing = false;
  String? albumId;
  String? artistName;
  List<String> recentSearches = ['Pendant', 'Ambient', 'Brume'];

  // ── User-configurable settings (in-memory; not persisted yet) ──
  String variant = 'bold';
  bool libraryGrid = false;
  bool nowPlayingRadial = true;
  VizStyle vizStyle = VizStyle.spectrum;
  double accentHue = AppTokens.accentHueDefault;

  Timer? _ticker;

  PlayerState() {
    _restartTickerIfNeeded();
  }

  Track get currentTrack => lookupTrack(currentTrackId) ?? kLibrary.first;

  double get progress =>
      duration > 0 ? (position / duration).clamp(0.0, 1.0) : 0.0;

  void navigate(AppRoute next, {String? id, String? name}) {
    route = next;
    playerOpen = false;
    if (next == AppRoute.album) albumId = id;
    if (next == AppRoute.artist) artistName = name;
    notifyListeners();
  }

  void openPlayer() {
    playerOpen = true;
    notifyListeners();
  }

  void closePlayer() {
    playerOpen = false;
    notifyListeners();
  }

  void togglePlay() {
    playing = !playing;
    _restartTickerIfNeeded();
    notifyListeners();
  }

  void playTrack(String id) {
    final t = lookupTrack(id);
    if (t == null) return;
    currentTrackId = id;
    duration = t.duration;
    position = 0;
    playing = true;
    playerOpen = true;
    _restartTickerIfNeeded();
    notifyListeners();
  }

  void toggleFavorite(String id) {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    notifyListeners();
  }

  void addRecentSearch(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final updated = [
      normalized,
      ...recentSearches.where(
        (item) => item.toLowerCase() != normalized.toLowerCase(),
      ),
    ].take(5).toList();

    if (listEquals(updated, recentSearches)) return;
    recentSearches = updated;
    notifyListeners();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    repeat = !repeat;
    notifyListeners();
  }

  void scrubStart() {
    scrubbing = true;
    notifyListeners();
  }

  void scrub(double pos) {
    position = pos;
    notifyListeners();
  }

  void scrubEnd() {
    scrubbing = false;
    notifyListeners();
  }

  void next() => _advance(1);
  void previous() => _advance(-1);

  void _advance(int dir) {
    final idx = kLibrary.indexWhere((t) => t.id == currentTrackId);
    if (idx < 0) return;
    final n = (idx + dir + kLibrary.length) % kLibrary.length;
    final nt = kLibrary[n];
    currentTrackId = nt.id;
    duration = nt.duration;
    position = 0;
    notifyListeners();
  }

  // ── Settings setters ────────────────────────────────────────────────
  void setVariant(String v) {
    variant = v;
    // Preset: Safe = clean grid + linear player, Bold = shelf + radial player.
    if (v == 'safe') {
      libraryGrid = true;
      nowPlayingRadial = false;
    } else {
      libraryGrid = false;
      nowPlayingRadial = true;
    }
    notifyListeners();
  }

  void setLibraryGrid(bool v) {
    libraryGrid = v;
    notifyListeners();
  }

  void setNowPlayingRadial(bool v) {
    nowPlayingRadial = v;
    notifyListeners();
  }

  void setVizStyle(VizStyle s) {
    vizStyle = s;
    notifyListeners();
  }

  void setAccentHue(double h) {
    accentHue = h;
    AppTokens.accentHueValue = h;
    notifyListeners();
  }

  void _restartTickerIfNeeded() {
    _ticker?.cancel();
    _ticker = null;
    if (!playing) return;
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!playing || scrubbing) return;
      final np = position + 0.5;
      if (np >= duration) {
        _advance(1);
      } else {
        position = np;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
