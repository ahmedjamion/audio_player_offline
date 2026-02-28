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
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class FakeAudioPlayerController extends ChangeNotifier
    implements AudioPlayerController {
  @override
  List<Song> songs = [];
  @override
  List<Song> queue = [];
  @override
  int queueIndex = -1;
  @override
  bool isLoading = false;
  @override
  Song? currentSong;
  @override
  bool isPlaying = false;
  @override
  String? playbackError;
  @override
  String? scanErrorMessage;
  @override
  Duration duration = const Duration(minutes: 3);
  @override
  Duration position = Duration.zero;
  @override
  bool isShuffle = false;
  @override
  LoopMode loopMode = LoopMode.off;
  @override
  AppSortType sortType = AppSortType.title;
  @override
  ScanIssue scanIssue = const ScanIssueNone();
  @override
  bool isInitialized = true;

  int scanCalls = 0;

  @override
  Future<void> next() async {}

  @override
  Future<void> previous() async {}

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
  Future<void> playSongs(List<Song> songs, int startIndex) async {
    if (startIndex >= 0 && startIndex < songs.length) {
      currentSong = songs[startIndex];
    }
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

  @override
  Future<void> initWithFolders(List<String> folders) async {}

  @override
  Future<bool> haveFoldersChanged(List<String> newFolders) async => false;
}

class FakePlaylistController extends ChangeNotifier
    implements PlaylistController {
  @override
  List<Playlist> playlists = [];
  @override
  List<String> favoriteIds = [];
  //@override
  bool isLoading = false;
  @override
  bool isReady = true;

  @override
  Future<void> init() async {}

  @override
  bool isFavorite(String songId) => favoriteIds.contains(songId);

  @override
  Future<void> toggleFavorite(String songId) async {
    if (favoriteIds.contains(songId)) {
      favoriteIds.remove(songId);
    } else {
      favoriteIds.add(songId);
    }
    notifyListeners();
  }

  @override
  Future<void> createPlaylist(String name) async {
    final playlist = Playlist(name: name, songIds: []);
    playlists.add(playlist);
    notifyListeners();
  }

  @override
  Future<void> deletePlaylist(Playlist playlist) async {
    playlists.remove(playlist);
    notifyListeners();
  }

  @override
  Future<void> addSongToPlaylist(Playlist playlist, String songId) async {
    if (!playlist.songIds.contains(songId)) {
      playlist.songIds.add(songId);
      notifyListeners();
    }
  }

  @override
  Future<void> removeSongFromPlaylist(Playlist playlist, String songId) async {
    playlist.songIds.remove(songId);
    notifyListeners();
  }
}

class FakeSettingsController extends ChangeNotifier
    implements SettingsController {
  @override
  List<String> folders = [];
  @override
  ThemeMode themeMode = ThemeMode.dark;
  //@override
  bool isLoaded = true;
  @override
  Future<void> get initialized async {}

  //@override
  Future<void> loadSettings() async {}

  @override
  Future<AddFolderResult> addFolder() async {
    return const AddFolderResult(
      added: false,
      permissionDenied: false,
      cancelled: true,
      alreadyExists: false,
    );
  }

  @override
  Future<void> removeFolder(String folder) async {
    folders.remove(folder);
    notifyListeners();
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
  }

  @override
  Future<MediaPermissionResult> ensureMediaReadPermission() async {
    return const MediaPermissionResult(
      state: MediaPermissionState.granted,
      permission: Permission.audio,
    );
  }
}

void main() {
  testWidgets('HomeScreen shows no folders guidance state', (tester) async {
    final audio = FakeAudioPlayerController()
      ..scanIssue = const ScanIssueNoFolders();
    final playlist = FakePlaylistController();
    final settings = FakeSettingsController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerController>.value(value: audio),
          ChangeNotifierProvider<PlaylistController>.value(value: playlist),
          ChangeNotifierProvider<SettingsController>.value(value: settings),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('No folders selected. Add folders in Settings.'),
      findsOneWidget,
    );
  });

  testWidgets('PlayerScreen play/pause button updates UI', (tester) async {
    final audio = FakeAudioPlayerController()
      ..songs = [
        Song(
          id: '1',
          title: 'Test Song',
          artist: 'Artist',
          album: 'Album',
          path: '/test.mp3',
          duration: 180000,
        ),
      ]
      ..currentSong = Song(
        id: '1',
        title: 'Test Song',
        artist: 'Artist',
        album: 'Album',
        path: '/test.mp3',
        duration: 180000,
      );
    final playlist = FakePlaylistController();
    final settings = FakeSettingsController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerController>.value(value: audio),
          ChangeNotifierProvider<PlaylistController>.value(value: playlist),
          ChangeNotifierProvider<SettingsController>.value(value: settings),
        ],
        child: const MaterialApp(home: PlayerScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Song'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_circle_filled));
    await tester.pump();

    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
  });

  testWidgets('SettingsScreen add folder triggers scan', (tester) async {
    final audio = FakeAudioPlayerController();
    final playlist = FakePlaylistController();
    final settings = FakeSettingsController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerController>.value(value: audio),
          ChangeNotifierProvider<PlaylistController>.value(value: playlist),
          ChangeNotifierProvider<SettingsController>.value(value: settings),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add Folder'), findsOneWidget);
  });

  testWidgets('HomeScreen displays songs when library is loaded', (
    tester,
  ) async {
    final audio = FakeAudioPlayerController()
      ..songs = [
        Song(
          id: '1',
          title: 'Song One',
          artist: 'Artist A',
          album: 'Album A',
          path: '/song1.mp3',
          duration: 180000,
        ),
        Song(
          id: '2',
          title: 'Song Two',
          artist: 'Artist B',
          album: 'Album B',
          path: '/song2.mp3',
          duration: 240000,
        ),
      ];
    final playlist = FakePlaylistController();
    final settings = FakeSettingsController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerController>.value(value: audio),
          ChangeNotifierProvider<PlaylistController>.value(value: playlist),
          ChangeNotifierProvider<SettingsController>.value(value: settings),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Song One'), findsOneWidget);
    expect(find.text('Song Two'), findsOneWidget);
  });

  testWidgets('HomeScreen shows create playlist button when no playlists', (
    tester,
  ) async {
    final audio = FakeAudioPlayerController();
    final playlist = FakePlaylistController()..playlists = [];
    final settings = FakeSettingsController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerController>.value(value: audio),
          ChangeNotifierProvider<PlaylistController>.value(value: playlist),
          ChangeNotifierProvider<SettingsController>.value(value: settings),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Playlists'));
    await tester.pumpAndSettle();

    expect(find.text('Create Playlist'), findsOneWidget);
  });

  testWidgets('HomeScreen shows favorites tab with favorited songs', (
    tester,
  ) async {
    final audio = FakeAudioPlayerController()
      ..songs = [
        Song(
          id: '1',
          title: 'Favorite Song',
          artist: 'Artist A',
          album: 'Album A',
          path: '/song1.mp3',
          duration: 180000,
        ),
      ];
    final playlist = FakePlaylistController()..favoriteIds = ['1'];
    final settings = FakeSettingsController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioPlayerController>.value(value: audio),
          ChangeNotifierProvider<PlaylistController>.value(value: playlist),
          ChangeNotifierProvider<SettingsController>.value(value: settings),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('Favorite Song'), findsOneWidget);
  });
}
