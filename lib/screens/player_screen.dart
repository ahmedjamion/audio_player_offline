import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/playlist_controller.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    color: isFav
                        ? (isDark ? const Color(0xFFD4A5A5) : const Color(0xFFC4918A))
                        : (isDark ? Colors.white54 : Colors.black54),
                    onPressed: () => playlist.toggleFavorite(song.id),
                  );
                },
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF2D3A3A),
                    const Color(0xFF1A1A1A),
                  ]
                : [
                    const Color(0xFFE8E0D8),
                    const Color(0xFFF5F2EB),
                  ],
          ),
        ),
        child: Consumer<AudioPlayerController>(
          builder: (context, audio, child) {
            final song = audio.currentSong;
            if (song == null) {
              return Center(
                child: Text(
                  'No song playing',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  // Artwork Placeholder
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFE0DCD4),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark
                                    ? const Color(0xFF7CB9A8)
                                    : const Color(0xFF5A9E85))
                                .withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.music_note,
                        size: 100,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                  // Title & Artist
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.artist,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 32),
                  // Progress Bar
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: Slider(
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
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(audio.position),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                        ),
                        Text(
                          _formatDuration(audio.duration),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: audio.isShuffle
                              ? (isDark
                                  ? const Color(0xFF7CB9A8)
                                  : const Color(0xFF5A9E85))
                              : (isDark ? Colors.white54 : Colors.black45),
                        ),
                        onPressed: audio.toggleShuffle,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous,
                          size: 40,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onPressed: audio.previous,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                      ? const Color(0xFF7CB9A8)
                                      : const Color(0xFF5A9E85))
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            audio.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 72,
                            color: isDark
                                ? const Color(0xFF7CB9A8)
                                : const Color(0xFF5A9E85),
                          ),
                          onPressed:
                              audio.isPlaying ? audio.pause : audio.resume,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_next,
                          size: 40,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onPressed: audio.next,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.repeat,
                          color: audio.loopMode != LoopMode.off
                              ? (isDark
                                  ? const Color(0xFF7CB9A8)
                                  : const Color(0xFF5A9E85))
                              : (isDark ? Colors.white54 : Colors.black45),
                        ),
                        onPressed: audio.toggleLoop,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
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
