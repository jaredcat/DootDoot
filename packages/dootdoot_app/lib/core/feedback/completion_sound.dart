import 'package:audioplayers/audioplayers.dart';

/// Short click played when the user marks a task or habit done.
void playCompletionSound() {
  CompletionSound.instance.play();
}

class CompletionSound {
  CompletionSound._();

  static final CompletionSound instance = CompletionSound._();

  static const _asset = 'sounds/doot_click_warm.mp3';

  final AudioContext _context = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  AudioPlayer? _player;
  Future<void>? _chain;

  void play() {
    final next = (_chain ?? Future<void>.value()).then((_) => _play());
    _chain = next;
  }

  Future<void> _play() async {
    try {
      final player = _player ??= await _createPlayer();
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {
      final player = _player;
      _player = null;
      if (player != null) {
        await player.dispose();
      }
    }
  }

  Future<AudioPlayer> _createPlayer() async {
    final player = AudioPlayer()
      ..audioCache = AudioCache(prefix: 'packages/dootdoot_app/assets/');
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setAudioContext(_context);
    await player.setSource(AssetSource(_asset));
    return player;
  }
}
