import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/playlist_controller.dart';

import '../models/playlist_model.dart';
import 'player_screen.dart';
import 'settings_screen.dart';
import 'library_search_screen.dart';
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LibrarySearchScreen(),
                  ),
                );
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
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
                children: [_SongsTab(), _PlaylistsTab(), _FavoritesTab()],
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

class _SongsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerController>(
      builder: (context, audio, child) {
        if (audio.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (audio.songs.isEmpty) {
          String message = 'No songs found.';
          if (audio.scanIssue == ScanIssue.permissionDenied) {
            message = 'Permission denied. Please allow media access in Settings.';
          } else if (audio.scanIssue == ScanIssue.noFolders) {
            message = 'No folders selected. Add folders in Settings.';
          } else if (audio.scanIssue == ScanIssue.error) {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  child: const Text('Manage Folders'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: audio.songs.length,
          itemBuilder: (context, index) {
            final song = audio.songs[index];
            return SongTile(
              song: song,
              onTap: () {
                audio.playSong(song);
                // Navigate to player? Or explicit open?
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerScreen()),
                );
              },
            );
          },
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: Text(pl.name)),
            body: Consumer2<PlaylistController, AudioPlayerController>(
              builder: (context, plCtrl, audioCtrl, child) {
                // Resolve songs
                // This is inefficient O(N*M) but fine for offline library size
                final songs = audioCtrl.songs
                    .where((s) => pl.songIds.contains(s.id))
                    .toList();
                if (songs.isEmpty) {
                  return const Center(child: Text('Empty Playlist'));
                }

                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return SongTile(
                      song: song,
                      onTap: () {
                        audioCtrl.playSong(song);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PlayerScreen(),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerScreen()),
                );
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
    return Consumer<AudioPlayerController>(
      builder: (context, audio, child) {
        final song = audio.currentSong;
        if (song == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayerScreen()),
            );
          },
          child: Container(
            color: Theme.of(context).primaryColorDark, // or bottomSheetTheme
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.music_note),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    audio.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
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
