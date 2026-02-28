import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/playlist_controller.dart';
import '../theme/app_colors.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: isDark ? Colors.transparent : AppColors.lightBackground,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        actions: [
          Consumer<AudioPlayerController>(
            builder: (context, audio, child) {
              final song = audio.currentSong;
              if (song == null) return const SizedBox.shrink();
                return Consumer<PlaylistController>(
                  builder: (context, playlist, child) {
                    final isFav = playlist.isFavorite(song.id);
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 24,
                      ),
                      color: isFav
                          ? (isDark ? AppColors.darkSecondary : AppColors.lightSecondary)
                          : theme.iconTheme.color?.withValues(alpha: 0.4),
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
            return Center(
              child: Text(
                'No song playing',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            );
          }
          return SafeArea(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < 0) {
                    audio.next();
                  } else if (details.primaryVelocity! > 0) {
                    audio.previous();
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.dividerLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          LucideIcons.music,
                          size: 80,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => _showDetailsDialog(context, song, audio),
                      child: Text(
                        song.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showDetailsDialog(context, song, audio),
                      child: Text(
                        song.artist,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SliderTheme(
                      data: theme.sliderTheme.copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
                          Text(_formatDuration(audio.position), style: theme.textTheme.bodySmall),
                          Text(_formatDuration(audio.duration), style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            LucideIcons.shuffle,
                            color: audio.isShuffle
                                ? theme.colorScheme.primary
                                : theme.iconTheme.color?.withValues(alpha: 0.5),
                          ),
                          iconSize: 24,
                          onPressed: audio.toggleShuffle,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.skipBack),
                          iconSize: 36,
                          onPressed: audio.previous,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            audio.isPlaying ? LucideIcons.pauseCircle : LucideIcons.playCircle,
                          ),
                          iconSize: 56,
                          color: theme.colorScheme.primary,
                          onPressed: audio.isPlaying ? audio.pause : audio.resume,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(LucideIcons.skipForward),
                          iconSize: 36,
                          onPressed: audio.next,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(_getRepeatIcon(audio.loopMode)),
                          iconSize: 24,
                          color: audio.loopMode != LoopMode.off
                              ? theme.colorScheme.primary
                              : theme.iconTheme.color?.withValues(alpha: 0.5),
                          onPressed: audio.toggleLoop,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getRepeatIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return LucideIcons.repeat;
      case LoopMode.all:
        return LucideIcons.repeat;
      case LoopMode.one:
        return LucideIcons.repeat1;
    }
  }

  void _showDetailsDialog(BuildContext context, dynamic song, AudioPlayerController audio) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Now Playing',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              song.artist,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              song.album,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _DetailRow(label: 'Duration', value: _formatDuration(audio.duration)),
            _DetailRow(label: 'Path', value: song.path),
          ],
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
