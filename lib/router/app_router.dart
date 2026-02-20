import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/audio_player_controller.dart';
import '../controllers/playlist_controller.dart';
import '../models/playlist_model.dart';
import '../screens/home_screen.dart';
import '../screens/player_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/library_search_screen.dart';
import '../widgets/song_tile.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'player',
          builder: (context, state) => const PlayerScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'library-search',
          builder: (context, state) => const LibrarySearchScreen(),
        ),
        GoRoute(
          path: 'playlist/:id',
          builder: (context, state) {
            final playlistId = state.pathParameters['id']!;
            return _PlaylistDetailsScreen(playlistId: playlistId);
          },
        ),
      ],
    ),
  ],
);

class _PlaylistDetailsScreen extends StatelessWidget {
  final String playlistId;

  const _PlaylistDetailsScreen({required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist'),
      ),
      body: Consumer2<PlaylistController, AudioPlayerController>(
        builder: (context, plCtrl, audioCtrl, child) {
          final playlist = plCtrl.playlists.cast<Playlist?>().firstWhere(
            (p) => p?.key.toString() == playlistId,
            orElse: () => null,
          );

          if (playlist == null) {
            return const Center(child: Text('Playlist not found'));
          }

          final songs = audioCtrl.songs
              .where((s) => playlist.songIds.contains(s.id))
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
                  audioCtrl.playSongs(songs, index);
                  context.push('/player');
                },
              );
            },
          );
        },
      ),
    );
  }
}
