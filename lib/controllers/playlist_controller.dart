import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/playlist_model.dart';

/// Controller for managing playlists and favorites.
///
/// Handles creating, deleting, and modifying playlists,
/// as well as managing favorite songs.
class PlaylistController extends ChangeNotifier {
  Box<Playlist>? _playlistBox;
  Box<String>? _favoritesBox;

  /// The list of all playlists.
  List<Playlist> get playlists => _playlistBox?.values.toList() ?? [];

  /// The list of favorite song IDs.
  List<String> get favoriteIds =>
      _favoritesBox?.keys.cast<String>().toList() ?? [];

  /// Whether the controller has been initialized.
  bool get isReady => _playlistBox != null && _favoritesBox != null;

  /// Initializes the controller by opening Hive boxes.
  ///
  /// Must be called before using other methods.
  Future<void> init() async {
    _playlistBox = await Hive.openBox<Playlist>('playlists');
    _favoritesBox = await Hive.openBox<String>('favorites');
    notifyListeners();
  }

  /// Creates a new playlist with the given name.
  Future<void> createPlaylist(String name) async {
    if (!isReady) return;
    final playlist = Playlist(name: name, songIds: []);
    await _playlistBox!.add(playlist);
    notifyListeners();
  }

  /// Deletes the specified playlist.
  Future<void> deletePlaylist(Playlist playlist) async {
    if (!isReady) return;
    await playlist.delete();
    notifyListeners();
  }

  /// Adds a song to the specified playlist.
  Future<void> addSongToPlaylist(Playlist playlist, String songId) async {
    if (!isReady) return;
    if (!playlist.songIds.contains(songId)) {
      playlist.songIds.add(songId);
      await playlist.save();
      notifyListeners();
    }
  }

  /// Removes a song from the specified playlist.
  Future<void> removeSongFromPlaylist(
      Playlist playlist, String songId) async {
    if (!isReady) return;
    playlist.songIds.remove(songId);
    await playlist.save();
    notifyListeners();
  }

  /// Toggles the favorite status of a song.
  ///
  /// If the song is already a favorite, it will be removed.
  /// Otherwise, it will be added to favorites.
  Future<void> toggleFavorite(String songId) async {
    if (!isReady) return;
    if (_favoritesBox!.containsKey(songId)) {
      await _favoritesBox!.delete(songId);
    } else {
      await _favoritesBox!.put(songId, songId);
    }
    notifyListeners();
  }

  /// Checks if a song is in the favorites list.
  bool isFavorite(String songId) {
    return _favoritesBox?.containsKey(songId) ?? false;
  }
}
