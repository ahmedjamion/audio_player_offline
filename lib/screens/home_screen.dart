import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/playlist_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/playlist_model.dart';
import '../widgets/song_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () {
              context.push('/library-search');
            },
          ),
          Consumer<AudioPlayerController>(
            builder: (context, audio, child) => PopupMenuButton<AppSortType>(
              icon: const Icon(LucideIcons.slidersHorizontal),
              onSelected: (value) {
                audio.setSortType(value);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: AppSortType.title,
                  child: Text('Title'),
                ),
                const PopupMenuItem(
                  value: AppSortType.artist,
                  child: Text('Artist'),
                ),
                const PopupMenuItem(
                  value: AppSortType.duration,
                  child: Text('Duration'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _CustomTabBar(
            selectedIndex: _selectedIndex,
            onTabSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [const _SongsTab(), _PlaylistsTab(), _FavoritesTab()],
            ),
          ),
          _MiniPlayer(),
        ],
      ),
    );
  }
}

class _CustomTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _CustomTabBar({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Songs',
            icon: LucideIcons.music,
            isSelected: selectedIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          _TabButton(
            label: 'Playlists',
            icon: LucideIcons.listMusic,
            isSelected: selectedIndex == 1,
            onTap: () => onTabSelected(1),
          ),
          _TabButton(
            label: 'Favorites',
            icon: LucideIcons.heart,
            isSelected: selectedIndex == 2,
            onTap: () => onTabSelected(2),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : theme.colorScheme.primary.withValues(alpha: 0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected && isDark
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongsTab extends StatefulWidget {
  const _SongsTab();

  @override
  State<_SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<_SongsTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsController, AudioPlayerController>(
      builder: (context, settings, audio, child) {

        if (audio.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (audio.songs.isEmpty) {
          String message = 'No songs found.';
          final issue = audio.scanIssue;
          if (issue is ScanIssuePermissionDenied) {
            message = 'Permission denied. Please allow media access in Settings.';
          } else if (issue is ScanIssueNoFolders) {
            message = 'No folders selected. Add folders in Settings.';
          } else if (issue is ScanIssueError) {
            message = audio.scanErrorMessage ?? 'Scan failed. Try again.';
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                const Text('Go to Settings to add folders.'),
                ElevatedButton(
                  onPressed: () {
                    context.push('/settings');
                  },
                  child: const Text('Manage Folders'),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await audio.scanSongs(settings.folders);
          },
          child: ListView.builder(
            itemCount: audio.songs.length,
            itemBuilder: (context, index) {
              final song = audio.songs[index];
              return SongTile(
                song: song,
                onTap: () async {
                  await audio.playSong(song);
                  if (context.mounted) {
                    context.push('/player');
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistController>(
      builder: (context, playlistCtrl, child) {
        if (playlistCtrl.playlists.isEmpty) {
          return Center(
            child: ElevatedButton(
              onPressed: () => _showCreatePlaylistDialog(context),
              child: const Text('Create Playlist'),
            ),
          );
        }
        return ListView.builder(
          itemCount:
              playlistCtrl.playlists.length + 1, // +1 for "Create" button
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                leading: const Icon(LucideIcons.plus),
                title: const Text('Create New Playlist'),
                onTap: () => _showCreatePlaylistDialog(context),
              );
            }
            final pl = playlistCtrl.playlists[index - 1];
            return ListTile(
              leading: const Icon(LucideIcons.listMusic),
              title: Text(pl.name),
              subtitle: Text('${pl.songIds.length} songs'),
              trailing: IconButton(
                icon: const Icon(LucideIcons.trash2),
                onPressed: () => playlistCtrl.deletePlaylist(pl),
              ),
              onTap: () {
                // Show playlist details...
                // For now, simpler implementation:
                _showPlaylistDetails(context, pl);
              },
            );
          },
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<PlaylistController>().createPlaylist(
                  controller.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistDetails(BuildContext context, Playlist pl) {
    context.push('/playlist/${pl.key}');
  }
}

class _FavoritesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<PlaylistController, AudioPlayerController>(
      builder: (context, plCtrl, audioCtrl, child) {
        final favIds = plCtrl.favoriteIds;
        if (favIds.isEmpty) {
          return const Center(child: Text('No Favorites yet'));
        }
        final favSongs = audioCtrl.songs
            .where((s) => favIds.contains(s.id))
            .toList();

        return ListView.builder(
          itemCount: favSongs.length,
          itemBuilder: (context, index) {
            final song = favSongs[index];
            return SongTile(
              song: song,
              onTap: () {
                audioCtrl.playSong(song);
                context.push('/player');
              },
            );
          },
        );
      },
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<AudioPlayerController>(
      builder: (context, audio, child) {
        final song = audio.currentSong;
        if (song == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            context.push('/player');
          },
          child: Container(
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? theme.colorScheme.surface.withValues(alpha: 0.9)
                  : theme.colorScheme.surface,
              border: Border.all(
                color: isDark
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                              theme.colorScheme.secondary.withValues(alpha: 0.2),
                            ]
                          : [
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                              theme.colorScheme.primary.withValues(alpha: 0.05),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.music,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      audio.isPlaying ? LucideIcons.pause : LucideIcons.play,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: audio.isPlaying ? audio.pause : audio.resume,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
