import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:spotube/provider/playlist_queue_provider.dart';
import 'package:spotube/services/audio_player.dart';

class MobileAudioService extends BaseAudioHandler {
  AudioSession? session;
  final PlaylistQueueNotifier playlistNotifier;
  final VolumeProvider volumeNotifier;

  PlaylistQueue? get playlist => playlistNotifier.state;

  MobileAudioService(this.playlistNotifier, this.volumeNotifier) {
    AudioSession.instance.then((s) {
      session = s;
      session?.configure(const AudioSessionConfiguration.music());
      s.interruptionEventStream.listen((event) async {
        switch (event.type) {
          case AudioInterruptionType.duck:
            await volumeNotifier.setVolume(event.begin ? 0.5 : 1.0);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            await playlistNotifier.pause();
            break;
        }
      });
    });
    audioPlayer.onPlayerStateChanged.listen((state) async {
      playbackState.add(await _transformEvent());
    });

    audioPlayer.onPositionChanged.listen((pos) async {
      playbackState.add(await _transformEvent());
    });
  }

  void addItem(MediaItem item) {
    session?.setActive(true);
    mediaItem.add(item);
  }

  @override
  Future<void> play() => playlistNotifier.resume();

  @override
  Future<void> pause() => playlistNotifier.pause();

  @override
  Future<void> seek(Duration position) => playlistNotifier.seek(position);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await super.setShuffleMode(shuffleMode);

    if (shuffleMode == AudioServiceShuffleMode.all) {
      playlistNotifier.shuffle();
    } else {
      playlistNotifier.unshuffle();
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    super.setRepeatMode(repeatMode);
    if (repeatMode == AudioServiceRepeatMode.all) {
      playlistNotifier.loop();
    } else {
      playlistNotifier.unloop();
    }
  }

  @override
  Future<void> stop() async {
    await playlistNotifier.stop();
  }

  @override
  Future<void> skipToNext() async {
    await playlistNotifier.next();
    await super.skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await playlistNotifier.previous();
    await super.skipToPrevious();
  }

  @override
  Future<void> onTaskRemoved() async {
    await playlistNotifier.stop();
    await audioPlayer.release();
    return super.onTaskRemoved();
  }

  Future<PlaybackState> _transformEvent() async {
    final position = (await audioPlayer.getCurrentPosition()) ?? Duration.zero;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        audioPlayer.state == PlayerState.playing
            ? MediaControl.pause
            : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: {
        MediaAction.seek,
      },
      androidCompactActionIndices: const [0, 1, 2],
      playing: audioPlayer.state == PlayerState.playing,
      updatePosition: position,
      bufferedPosition: position,
      shuffleMode: playlist?.isShuffled == true
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      repeatMode: playlist?.isLooping == true
          ? AudioServiceRepeatMode.one
          : AudioServiceRepeatMode.all,
      processingState: playlist?.isLoading == true
          ? AudioProcessingState.loading
          : AudioProcessingState.ready,
    );
  }
}
