import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/playlist_controller.dart';
import '../controllers/settings_controller.dart';

import '../models/playlist_model.dart';
import '../widgets/song_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                context.push('/library-search');
              },
            ),
            Consumer<AudioPlayerController>(
              builder: (context, audio, child) => PopupMenuButton<AppSortType>(
                icon: const Icon(Icons.sort),
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
              icon: const Icon(Icons.settings),
              onPressed: () {
                context.push('/settings');
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Songs'),
              Tab(text: 'Playlists'),
              Tab(text: 'Favorites'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [const _SongsTab(), _PlaylistsTab(), _FavoritesTab()],
              ),
            ),
            // Mini Player or persistent bar
            _MiniPlayer(),
          ],
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
  bool _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsController, AudioPlayerController>(
      builder: (context, settings, audio, child) {
        if (!_hasScanned && !audio.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (settings.folders.isNotEmpty) {
              await audio.scanSongs(settings.folders);
            }
            if (mounted) {
              setState(() {
                _hasScanned = true;
              });
            }
          });
        }

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
                leading: const Icon(Icons.add),
                title: const Text('Create New Playlist'),
                onTap: () => _showCreatePlaylistDialog(context),
              );
            }
            final pl = playlistCtrl.playlists[index - 1];
            return ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(pl.name),
              subtitle: Text('${pl.songIds.length} songs'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
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
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: theme.iconTheme.color?.withValues(alpha: 0.5),
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    audio.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: audio.isPlaying ? audio.pause : audio.resume,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
