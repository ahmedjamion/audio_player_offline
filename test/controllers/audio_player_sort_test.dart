import 'package:audio_player_offline/controllers/audio_player_controller.dart';
import 'package:audio_player_offline/models/song_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<Song> sampleSongs() {
    return [
      Song(
        id: '2',
        title: 'Beta',
        artist: 'Zed',
        album: 'X',
        path: '/a.mp3',
        duration: 3000,
      ),
      Song(
        id: '1',
        title: 'Alpha',
        artist: 'Alice',
        album: 'Y',
        path: '/b.mp3',
        duration: 1000,
      ),
      Song(
        id: '3',
        title: 'Gamma',
        artist: 'Bob',
        album: 'Z',
        path: '/c.mp3',
        duration: 2000,
      ),
    ];
  }

  test('sortSongsByType sorts by title', () {
    final songs = sampleSongs();
    AudioPlayerController.sortSongsByType(songs, AppSortType.title);
    expect(songs.map((s) => s.title).toList(), ['Alpha', 'Beta', 'Gamma']);
  });

  test('sortSongsByType sorts by artist', () {
    final songs = sampleSongs();
    AudioPlayerController.sortSongsByType(songs, AppSortType.artist);
    expect(songs.map((s) => s.artist).toList(), ['Alice', 'Bob', 'Zed']);
  });

  test('sortSongsByType sorts by duration', () {
    final songs = sampleSongs();
    AudioPlayerController.sortSongsByType(songs, AppSortType.duration);
    expect(songs.map((s) => s.duration).toList(), [1000, 2000, 3000]);
  });
}
