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
        title: const Text('Manage Folders'),
      ),
      body: Consumer<SettingsController>(
        builder: (context, settings, child) {
          if (settings.folders.isEmpty) {
            return const Center(
              child: Text(
                'No folders added.\nAdd a folder to scan for music.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: settings.folders.length,
            itemBuilder: (context, index) {
              final folder = settings.folders[index];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(folder),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    settings.removeFolder(folder);
                    // Trigger re-scan?
                    context.read<AudioPlayerController>().scanSongs(settings.folders);
                  },
                ),
              );
            },
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
