import 'package:flutter/foundation.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum MediaPermissionState { granted, denied, permanentlyDenied }

class MediaPermissionResult {
  const MediaPermissionResult({
    required this.state,
    required this.permission,
  });

  final MediaPermissionState state;
  final Permission? permission;

  bool get isGranted => state == MediaPermissionState.granted;
}

typedef AndroidSdkProvider = Future<int> Function();
typedef PermissionRequester = Future<PermissionStatus> Function(Permission);

class MediaPermissionService {
  MediaPermissionService({
    AndroidSdkProvider? androidSdkProvider,
    PermissionRequester? permissionRequester,
    TargetPlatform? platformOverride,
    bool? isWebOverride,
  })  : _androidSdkProvider = androidSdkProvider,
        _permissionRequester = permissionRequester,
        _platformOverride = platformOverride,
        _isWebOverride = isWebOverride;

  final AndroidSdkProvider? _androidSdkProvider;
  final PermissionRequester? _permissionRequester;
  final TargetPlatform? _platformOverride;
  final bool? _isWebOverride;
  final MediaStore _mediaStore = MediaStore();

  Future<int> _getAndroidSdkInt() async {
    if (_androidSdkProvider != null) {
      return _androidSdkProvider();
    }
    await MediaStore.ensureInitialized();
    return _mediaStore.getPlatformSDKInt();
  }

  Future<PermissionStatus> _requestPermission(Permission permission) async {
    if (_permissionRequester != null) {
      return _permissionRequester(permission);
    }
    return permission.request();
  }

  Future<MediaPermissionResult> ensureMediaReadPermission() async {
    if (_isWebOverride ?? kIsWeb) {
      return const MediaPermissionResult(
        state: MediaPermissionState.granted,
        permission: null,
      );
    }

    switch (_platformOverride ?? defaultTargetPlatform) {
      case TargetPlatform.android:
        final sdkInt = await _getAndroidSdkInt();
        final permission = sdkInt >= 33 ? Permission.audio : Permission.storage;
        return _mapStatus(await _requestPermission(permission), permission);
      case TargetPlatform.iOS:
        return _mapStatus(
          await _requestPermission(Permission.mediaLibrary),
          Permission.mediaLibrary,
        );
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return const MediaPermissionResult(
          state: MediaPermissionState.granted,
          permission: null,
        );
    }
  }

  MediaPermissionResult _mapStatus(PermissionStatus status, Permission permission) {
    if (status.isGranted || status.isLimited) {
      return MediaPermissionResult(
        state: MediaPermissionState.granted,
        permission: permission,
      );
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return MediaPermissionResult(
        state: MediaPermissionState.permanentlyDenied,
        permission: permission,
      );
    }
    return MediaPermissionResult(
      state: MediaPermissionState.denied,
      permission: permission,
    );
  }
}
