import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/settings_controller.dart';
import '../controllers/audio_player_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsController>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Appearance',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(LucideIcons.moon),
                title: const Text('Theme'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        LucideIcons.sun,
                        color: settings.themeMode == ThemeMode.light
                            ? theme.colorScheme.primary
                            : theme.iconTheme.color?.withValues(alpha: 0.5),
                      ),
                      onPressed: () => settings.setThemeMode(ThemeMode.light),
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.monitor,
                        color: settings.themeMode == ThemeMode.system
                            ? theme.colorScheme.primary
                            : theme.iconTheme.color?.withValues(alpha: 0.5),
                      ),
                      onPressed: () => settings.setThemeMode(ThemeMode.system),
                    ),
                    IconButton(
                      icon: Icon(
                        LucideIcons.moon,
                        color: settings.themeMode == ThemeMode.dark
                            ? theme.colorScheme.primary
                            : theme.iconTheme.color?.withValues(alpha: 0.5),
                      ),
                      onPressed: () => settings.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Library',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (settings.folders.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No folders added.\nAdd a folder to scan for music.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                ...settings.folders.map((folder) => ListTile(
                      leading: const Icon(LucideIcons.folder),
                      title: Text(
                        folder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.trash2),
                        onPressed: () {
                          settings.removeFolder(folder);
                          context
                              .read<AudioPlayerController>()
                              .scanSongs(settings.folders);
                        },
                      ),
                    )),
              const SizedBox(height: 80),
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
        icon: const Icon(LucideIcons.folderPlus),
      ),
    );
  }
}
