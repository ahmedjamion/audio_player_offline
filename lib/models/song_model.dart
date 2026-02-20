import 'package:hive/hive.dart';

part 'song_model.g.dart';

/// Represents an audio song in the library.
@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  final String id;

  /// The title of the song.
  @HiveField(1)
  final String title;

  /// The artist of the song.
  @HiveField(2)
  final String artist;

  /// The album of the song.
  @HiveField(3)
  final String album;

  /// The file path to the audio file.
  @HiveField(4)
  final String path;

  /// Duration of the song in milliseconds.
  @HiveField(5)
  final int duration;

  /// Android media store ID, if available.
  @HiveField(6)
  final int? androidId;

  /// Whether the song is marked as favorite.
  @HiveField(7)
  bool isFavorite;

  /// Creates a Song with the given properties.
  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.duration,
    this.androidId,
    this.isFavorite = false,
  });

  /// Creates a copy of this song with optionally modified fields.
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? path,
    int? duration,
    int? androidId,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      androidId: androidId ?? this.androidId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
