import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../services/media_permission_service.dart';

class AddFolderResult {
  const AddFolderResult({
    required this.added,
    required this.permissionDenied,
    required this.cancelled,
    required this.alreadyExists,
  });

  final bool added;
  final bool permissionDenied;
  final bool cancelled;
  final bool alreadyExists;
}

typedef PreferencesProvider = Future<SharedPreferences> Function();
typedef DirectoryPicker = Future<String?> Function();

class SettingsController extends ChangeNotifier {
  static const String _prefKeyFolders = 'audio_folders';

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
    _initialization = _loadFolders();
  }

  List<String> _folders = [];
  late final Future<void> _initialization;
  final MediaPermissionService _mediaPermissionService;
  final PreferencesProvider _preferencesProvider;
  final DirectoryPicker _directoryPicker;

  List<String> get folders => List.unmodifiable(_folders);
  Future<void> get initialized => _initialization;

  Future<void> _loadFolders() async {
    final prefs = await _preferencesProvider();
    _folders = prefs.getStringList(_prefKeyFolders) ?? [];
    notifyListeners();
  }

  Future<MediaPermissionResult> ensureMediaReadPermission() {
    return _mediaPermissionService.ensureMediaReadPermission();
  }

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

  Future<void> removeFolder(String path) async {
    _folders.remove(path);
    await _saveFolders();
    notifyListeners();
  }

  Future<void> _saveFolders() async {
    final prefs = await _preferencesProvider();
    await prefs.setStringList(_prefKeyFolders, _folders);
  }
}
