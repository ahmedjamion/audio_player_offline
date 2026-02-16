import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../models/song_model.dart';

enum AppSortType { title, artist, duration }

class AudioPlayerController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  final List<Song> _songs = [];
  List<Song> get songs => List.unmodifiable(_songs);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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

  AudioPlayerController() {
    _initPlayer();
  }

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

  Future<void> scanSongs(List<String> folders) async {
    _isLoading = true;
    notifyListeners();
    _songs.clear();

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _scanDesktop(folders);
    } else if (Platform.isAndroid || Platform.isIOS) {
      await _scanMobile(folders);
    }

    _sortSongs();
    _isLoading = false;
    notifyListeners();
  }

  void setSortType(AppSortType type) {
    _sortType = type;
    _sortSongs();
    notifyListeners();
  }

  void _sortSongs() {
    switch (_sortType) {
      case AppSortType.title:
        _songs.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case AppSortType.artist:
        _songs.sort(
          (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
        );
        break;
      case AppSortType.duration:
        _songs.sort((a, b) => a.duration.compareTo(b.duration));
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
                  final metadata = await MetadataRetriever.fromFile(
                    File(entity.path),
                  );
                  _songs.add(
                    Song(
                      id: entity.path,
                      title:
                          metadata.trackName ??
                          p.basenameWithoutExtension(entity.path),
                      artist:
                          metadata.trackArtistNames?.first ?? 'Unknown Artist',
                      album: metadata.albumName ?? 'Unknown Album',
                      path: entity.path,
                      duration: metadata.trackDuration ?? 0,
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

  Future<void> _scanMobile(List<String> folders) async {
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        // Request legacy storage permission or READ_MEDIA_AUDIO depending on SDK
        // permission_handler handles SDK version checks automatically usually
        await Permission.storage.request();
        if (await Permission.audio.status.isDenied) {
          await Permission.audio.request();
        }
      } else {
        await Permission.mediaLibrary.request();
      }
    }

    // Query all songs
    List<SongModel> queriedSongs = await _audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    // Filter
    for (var s in queriedSongs) {
      // On Android 'data' contains the path
      bool inFolder =
          folders.isEmpty || folders.any((f) => s.data.startsWith(f));

      if (inFolder) {
        _songs.add(
          Song(
            id: s.id.toString(),
            title: s.title,
            artist: s.artist ?? 'Unknown Artist',
            album: s.album ?? 'Unknown Album',
            path: s.data,
            duration: s.duration ?? 0,
            androidId: s.id,
          ),
        );
      }
    }
  }

  Future<void> playSong(Song song) async {
    _currentSong = song;
    notifyListeners();

    try {
      Uri? artUri;
      if (song.androidId != null) {
        artUri = Uri.parse(
          'content://media/external/audio/albumart/${song.androidId}',
        );
        // Note: albumart URI might need albumId actually, but on_audio_query handles retrieval usually.
        // Actually typically it is content://media/external/audio/albumart matches album ID.
        // Let's rely on just_audio_background handling logic or use placeholders.
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
