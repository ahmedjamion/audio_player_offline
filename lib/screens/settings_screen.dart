import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';
import '../controllers/audio_player_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsController>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Theme'),
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode, size: 18),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) {
                    settings.setThemeMode(selection.first);
                  },
                ),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Library',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              if (settings.folders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No folders added.\nAdd a folder to scan for music.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...settings.folders.map((folder) => ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(
                        folder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          settings.removeFolder(folder);
                          context
                              .read<AudioPlayerController>()
                              .scanSongs(settings.folders);
                        },
                      ),
                    )),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.read<SettingsController>().addFolder();
          if (!context.mounted) {
            return;
          }

          if (result.permissionDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Media permission denied. Please allow access.'),
              ),
            );
            return;
          }
          if (result.cancelled) {
            return;
          }
          if (result.alreadyExists) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Folder is already added.')),
            );
            return;
          }

          if (result.added) {
            final folders = context.read<SettingsController>().folders;
            await context.read<AudioPlayerController>().scanSongs(folders);
          }
        },
        label: const Text('Add Folder'),
        icon: const Icon(Icons.create_new_folder),
      ),
    );
  }
}
