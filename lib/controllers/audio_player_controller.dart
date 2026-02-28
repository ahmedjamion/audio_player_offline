import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';

import '../models/song_model.dart';
import '../services/media_permission_service.dart';

final Logger _logger = Logger('AudioPlayerController');

const String _songsBoxName = 'cached_songs';
const String _scanFoldersBoxName = 'scan_folders';

/// Defines the available sorting options for the song library.
enum AppSortType {
  /// Sort by song title.
  title,

  /// Sort by artist name.
  artist,

  /// Sort by song duration.
  duration,
}

/// Represents the issues that can occur during library scanning.
sealed class ScanIssue {
  const ScanIssue();
}

/// No issues encountered.
class ScanIssueNone extends ScanIssue {
  const ScanIssueNone();
}

/// Permission to access media was denied.
class ScanIssuePermissionDenied extends ScanIssue {
  const ScanIssuePermissionDenied();
}

/// No folders were selected for scanning.
class ScanIssueNoFolders extends ScanIssue {
  const ScanIssueNoFolders();
}

/// An error occurred during scanning.
class ScanIssueError extends ScanIssue {
  const ScanIssueError([this.message]);

  final String? message;
}

/// Result of a library scan operation.
class LibraryScanResult {
  const LibraryScanResult({
    required this.success,
    required this.permissionDenied,
    required this.noFolders,
    this.errorMessage,
  });

  /// Whether the scan completed successfully.
  final bool success;

  /// Whether media permission was denied.
  final bool permissionDenied;

  /// Whether no folders were selected.
  final bool noFolders;

  /// Error message if the scan failed.
  final String? errorMessage;
}

/// Controller for managing audio playback and library scanning.
///
/// This controller handles scanning for audio files on the device,
/// managing playback state, and providing sorting capabilities.
class AudioPlayerController extends ChangeNotifier {
  /// Creates an AudioPlayerController.
  ///
  /// Optionally accepts a [mediaPermissionService] for dependency injection.
  AudioPlayerController({
    MediaPermissionService? mediaPermissionService,
  })  : _mediaPermissionService =
            mediaPermissionService ?? MediaPermissionService() {
    _initPlayer();
  }

  Box<List<String>>? _songsBox;
  Box<List<String>>? _foldersBox;

  final AudioPlayer _player = AudioPlayer();
  final MediaStore _mediaStore = MediaStore();
  final MediaPermissionService _mediaPermissionService;

  final List<Song> _songs = [];

  /// The list of scanned songs in the library.
  List<Song> get songs => List.unmodifiable(_songs);

  final List<Song> _queue = [];

  /// The current playback queue.
  List<Song> get queue => List.unmodifiable(_queue);

  int _queueIndex = -1;

  /// The current index in the queue.
  int get queueIndex => _queueIndex;

  bool _isLoading = false;

  /// Whether the library is currently being scanned.
  bool get isLoading => _isLoading;
  ScanIssue _scanIssue = const ScanIssueNone();

  /// The current scan issue, if any.
  ScanIssue get scanIssue => _scanIssue;
  String? _scanErrorMessage;

  /// Error message from the last scan, if it failed.
  String? get scanErrorMessage => _scanErrorMessage;

  Song? _currentSong;

  /// The currently playing song.
  Song? get currentSong => _currentSong;

  // Playback state
  bool _isPlaying = false;

  /// Whether audio is currently playing.
  bool get isPlaying => _isPlaying;

  String? _playbackError;

  /// Error message from playback, if any.
  String? get playbackError => _playbackError;

  Duration _duration = Duration.zero;

  /// Duration of the current song.
  Duration get duration => _duration;

  Duration _position = Duration.zero;

  /// Current playback position.
  Duration get position => _position;

  // Sorting
  bool _isShuffle = false;

  /// Whether shuffle mode is enabled.
  bool get isShuffle => _isShuffle;

  LoopMode _loopMode = LoopMode.off;

  /// The current loop mode.
  LoopMode get loopMode => _loopMode;

  AppSortType _sortType = AppSortType.title;

  /// The current sort type for the library.
  AppSortType get sortType => _sortType;

