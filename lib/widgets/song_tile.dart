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
    return ListTile(
      leading: const Icon(Icons.music_note),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'fav') {
            context.read<PlaylistController>().toggleFavorite(song.id);
          } else if (value == 'playlist') {
            // Show playlist dialog
            _showAddToPlaylistDialog(context, song.id);
          }
        },
        itemBuilder: (context) {
          final isFav = context.read<PlaylistController>().isFavorite(song.id);
          return [
            PopupMenuItem(
              value: 'fav',
              child: Text(isFav ? 'Unfavorite' : 'Favorite'),
            ),
            const PopupMenuItem(
              value: 'playlist',
              child: Text('Add to Playlist'),
            ),
          ];
        },
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, String songId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add to Playlist'),
          content: Consumer<PlaylistController>(
            builder: (context, playlistCtrl, child) {
              if (playlistCtrl.playlists.isEmpty) {
                return const Text('No playlists. Create one in Library.');
              }
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlistCtrl.playlists.length,
                  itemBuilder: (context, index) {
                    final pl = playlistCtrl.playlists[index];
                    return ListTile(
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
              );
            },
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
  }
}
