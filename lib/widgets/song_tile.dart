import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../controllers/playlist_controller.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const SongTile({super.key, required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.music_note,
          color: theme.iconTheme.color?.withValues(alpha: 0.5),
          size: 22,
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: theme.iconTheme.color?.withValues(alpha: 0.5),
        ),
        onSelected: (value) {
          if (value == 'fav') {
            context.read<PlaylistController>().toggleFavorite(song.id);
          } else if (value == 'playlist') {
            _showAddToPlaylistDialog(context, song.id);
          }
        },
        itemBuilder: (context) {
          final isFav = context.read<PlaylistController>().isFavorite(song.id);
          return [
            PopupMenuItem(
              value: 'fav',
              child: Row(
                children: [
                  Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isFav ? theme.colorScheme.secondary : null,
                  ),
                  const SizedBox(width: 8),
                  Text(isFav ? 'Unfavorite' : 'Favorite'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'playlist',
              child: Row(
                children: [
                  Icon(Icons.playlist_add, size: 20),
                  SizedBox(width: 8),
                  Text('Add to Playlist'),
                ],
              ),
            ),
          ];
        },
      ),
      onTap: onTap,
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, String songId) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<PlaylistController>(
          builder: (context, playlistCtrl, child) {
            if (playlistCtrl.playlists.isEmpty) {
              return AlertDialog(
                title: const Text('Add to Playlist'),
                content: const Text('No playlists. Create one in Library.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            }
            return AlertDialog(
              title: const Text('Add to Playlist'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlistCtrl.playlists.length,
                  itemBuilder: (context, index) {
                    final pl = playlistCtrl.playlists[index];
                    return ListTile(
                      leading: Icon(
                        Icons.queue_music,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(pl.name),
                      onTap: () {
                        playlistCtrl.addSongToPlaylist(pl, songId);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${pl.name}')),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
