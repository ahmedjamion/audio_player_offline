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
  void initState() {
    super.initState();
    // Initialize with all songs? Or empty? Better empty.
    // _filteredSongs = context.read<AudioPlayerController>().songs; 
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
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search songs, artists...',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: _filteredSongs.isEmpty 
          ? const Center(child: Text('Type to search')) 
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
