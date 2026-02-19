import 'package:audio_player_offline/services/media_permission_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('MediaPermissionService', () {
    test('uses Permission.audio on Android 13+', () async {
      Permission? requestedPermission;

      final service = MediaPermissionService(
        platformOverride: TargetPlatform.android,
        androidSdkProvider: () async => 33,
        permissionRequester: (permission) async {
          requestedPermission = permission;
          return PermissionStatus.granted;
        },
      );

      final result = await service.ensureMediaReadPermission();
      expect(result.isGranted, isTrue);
      expect(requestedPermission, Permission.audio);
    });

    test('uses Permission.storage on Android 12 and below', () async {
      Permission? requestedPermission;

      final service = MediaPermissionService(
        platformOverride: TargetPlatform.android,
        androidSdkProvider: () async => 32,
        permissionRequester: (permission) async {
          requestedPermission = permission;
          return PermissionStatus.granted;
        },
      );

      final result = await service.ensureMediaReadPermission();
      expect(result.isGranted, isTrue);
      expect(requestedPermission, Permission.storage);
    });
  });
}
