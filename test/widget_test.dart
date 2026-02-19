import 'package:audio_player_offline/controllers/audio_player_controller.dart';
import 'package:audio_player_offline/controllers/playlist_controller.dart';
import 'package:audio_player_offline/controllers/settings_controller.dart';
import 'package:audio_player_offline/models/playlist_model.dart';
import 'package:audio_player_offline/models/song_model.dart';
import 'package:audio_player_offline/screens/home_screen.dart';
import 'package:audio_player_offline/screens/player_screen.dart';
import 'package:audio_player_offline/screens/settings_screen.dart';
import 'package:audio_player_offline/services/media_permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class FakeAudioPlayerController extends ChangeNotifier
    implements AudioPlayerController {
  @override
  List<Song> songs = [];
  @override
  bool isLoading = false;
  @override
  Song? currentSong;
  @override
  bool isPlaying = false;
  @override
  Duration duration = const Duration(minutes: 3);
  @override
  Duration position = const Duration(seconds: 10);
  @override
  bool isShuffle = false;
  @override
  LoopMode loopMode = LoopMode.off;
  @override
  AppSortType sortType = AppSortType.title;
  @override
  ScanIssue scanIssue = ScanIssue.none;
  @override
  String? scanErrorMessage;

  int scanCalls = 0;

  @override
  Future<void> pause() async {
    isPlaying = false;
    notifyListeners();
  }

  @override
  Future<void> playSong(Song song) async {
    currentSong = song;
    isPlaying = true;
    notifyListeners();
  }

  @override
  Future<void> resume() async {
    isPlaying = true;
    notifyListeners();
  }

  @override
  Future<LibraryScanResult> scanSongs(List<String> folders) async {
    scanCalls++;
    return const LibraryScanResult(
      success: true,
      permissionDenied: false,
      noFolders: false,
    );
  }

  @override
  Future<void> seek(Duration position) async {
    this.position = position;
    notifyListeners();
  }

  @override
  void setSortType(AppSortType type) {
    sortType = type;
    notifyListeners();
  }

  @override
  Future<void> toggleLoop() async {
    loopMode = loopMode == LoopMode.off ? LoopMode.all : LoopMode.off;
    notifyListeners();
  }

  @override
  Future<void> toggleShuffle() async {
    isShuffle = !isShuffle;
    notifyListeners();
  }
}

class FakePlaylistController extends ChangeNotifier implements PlaylistController {
  @override
  List<Playlist> playlists = [];
  @override
  List<String> favoriteIds = [];
  @override
  bool isReady = true;

  @override
  Future<void> addSongToPlaylist(Playlist playlist, String songId) async {}

  @override
  Future<void> createPlaylist(String name) async {}

  @override
  Future<void> deletePlaylist(Playlist playlist) async {}

  @override
  Future<void> init() async {}

  @override
  bool isFavorite(String songId) => favoriteIds.contains(songId);

  @override
  Future<void> removeSongFromPlaylist(Playlist playlist, String songId) async {}

  @override
  Future<void> toggleFavorite(String songId) async {
    if (favoriteIds.contains(songId)) {
      favoriteIds.remove(songId);
    } else {
      favoriteIds.add(songId);
    }
    notifyListeners();
  }
}

class FakeSettingsController extends ChangeNotifier implements SettingsController {
  @override
  List<String> folders = [];
  AddFolderResult addFolderResult = const AddFolderResult(
    added: true,
    permissionDenied: false,
    cancelled: false,
    alreadyExists: false,
  );

  @override
  Future<AddFolderResult> addFolder() async {
    if (addFolderResult.added) {
      folders = ['/music'];
    }
    return addFolderResult;
  }

  @override
  Future<MediaPermissionResult> ensureMediaReadPermission() async {
    return const MediaPermissionResult(
      state: MediaPermissionState.granted,
      permission: null,
    );
  }

  @override
  Future<void> get initialized async {}

  @override
  Future<void> removeFolder(String path) async {
    folders.remove(path);
    notifyListeners();
  }
}

void main() {
  testWidgets('HomeScreen shows no folders guidance state', (tester) async {
    final audio = FakeAudioPlayerController()..scanIssue = ScanIssue.noFolders;
    final playlist = FakePlaylistController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerController>.value(value: audio),
          ChangeNotifierProvider<PlaylistController>.value(value: playlist),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('No folders selected. Add folders in Settings.'), findsOneWidget);
  });

  testWidgets('PlayerScreen play/pause button updates UI', (tester) async {
    final audio = FakeAudioPlayerController()
      ..currentSong = Song(
        id: '1',
        title: 'Song A',
        artist: 'Artist A',
        album: 'Album A',
        path: '/song.mp3',
        duration: 1000,
      )
      ..isPlaying = false;
    final playlist = FakePlaylistController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerController>.value(value: audio),
          ChangeNotifierProvider<PlaylistController>.value(value: playlist),
        ],
        child: const MaterialApp(home: PlayerScreen()),
      ),
    );

    expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_circle_filled));
    await tester.pump();
    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
  });

  testWidgets('SettingsScreen add folder triggers scan', (tester) async {
    final audio = FakeAudioPlayerController();
    final settings = FakeSettingsController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerController>.value(value: audio),
          ChangeNotifierProvider<SettingsController>.value(value: settings),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(audio.scanCalls, 1);
  });
}
