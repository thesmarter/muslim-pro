import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:muslim/src/features/quran/data/models/reciter_model.dart';
import 'package:muslim/src/features/quran/data/models/surah_model.dart';
import 'package:muslim/src/features/quran/data/repository/quran_repository.dart';

part 'quran_audio_state.dart';

class QuranAudioCubit extends Cubit<QuranAudioState> {
  final QuranRepository _repository;
  final AudioPlayer _audioPlayer;

  Reciter? _currentReciter;
  Surah? _currentSurah;
  int _currentAyahIndex = 0;

  QuranAudioCubit(this._repository)
      : _audioPlayer = AudioPlayer(),
        super(QuranAudioInitial()) {
    _initializeAudioPlayer();
  }

  void _initializeAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((playerState) {
      if (playerState == PlayerState.completed) {
        _onAudioCompleted();
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (state is QuranAudioPlaying) {
        final currentState = state as QuranAudioPlaying;
        emit(currentState.copyWith(position: position));
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      if (state is QuranAudioPlaying) {
        final currentState = state as QuranAudioPlaying;
        emit(currentState.copyWith(duration: duration));
      }
    });
  }

  // Load and play surah
  Future<void> playSurah(
    Surah surah,
    Reciter reciter, {
    int startFromAyah = 0,
  }) async {
    try {
      emit(QuranAudioLoading());

      _currentSurah = surah;
      _currentReciter = reciter;
      _currentAyahIndex = startFromAyah;

      final audioUrl = _repository.getAudioUrl(surah.number, reciter);

      await _audioPlayer.setSourceUrl(audioUrl);
      await _audioPlayer.resume();

      emit(QuranAudioPlaying(
        surah: surah,
        reciter: reciter,
        currentAyahIndex: _currentAyahIndex,
        isPlaying: true,
        position: Duration.zero,
        duration: Duration.zero,
      ));
    } catch (e) {
      emit(QuranAudioError(e.toString()));
    }
  }

  // Play/Pause toggle
  Future<void> togglePlayPause() async {
    try {
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.pause();
        if (state is QuranAudioPlaying) {
          final currentState = state as QuranAudioPlaying;
          emit(currentState.copyWith(isPlaying: false));
        }
      } else {
        await _audioPlayer.resume();
        if (state is QuranAudioPlaying) {
          final currentState = state as QuranAudioPlaying;
          emit(currentState.copyWith(isPlaying: true));
        }
      }
    } catch (e) {
      emit(QuranAudioError(e.toString()));
    }
  }

  // Stop audio
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      emit(QuranAudioStopped());
    } catch (e) {
      emit(QuranAudioError(e.toString()));
    }
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      emit(QuranAudioError(e.toString()));
    }
  }

  // Next surah
  Future<void> nextSurah() async {
    if (_currentSurah != null && _currentReciter != null) {
      if (_currentSurah!.number < 114) {
        try {
          final nextSurah =
              await _repository.getSurah(_currentSurah!.number + 1);
          await playSurah(nextSurah, _currentReciter!);
        } catch (e) {
          emit(QuranAudioError(e.toString()));
        }
      }
    }
  }

  // Previous surah
  Future<void> previousSurah() async {
    if (_currentSurah != null && _currentReciter != null) {
      if (_currentSurah!.number > 1) {
        try {
          final previousSurah =
              await _repository.getSurah(_currentSurah!.number - 1);
          await playSurah(previousSurah, _currentReciter!);
        } catch (e) {
          emit(QuranAudioError(e.toString()));
        }
      }
    }
  }

  // Set playback speed
  Future<void> setSpeed(double speed) async {
    try {
      await _audioPlayer.setPlaybackRate(speed);
      if (state is QuranAudioPlaying) {
        final currentState = state as QuranAudioPlaying;
        emit(currentState.copyWith(playbackSpeed: speed));
      }
    } catch (e) {
      emit(QuranAudioError(e.toString()));
    }
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
      if (state is QuranAudioPlaying) {
        final currentState = state as QuranAudioPlaying;
        emit(currentState.copyWith(volume: volume));
      }
    } catch (e) {
      emit(QuranAudioError(e.toString()));
    }
  }

  // Change reciter
  Future<void> changeReciter(Reciter reciter) async {
    if (_currentSurah != null) {
      // Get current position if available
      const Duration currentPosition = Duration.zero;
      await playSurah(_currentSurah!, reciter);
      await seek(currentPosition);
    }
  }

  void _onAudioCompleted() {
    // Auto play next surah if enabled
    // This can be made configurable
    nextSurah();
  }

  // Get current playing info
  QuranAudioPlaying? get currentlyPlaying {
    if (state is QuranAudioPlaying) {
      return state as QuranAudioPlaying;
    }
    return null;
  }

  // Check if audio is playing
  bool get isPlaying => _audioPlayer.state == PlayerState.playing;

  // Get current position
  Duration get currentPosition => Duration.zero; // Will be updated via streams

  // Get duration
  Duration? get duration => null; // Will be updated via streams

  @override
  Future<void> close() async {
    await _audioPlayer.dispose();
    return super.close();
  }
}
