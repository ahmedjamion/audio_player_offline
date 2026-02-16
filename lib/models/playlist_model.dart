import 'package:hive/hive.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 1)
class Playlist extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<String> songIds; // References to Song.id

  Playlist({
    required this.name,
    required this.songIds,
  });
}
