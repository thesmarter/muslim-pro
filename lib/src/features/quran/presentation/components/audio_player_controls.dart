import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim/src/features/quran/presentation/controller/cubit/quran_audio_cubit.dart';

class AudioPlayerControls extends StatelessWidget {
  const AudioPlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Main Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous Surah
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.skip_previous),
                iconSize: 32,
              ),

              // Seek Backward
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.replay_10),
                iconSize: 28,
              ),

              // Play/Pause
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('اختر سورة للتشغيل')),
                    );
                  },
                  icon: Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  iconSize: 40,
                ),
              ),

              // Seek Forward
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.forward_10),
                iconSize: 28,
              ),

              // Next Surah
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.skip_next),
                iconSize: 32,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Secondary Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speed Control
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.speed),
                tooltip: 'سرعة التشغيل',
              ),

              // Volume Control
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.volume_up),
                tooltip: 'مستوى الصوت',
              ),

              // Stop
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.stop),
                tooltip: 'إيقاف',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, QuranAudioPlaying state) {
    final progress = state.duration.inMilliseconds > 0
        ? state.position.inMilliseconds / state.duration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final newPosition = Duration(
                milliseconds: (value * state.duration.inMilliseconds).round(),
              );
              context.read<QuranAudioCubit>().seek(newPosition);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(state.position),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _formatDuration(state.duration),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedControl(BuildContext context, QuranAudioPlaying state) {
    return PopupMenuButton<double>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speed, size: 20),
          const SizedBox(width: 4),
          Text(
            '${state.playbackSpeed}x',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0.5, child: Text('0.5x')),
        const PopupMenuItem(value: 0.75, child: Text('0.75x')),
        const PopupMenuItem(value: 1.0, child: Text('1.0x')),
        const PopupMenuItem(value: 1.25, child: Text('1.25x')),
        const PopupMenuItem(value: 1.5, child: Text('1.5x')),
        const PopupMenuItem(value: 2.0, child: Text('2.0x')),
      ],
      onSelected: (speed) {
        context.read<QuranAudioCubit>().setSpeed(speed);
      },
    );
  }

  Widget _buildVolumeControl(BuildContext context, QuranAudioPlaying state) {
    return PopupMenuButton<void>(
      icon: Icon(
        state.volume > 0.5
            ? Icons.volume_up
            : state.volume > 0
                ? Icons.volume_down
                : Icons.volume_off,
        size: 20,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 200,
            child: Column(
              children: [
                Text('Volume: ${(state.volume * 100).round()}%'),
                Slider(
                  value: state.volume,
                  onChanged: (volume) {
                    context.read<QuranAudioCubit>().setVolume(volume);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _seekBackward(BuildContext context, QuranAudioPlaying state) {
    final newPosition = state.position - const Duration(seconds: 10);
    context.read<QuranAudioCubit>().seek(
          newPosition.isNegative ? Duration.zero : newPosition,
        );
  }

  void _seekForward(BuildContext context, QuranAudioPlaying state) {
    final newPosition = state.position + const Duration(seconds: 10);
    context.read<QuranAudioCubit>().seek(
          newPosition > state.duration ? state.duration : newPosition,
        );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