  void _initPlayer() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _isPlaying = false;
        notifyListeners();
      }
    });

    _player.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace stackTrace) {
        _playbackError = e.toString();
        _logger.severe('Playback error: $e');
        notifyListeners();
      },
    );

    _player.durationStream.listen((d) {
      _duration = d ?? Duration.zero;
      notifyListeners();
    });

    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.shuffleModeEnabledStream.listen((enabled) {
      _isShuffle = enabled;
      notifyListeners();
    });

    _player.loopModeStream.listen((mode) {
      _loopMode = mode;
      notifyListeners();
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _queue.length) {
        _queueIndex = index;
        _currentSong = _queue[index];
        notifyListeners();
      }
    });
  }

  Future<void> _loadCachedSongs() async {
    try {
      _songsBox = await Hive.openBox<List<String>>(_songsBoxName);
      _foldersBox = await Hive.openBox<List<String>>(_scanFoldersBoxName);

      final cachedSongs = _songsBox!.get('songs');
      if (cachedSongs != null && cachedSongs.isNotEmpty) {
        for (final path in cachedSongs) {
          final file = File(path);
          if (await file.exists()) {
            _songs.add(Song(
              id: path,
              title: p.basenameWithoutExtension(path),
              artist: 'Unknown Artist',
              album: 'Unknown Album',
              path: path,
              duration: 0,
            ));
          }
        }
        if (_songs.isNotEmpty) {
          _sortSongs();
          notifyListeners();
          _logger.info('Loaded ${_songs.length} cached songs');
        }
      }
    } catch (e) {
      _logger.warning('Failed to load cached songs: $e');
    }
  }

  Future<void> _saveSongsToCache(List<String> folders) async {
    try {
      if (_songsBox == null) {
        _songsBox = await Hive.openBox<List<String>>(_songsBoxName);
      }
      if (_foldersBox == null) {
        _foldersBox = await Hive.openBox<List<String>>(_scanFoldersBoxName);
      }

      final paths = _songs.map((s) => s.path).toList();
      await _songsBox!.put('songs', paths);
      await _foldersBox!.put('folders', folders);
      _logger.info('Cached ${_songs.length} songs');
    } catch (e) {
      _logger.warning('Failed to cache songs: $e');
    }
  }

  /// Returns whether the folders have changed since last scan.
  Future<bool> haveFoldersChanged(List<String> newFolders) async {
    try {
      if (_foldersBox == null) {
        _foldersBox = await Hive.openBox<List<String>>(_scanFoldersBoxName);
      }
      final cachedFolders = _foldersBox!.get('folders');
      if (cachedFolders == null) return true;

      if (cachedFolders.length != newFolders.length) return true;
      for (var i = 0; i < cachedFolders.length; i++) {
        if (cachedFolders[i] != newFolders[i]) return true;
      }
      return false;
    } catch (e) {
      return true;
    }
  }

  /// Scans the specified folders for audio files.
  ///
  /// Returns a [LibraryScanResult] indicating the outcome of the scan.
  /// On desktop platforms (Windows, Linux, Mac), requires at least one folder.
  /// On mobile platforms (Android, iOS), will use default folders if none provided.
  Future<LibraryScanResult> scanSongs(List<String> folders) async {
    _isLoading = true;
    _scanIssue = const ScanIssueNone();
    _scanErrorMessage = null;
    notifyListeners();
    _songs.clear();

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        if (folders.isEmpty) {
          _scanIssue = const ScanIssueNoFolders();
          return const LibraryScanResult(
            success: false,
            permissionDenied: false,
            noFolders: true,
          );
        }
        await _scanDesktop(folders);
      } else if (Platform.isAndroid || Platform.isIOS) {
        final result = await _scanMobile(folders);
        if (!result.success) {
          if (result.permissionDenied) {
            _scanIssue = const ScanIssuePermissionDenied();
          } else if (result.noFolders) {
            _scanIssue = const ScanIssueNoFolders();
          } else {
            _scanIssue = const ScanIssueError();
            _scanErrorMessage = result.errorMessage;
          }
          return result;
        }
      }

      _sortSongs();
      await _saveSongsToCache(folders);
      return const LibraryScanResult(
        success: true,
        permissionDenied: false,
        noFolders: false,
      );
    } catch (e) {
      _scanIssue = const ScanIssueError();
      _scanErrorMessage = 'Scan failed: $e';
      return LibraryScanResult(
        success: false,
        permissionDenied: false,
        noFolders: false,
        errorMessage: _scanErrorMessage,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the sorting type for the library.
  void setSortType(AppSortType type) {
    _sortType = type;
    _sortSongs();
    notifyListeners();
  }

  void _sortSongs() {
    sortSongsByType(_songs, _sortType);
  }

  /// Sorts a list of songs by the specified type.
  ///
  /// This is a static method that can be used to sort songs outside of
  /// the controller context.
  static void sortSongsByType(List<Song> songs, AppSortType type) {
    switch (type) {
      case AppSortType.title:
        songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case AppSortType.artist:
        songs.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case AppSortType.duration:
        songs.sort((a, b) => a.duration.compareTo(b.duration));
        break;
    }
  }

  Future<void> _scanDesktop(List<String> folders) async {
    final seenPaths = <String>{};
    
    for (var folder in folders) {
      final dir = Directory(folder);
      if (await dir.exists()) {
        try {
          await for (var entity in dir.list(
            recursive: true,
            followLinks: false,
          )) {
            if (entity is File) {
              final String ext = p.extension(entity.path).toLowerCase();
              if (['.mp3', '.m4a', '.wav', '.flac', '.ogg'].contains(ext)) {
                if (seenPaths.contains(entity.path)) continue;
                seenPaths.add(entity.path);
                
                try {
                  final metadata = readMetadata(
                    entity,
                    getImage: false,
                  );
                  _songs.add(
                    Song(
                      id: entity.path,
                      title:
                          metadata.title ?? p.basenameWithoutExtension(entity.path),
                      artist: metadata.artist ?? 'Unknown Artist',
                      album: metadata.album ?? 'Unknown Album',
                      path: entity.path,
                      duration: metadata.duration?.inMilliseconds ?? 0,
                    ),
                  );
                } catch (e) {
                  _logger.warning('Error parsing metadata for ${entity.path}: $e');
                  // Fallback without metadata
                  _songs.add(
                    Song(
                      id: entity.path,
                      title: p.basenameWithoutExtension(entity.path),
                      artist: 'Unknown Artist',
                      album: 'Unknown Album',
                      path: entity.path,
                      duration: 0,
                    ),
                  );
                }
              }
            }
          }
        } catch (e) {
          _logger.warning('Error scanning directory $folder: $e');
        }
      }
    }
  }

  Future<List<String>> _defaultAndroidFolders() async {
    const candidates = <String>[
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Podcasts',
      '/storage/emulated/0/Download',
      '/sdcard/Music',
    ];

    final existing = <String>[];
    for (final path in candidates) {
      if (await Directory(path).exists()) {
        existing.add(path);
      }
    }
    return existing;
  }

  Future<LibraryScanResult> _scanMobile(List<String> folders) async {
    final permissionResult =
        await _mediaPermissionService.ensureMediaReadPermission();
    if (!permissionResult.isGranted) {
      return const LibraryScanResult(
        success: false,
        permissionDenied: true,
        noFolders: false,
      );
    }

    var foldersToScan = folders;
    if (Platform.isAndroid && foldersToScan.isEmpty) {
      foldersToScan = await _defaultAndroidFolders();
    }

    if (foldersToScan.isEmpty) {
      return const LibraryScanResult(
        success: false,
        permissionDenied: false,
        noFolders: true,
      );
    }

    await _scanDesktop(foldersToScan);
    return const LibraryScanResult(
      success: true,
      permissionDenied: false,
      noFolders: false,
    );
  }

  /// Plays the specified song.
  ///
  /// Sets the song as the current track and begins playback.
  /// On Android, attempts to load album artwork from the media store.
  /// Builds a queue from all songs in the library.
  Future<void> playSong(Song song) async {
    if (_songs.isEmpty) return;

    final startIndex = _songs.indexOf(song);
    if (startIndex == -1) return;

    await playSongs(_songs, startIndex);
  }

  /// Plays a list of songs starting from the specified index.
  ///
  /// This is useful for playing a playlist or album.
  Future<void> playSongs(List<Song> songList, int startIndex) async {
    if (songList.isEmpty || startIndex < 0 || startIndex >= songList.length) {
      return;
    }

    _queue.clear();
    _queue.addAll(songList);
    _queueIndex = startIndex;
    _currentSong = _queue[startIndex];
    _playbackError = null;
    notifyListeners();

    _logger.info('Playing: ${songList[startIndex].path}');

    try {
      final sources = <AudioSource>[];
      for (final song in songList) {
        Uri? artUri;
        if (Platform.isAndroid) {
          try {
            artUri = await _mediaStore.getUriFromFilePath(path: song.path);
          } catch (_) {
            artUri = null;
          }
        }
        final sourceUri = Platform.isWindows
            ? Uri.file(song.path)
            : Uri.file(song.path);
        sources.add(AudioSource.uri(
          sourceUri,
          tag: MediaItem(
            id: song.id,
            title: song.title,
            artist: song.artist,
            album: song.album,
            artUri: artUri,
          ),
        ));
      }

      await _player.setAudioSources(
        sources,
        initialIndex: startIndex,
      );
      await _player.play();
      _logger.info('Play called successfully');
    } catch (e) {
      _logger.severe('Error playing song: $e');
    }
  }

  /// Plays the next song in the queue.
  ///
  /// Does nothing if there is no next song (unless loop mode is enabled).
  Future<void> next() async {
    if (_queue.isEmpty) return;
    await _player.seekToNext();
  }

  /// Plays the previous song in the queue.
  ///
  /// If more than 3 seconds into the song, restarts it instead.
  Future<void> previous() async {
    if (_queue.isEmpty) return;

    if (_position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    await _player.seekToPrevious();
  }

  /// Pauses the currently playing audio.
  Future<void> pause() async {
    await _player.pause();
  }

  /// Resumes playback of the current song.
  Future<void> resume() async {
    await _player.play();
  }

  /// Seeks to the specified position in the current song.
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Toggles shuffle mode on or off.
  Future<void> toggleShuffle() async {
    final enable = !_isShuffle;
    await _player.setShuffleModeEnabled(enable);
  }

  /// Toggles loop mode between off, all, and one.
  ///
  /// Cycles through: off -> all -> one -> off
  Future<void> toggleLoop() async {
    final nextMode = _loopMode == LoopMode.off
        ? LoopMode.all
        : (_loopMode == LoopMode.all ? LoopMode.one : LoopMode.off);
    await _player.setLoopMode(nextMode);
  }
}
