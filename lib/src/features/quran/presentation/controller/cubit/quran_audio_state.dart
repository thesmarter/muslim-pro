part of 'quran_audio_cubit.dart';

abstract class QuranAudioState extends Equatable {
  const QuranAudioState();

  @override
  List<Object?> get props => [];
}

class QuranAudioInitial extends QuranAudioState {}

class QuranAudioLoading extends QuranAudioState {}

class QuranAudioError extends QuranAudioState {
  final String message;

  const QuranAudioError(this.message);

  @override
  List<Object> get props => [message];
}

class QuranAudioPlaying extends QuranAudioState {
  final Surah surah;
  final Reciter reciter;
  final int currentAyahIndex;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final double volume;

  const QuranAudioPlaying({
    required this.surah,
    required this.reciter,
    required this.currentAyahIndex,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.playbackSpeed = 1.0,
    this.volume = 1.0,
  });

  QuranAudioPlaying copyWith({
    Surah? surah,
    Reciter? reciter,
    int? currentAyahIndex,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    double? volume,
  }) {
    return QuranAudioPlaying(
      surah: surah ?? this.surah,
      reciter: reciter ?? this.reciter,
      currentAyahIndex: currentAyahIndex ?? this.currentAyahIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      volume: volume ?? this.volume,
    );
  }

  @override
  List<Object> get props => [
        surah,
        reciter,
        currentAyahIndex,
        isPlaying,
        position,
        duration,
        playbackSpeed,
        volume,
      ];
}

class QuranAudioPaused extends QuranAudioState {
  final Surah surah;
  final Reciter reciter;
  final int currentAyahIndex;
  final Duration position;
  final Duration duration;

  const QuranAudioPaused({
    required this.surah,
    required this.reciter,
    required this.currentAyahIndex,
    required this.position,
    required this.duration,
  });

  @override
  List<Object> get props => [
        surah,
        reciter,
        currentAyahIndex,
        position,
        duration,
      ];
}

class QuranAudioStopped extends QuranAudioState {}

class QuranAudioBuffering extends QuranAudioState {
  final Surah surah;
  final Reciter reciter;

  const QuranAudioBuffering({
    required this.surah,
    required this.reciter,
  });

  @override
  List<Object> get props => [surah, reciter];
}
