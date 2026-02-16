import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/playlist_model.dart';

class PlaylistController extends ChangeNotifier {
  Box<Playlist>? _playlistBox;
  Box<String>? _favoritesBox;

  List<Playlist> get playlists => _playlistBox?.values.toList() ?? [];
  List<String> get favoriteIds => _favoritesBox?.keys.cast<String>().toList() ?? [];

  bool get isReady => _playlistBox != null && _favoritesBox != null;

  Future<void> init() async {
    _playlistBox = await Hive.openBox<Playlist>('playlists');
    _favoritesBox = await Hive.openBox<String>('favorites');
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    if (!isReady) return;
    final playlist = Playlist(name: name, songIds: []);
    await _playlistBox!.add(playlist);
    notifyListeners();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    if (!isReady) return;
    await playlist.delete();
    notifyListeners();
  }

  Future<void> addSongToPlaylist(Playlist playlist, String songId) async {
    if (!isReady) return;
    if (!playlist.songIds.contains(songId)) {
      playlist.songIds.add(songId);
      await playlist.save();
      notifyListeners();
    }
  }

  Future<void> removeSongFromPlaylist(Playlist playlist, String songId) async {
    if (!isReady) return;
    playlist.songIds.remove(songId);
    await playlist.save();
    notifyListeners();
  }

  Future<void> toggleFavorite(String songId) async {
    if (!isReady) return;
    if (_favoritesBox!.containsKey(songId)) {
      await _favoritesBox!.delete(songId);
    } else {
      await _favoritesBox!.put(songId, songId);
    }
    notifyListeners();
  }

  bool isFavorite(String songId) {
    return _favoritesBox?.containsKey(songId) ?? false;
  }
}
