import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/audio_player_controller.dart';
import '../models/song_model.dart';
import '../widgets/song_tile.dart';

class LibrarySearchScreen extends StatefulWidget {
  const LibrarySearchScreen({super.key});

  @override
  State<LibrarySearchScreen> createState() => _LibrarySearchScreenState();
}

class _LibrarySearchScreenState extends State<LibrarySearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Song> _filteredSongs = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSongs = [];
      });
      return;
    }
    final allSongs = context.read<AudioPlayerController>().songs;
    setState(() {
      _filteredSongs = allSongs.where((s) {
        return s.title.toLowerCase().contains(query.toLowerCase()) ||
            s.artist.toLowerCase().contains(query.toLowerCase()) ||
            s.album.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search songs, artists...',
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            _search(value);
            setState(() {});
          },
        ),
      ),
      body: _filteredSongs.isEmpty
          ? Center(
              child: Text(
                _controller.text.isEmpty ? 'Type to search' : 'No results',
                style: theme.textTheme.bodyMedium,
              ),
            )
          : ListView.builder(
              itemCount: _filteredSongs.length,
              itemBuilder: (context, index) {
                final song = _filteredSongs[index];
                return SongTile(
                  song: song,
                  onTap: () {
                    context.read<AudioPlayerController>().playSong(song);
                    context.push('/player');
                  },
                );
              },
            ),
    );
  }
}
