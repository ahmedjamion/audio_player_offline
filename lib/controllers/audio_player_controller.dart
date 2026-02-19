import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as p;

import '../models/song_model.dart';
import '../services/media_permission_service.dart';

enum AppSortType { title, artist, duration }
enum ScanIssue { none, permissionDenied, noFolders, error }

class LibraryScanResult {
  const LibraryScanResult({
    required this.success,
    required this.permissionDenied,
    required this.noFolders,
    this.errorMessage,
  });

  final bool success;
  final bool permissionDenied;
  final bool noFolders;
  final String? errorMessage;
}

class AudioPlayerController extends ChangeNotifier {
  AudioPlayerController({
    MediaPermissionService? mediaPermissionService,
  }) : _mediaPermissionService =
           mediaPermissionService ?? MediaPermissionService() {
    _initPlayer();
  }

  final AudioPlayer _player = AudioPlayer();
  final MediaStore _mediaStore = MediaStore();
  final MediaPermissionService _mediaPermissionService;

  final List<Song> _songs = [];
  List<Song> get songs => List.unmodifiable(_songs);

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  ScanIssue _scanIssue = ScanIssue.none;
  ScanIssue get scanIssue => _scanIssue;
  String? _scanErrorMessage;
  String? get scanErrorMessage => _scanErrorMessage;

  Song? _currentSong;
  Song? get currentSong => _currentSong;

  // Playback state
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  Duration _position = Duration.zero;
  Duration get position => _position;

  // Sorting
  bool _isShuffle = false;
  bool get isShuffle => _isShuffle;

  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;

  AppSortType _sortType = AppSortType.title;
  AppSortType get sortType => _sortType;

  void _initPlayer() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

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
  }

  Future<LibraryScanResult> scanSongs(List<String> folders) async {
    _isLoading = true;
    _scanIssue = ScanIssue.none;
    _scanErrorMessage = null;
    notifyListeners();
    _songs.clear();

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        if (folders.isEmpty) {
          _scanIssue = ScanIssue.noFolders;
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
            _scanIssue = ScanIssue.permissionDenied;
          } else if (result.noFolders) {
            _scanIssue = ScanIssue.noFolders;
          } else {
            _scanIssue = ScanIssue.error;
            _scanErrorMessage = result.errorMessage;
          }
          return result;
        }
      }

      _sortSongs();
      return const LibraryScanResult(
        success: true,
        permissionDenied: false,
        noFolders: false,
      );
    } catch (e) {
      _scanIssue = ScanIssue.error;
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

  void setSortType(AppSortType type) {
    _sortType = type;
    _sortSongs();
    notifyListeners();
  }

  void _sortSongs() {
    sortSongsByType(_songs, _sortType);
  }

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
    for (var folder in folders) {
      final dir = Directory(folder);
      if (await dir.exists()) {
        try {
          await for (var entity in dir.list(
            recursive: true,
            followLinks: false,
          )) {
            if (entity is File) {
              String ext = p.extension(entity.path).toLowerCase();
              if (['.mp3', '.m4a', '.wav', '.flac', '.ogg'].contains(ext)) {
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
                  debugPrint('Error parsing metadata for ${entity.path}: $e');
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
          debugPrint('Error scanning directory $folder: $e');
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

  Future<void> playSong(Song song) async {
    _currentSong = song;
    notifyListeners();

    try {
      Uri? artUri;
      if (Platform.isAndroid) {
        try {
          artUri = await _mediaStore.getUriFromFilePath(path: song.path);
        } catch (_) {
          artUri = null;
        }
      }

      final source = AudioSource.file(
        song.path,
        tag: MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          album: song.album,
          artUri: artUri,
        ),
      );

      await _player.setAudioSource(source);
      await _player.play();
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> toggleShuffle() async {
    final enable = !_isShuffle;
    await _player.setShuffleModeEnabled(enable);
  }

  Future<void> toggleLoop() async {
    final nextMode = _loopMode == LoopMode.off
        ? LoopMode.all
        : (_loopMode == LoopMode.all ? LoopMode.one : LoopMode.off);
    await _player.setLoopMode(nextMode);
  }

  // Next/Prev requires playlist implementation in just_audio (ConcatenatingAudioSource)
  // For now, implementing simple single plays.
  // TODO: Upgrade to ConcatenatingAudioSource for gapless playback and proper queue management.
}
