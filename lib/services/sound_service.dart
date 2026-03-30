import 'package:audioplayers/audioplayers.dart';

/// Plays short sound effects for fidget toys.
///
/// Sound files are loaded from assets/sounds/. If a file is missing the
/// service silently skips playback — the app works fine without them.
///
/// Required files (place in assets/sounds/ and uncomment the assets entry
/// in pubspec.yaml, then run `flutter pub get`):
///   • bubble_pop.mp3       — short pop (~0.1 s)
///   • stress_ball_squeeze.mp3 — soft rubbery squish (~0.1–0.2 s)
///   • stress_ball_release.mp3 — light bounce/snap (~0.1 s)
class SoundService {
  SoundService._();
  static final instance = SoundService._();

  // Round-robin pool so rapid pops can overlap without cutting each other off
  static const _popPoolSize = 6;
  final _popPlayers = <AudioPlayer>[];
  int _popIdx = 0;

  final _squeezePlayer = AudioPlayer();
  final _releasePlayer = AudioPlayer();

  bool _popsReady = false;
  bool _squeezeReady = false;
  bool _releaseReady = false;

  Future<void> init() async {
    await _loadPops();
    await _loadSqueeze();
    await _loadRelease();
  }

  Future<void> _loadPops() async {
    try {
      for (var i = 0; i < _popPoolSize; i++) {
        final p = AudioPlayer();
        await p.setSource(AssetSource('sounds/bubble_pop.mp3'));
        await p.setVolume(0.85);
        _popPlayers.add(p);
      }
      _popsReady = true;
    } catch (_) {
      // File not present yet — silent fallback
    }
  }

  Future<void> _loadSqueeze() async {
    try {
      await _squeezePlayer.setSource(
          AssetSource('sounds/stress_ball_squeeze.mp3'));
      await _squeezePlayer.setVolume(0.75);
      _squeezeReady = true;
    } catch (_) {}
  }

  Future<void> _loadRelease() async {
    try {
      await _releasePlayer.setSource(
          AssetSource('sounds/stress_ball_release.mp3'));
      await _releasePlayer.setVolume(0.75);
      _releaseReady = true;
    } catch (_) {}
  }

  void playBubblePop() {
    if (!_popsReady) return;
    try {
      final p = _popPlayers[_popIdx % _popPlayers.length];
      _popIdx++;
      p.seek(Duration.zero);
      p.resume();
    } catch (_) {}
  }

  void playStressBallSqueeze() {
    if (!_squeezeReady) return;
    try {
      _squeezePlayer.seek(Duration.zero);
      _squeezePlayer.resume();
    } catch (_) {}
  }

  void playStressBallRelease() {
    if (!_releaseReady) return;
    try {
      _releasePlayer.seek(Duration.zero);
      _releasePlayer.resume();
    } catch (_) {}
  }

  void dispose() {
    for (final p in _popPlayers) p.dispose();
    _squeezePlayer.dispose();
    _releasePlayer.dispose();
  }
}
