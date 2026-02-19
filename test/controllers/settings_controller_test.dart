import 'package:audio_player_offline/controllers/settings_controller.dart';
import 'package:audio_player_offline/services/media_permission_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsController', () {
    test('loads folders from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'audio_folders': ['/music/a', '/music/b'],
      });

      final controller = SettingsController(
        preferencesProvider: SharedPreferences.getInstance,
        mediaPermissionService: MediaPermissionService(
          platformOverride: TargetPlatform.android,
          androidSdkProvider: () async => 33,
          permissionRequester: (_) async => PermissionStatus.granted,
        ),
        directoryPicker: () async => null,
      );
      await controller.initialized;

      expect(controller.folders, ['/music/a', '/music/b']);
    });

    test('addFolder returns permission denied when permission is not granted', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = SettingsController(
        preferencesProvider: SharedPreferences.getInstance,
        mediaPermissionService: MediaPermissionService(
          platformOverride: TargetPlatform.android,
          androidSdkProvider: () async => 33,
          permissionRequester: (_) async => PermissionStatus.denied,
        ),
        directoryPicker: () async => '/music/a',
      );
      await controller.initialized;

      final result = await controller.addFolder();

      expect(result.permissionDenied, isTrue);
      expect(controller.folders, isEmpty);
    });

    test('addFolder persists new folder', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = SettingsController(
        preferencesProvider: SharedPreferences.getInstance,
        mediaPermissionService: MediaPermissionService(
          platformOverride: TargetPlatform.android,
          androidSdkProvider: () async => 33,
          permissionRequester: (_) async => PermissionStatus.granted,
        ),
        directoryPicker: () async => '/music/a',
      );
      await controller.initialized;

      final result = await controller.addFolder();
      final prefs = await SharedPreferences.getInstance();

      expect(result.added, isTrue);
      expect(controller.folders, ['/music/a']);
      expect(prefs.getStringList('audio_folders'), ['/music/a']);
    });
  });
}
