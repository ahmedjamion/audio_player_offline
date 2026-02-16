import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  final String id; 

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String album;

  @HiveField(4)
  final String path;

  @HiveField(5)
  final int duration; // Milliseconds

  @HiveField(6)
  final int? androidId; // For on_audio_query usage on Android

  @HiveField(7)
  bool isFavorite;

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

  // Factory constructor for creating a copy with modified fields
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
