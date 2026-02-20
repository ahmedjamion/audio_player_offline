import 'package:hive/hive.dart';

part 'playlist_model.g.dart';

/// Represents a playlist containing songs.
@HiveType(typeId: 1)
class Playlist extends HiveObject {
  /// The name of the playlist.
  @HiveField(0)
  final String name;

  /// List of song IDs in this playlist.
  @HiveField(1)
  final List<String> songIds;

  /// Creates a Playlist with the given name and optional song IDs.
  Playlist({
    required this.name,
    required this.songIds,
  });
}
