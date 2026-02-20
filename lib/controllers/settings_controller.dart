import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../services/media_permission_service.dart';

/// Result of an add folder operation.
class AddFolderResult {
  const AddFolderResult({
    required this.added,
    required this.permissionDenied,
    required this.cancelled,
    required this.alreadyExists,
  });

  /// Whether the folder was successfully added.
  final bool added;

  /// Whether media permission was denied.
  final bool permissionDenied;

  /// Whether the folder picker was cancelled.
  final bool cancelled;

  /// Whether the folder is already in the list.
  final bool alreadyExists;
}

typedef PreferencesProvider = Future<SharedPreferences> Function();
typedef DirectoryPicker = Future<String?> Function();

/// Controller for managing app settings.
///
/// Handles folder management for music library scanning and theme preferences.
class SettingsController extends ChangeNotifier {
  static const String _prefKeyFolders = 'audio_folders';
  static const String _prefKeyThemeMode = 'theme_mode';

  /// Creates a SettingsController.
  ///
  /// Optionally accepts [mediaPermissionService], [preferencesProvider],
  /// and [directoryPicker] for dependency injection and testing.
  SettingsController({
    MediaPermissionService? mediaPermissionService,
    PreferencesProvider? preferencesProvider,
    DirectoryPicker? directoryPicker,
  })  : _mediaPermissionService =
            mediaPermissionService ?? MediaPermissionService(),
        _preferencesProvider =
            preferencesProvider ?? SharedPreferences.getInstance,
        _directoryPicker =
            directoryPicker ?? FilePicker.platform.getDirectoryPath {
    _initialization = _loadSettings();
  }

  List<String> _folders = [];
  late final Future<void> _initialization;
  final MediaPermissionService _mediaPermissionService;
  final PreferencesProvider _preferencesProvider;
  final DirectoryPicker _directoryPicker;
  ThemeMode _themeMode = ThemeMode.dark;

  /// The list of folders to scan for music.
  List<String> get folders => List.unmodifiable(_folders);

  /// Future that completes when settings are loaded.
  Future<void> get initialized => _initialization;

  /// The current theme mode.
  ThemeMode get themeMode => _themeMode;

  Future<void> _loadSettings() async {
    final prefs = await _preferencesProvider();
    _folders = prefs.getStringList(_prefKeyFolders) ?? [];
    final themeModeIndex = prefs.getInt(_prefKeyThemeMode) ?? 2;
    _themeMode = ThemeMode.values[themeModeIndex];
    notifyListeners();
  }

  /// Ensures media read permission is granted.
  ///
  /// Returns the result of the permission request.
  Future<MediaPermissionResult> ensureMediaReadPermission() {
    return _mediaPermissionService.ensureMediaReadPermission();
  }

  /// Opens a folder picker to add a folder to scan for music.
  ///
  /// Returns an [AddFolderResult] indicating the outcome.
  Future<AddFolderResult> addFolder() async {
    final permission = await ensureMediaReadPermission();
    if (!permission.isGranted) {
      return const AddFolderResult(
        added: false,
        permissionDenied: true,
        cancelled: false,
        alreadyExists: false,
      );
    }

    final selectedDirectory = await _directoryPicker();

    if (selectedDirectory != null) {
      if (!_folders.contains(selectedDirectory)) {
        _folders.add(selectedDirectory);
        await _saveFolders();
        notifyListeners();
        return const AddFolderResult(
          added: true,
          permissionDenied: false,
          cancelled: false,
          alreadyExists: false,
        );
      }
      return const AddFolderResult(
        added: false,
        permissionDenied: false,
        cancelled: false,
        alreadyExists: true,
      );
    }
    return const AddFolderResult(
      added: false,
      permissionDenied: false,
      cancelled: true,
      alreadyExists: false,
    );
  }

  /// Removes a folder from the scan list.
  Future<void> removeFolder(String path) async {
    _folders.remove(path);
    await _saveFolders();
    notifyListeners();
  }

  Future<void> _saveFolders() async {
    final prefs = await _preferencesProvider();
    await prefs.setStringList(_prefKeyFolders, _folders);
  }

  /// Sets the theme mode.
  ///
  /// Persists the selection and notifies listeners.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await _preferencesProvider();
    await prefs.setInt(_prefKeyThemeMode, mode.index);
    notifyListeners();
  }
}
