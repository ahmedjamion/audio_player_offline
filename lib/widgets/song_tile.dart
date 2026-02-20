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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFFE8E5E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: isDark ? Colors.white38 : Colors.black26,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  onSelected: (value) {
                    if (value == 'fav') {
                      context.read<PlaylistController>().toggleFavorite(song.id);
                    } else if (value == 'playlist') {
                      _showAddToPlaylistDialog(context, song.id);
                    }
                  },
                  itemBuilder: (context) {
                    final isFav =
                        context.read<PlaylistController>().isFavorite(song.id);
                    return [
                      PopupMenuItem(
                        value: 'fav',
                        child: Row(
                          children: [
                            Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: isFav
                                  ? (isDark
                                      ? const Color(0xFFD4A5A5)
                                      : const Color(0xFFC4918A))
                                  : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, String songId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'Add to Playlist',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Consumer<PlaylistController>(
            builder: (context, playlistCtrl, child) {
              if (playlistCtrl.playlists.isEmpty) {
                return Text(
                  'No playlists. Create one in Library.',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                );
              }
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlistCtrl.playlists.length,
                  itemBuilder: (context, index) {
                    final pl = playlistCtrl.playlists[index];
                    return ListTile(
                      leading: Icon(
                        Icons.queue_music,
                        color: isDark
                            ? const Color(0xFF7CB9A8)
                            : const Color(0xFF5A9E85),
                      ),
                      title: Text(
                        pl.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      onTap: () {
                        playlistCtrl.addSongToPlaylist(pl, songId);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added to ${pl.name}'),
                            backgroundColor:
                                isDark ? const Color(0xFF2A2A2A) : null,
                          ),
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
