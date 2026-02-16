import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const String _prefKeyFolders = 'audio_folders';
  List<String> _folders = [];

  List<String> get folders => List.unmodifiable(_folders);

  SettingsController() {
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    _folders = prefs.getStringList(_prefKeyFolders) ?? [];
    notifyListeners();
  }

  Future<void> addFolder() async {
    // Request storage permission if needed (mostly Android)
    if (!kIsWeb) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      // On Android 13+, different permissions apply, handled by file_picker usually or explicit request
    }

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      if (!_folders.contains(selectedDirectory)) {
        _folders.add(selectedDirectory);
        await _saveFolders();
        notifyListeners();
      }
    }
  }

  Future<void> removeFolder(String path) async {
    _folders.remove(path);
    await _saveFolders();
    notifyListeners();
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKeyFolders, _folders);
  }
}
