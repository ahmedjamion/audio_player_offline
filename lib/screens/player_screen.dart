import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/playlist_controller.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          Consumer<AudioPlayerController>(
            builder: (context, audio, child) {
              final song = audio.currentSong;
              if (song == null) return const SizedBox.shrink();
              return Consumer<PlaylistController>(
                builder: (context, playlist, child) {
                  final isFav = playlist.isFavorite(song.id);
                  return IconButton(
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                    color: isFav ? Colors.red : null,
                    onPressed: () => playlist.toggleFavorite(song.id),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<AudioPlayerController>(
        builder: (context, audio, child) {
          final song = audio.currentSong;
          if (song == null) {
            return const Center(child: Text('No song playing'));
          }
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Artwork Placeholder
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 100,
                      color: Colors.white54,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Title & Artist
                Text(
                  song.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  song.artist,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 30),
                // Progress Bar
                Slider(
                  value: audio.position.inMilliseconds.toDouble().clamp(
                    0,
                    audio.duration.inMilliseconds.toDouble(),
                  ),
                  min: 0,
                  max: audio.duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    audio.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(audio.position)),
                      Text(_formatDuration(audio.duration)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: audio.isShuffle
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: audio.toggleShuffle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 36),
                      onPressed: () {
                        // Previous logic (needs queue, for now just restart or do nothing)
                        audio.seek(Duration.zero);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        audio.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: audio.isPlaying ? audio.pause : audio.resume,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 36),
                      onPressed: () {
                        // Next logic
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.loop,
                        color: audio.loopMode != LoopMode.off
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: audio.toggleLoop,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }
    return '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}
