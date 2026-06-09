import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// ✅ Request Camera Permission
  Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      final status = await Permission.camera.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.camera.request();

        if (result.isGranted) {
          return true;
        } else if (result.isPermanentlyDenied) {
          _showPermissionDialog(
            context,
            'Camera Permission Required',
            'Syncly needs camera access to take photos for channels and profile. Please enable it in Settings.',
          );
          return false;
        }
      }

      if (status.isPermanentlyDenied) {
        _showPermissionDialog(
          context,
          'Camera Permission Required',
          'syncly needs camera access. Please enable it in Settings.',
        );
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Camera permission error: $e');
      return false;
    }
  }

  /// ✅ Request Photo/Gallery Permission (handles Android 13+ and older)
  Future<bool> requestPhotosPermission(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        // Android 13+ (API 33+) uses new photo picker
        if (androidInfo.version.sdkInt >= 33) {
          final status = await Permission.photos.status;

          if (status.isGranted || status.isLimited) {
            return true;
          }

          if (status.isDenied) {
            final result = await Permission.photos.request();

            if (result.isGranted || result.isLimited) {
              return true;
            } else if (result.isPermanentlyDenied) {
              _showPermissionDialog(
                context,
                'Photos Permission Required',
                'Syncly needs access to your photos to select images for channels and profile. Please enable it in Settings.',
              );
              return false;
            }
          }

          if (status.isPermanentlyDenied) {
            _showPermissionDialog(
              context,
              'Photos Permission Required',
              'Please enable photo access in Settings.',
            );
            return false;
          }
        } else {
          // Android 12 and below uses storage permission
          final status = await Permission.storage.status;

          if (status.isGranted) {
            return true;
          }

          if (status.isDenied) {
            final result = await Permission.storage.request();

            if (result.isGranted) {
              return true;
            } else if (result.isPermanentlyDenied) {
              _showPermissionDialog(
                context,
                'Storage Permission Required',
                'syncly needs storage access to select images. Please enable it in Settings.',
              );
              return false;
            }
          }

          if (status.isPermanentlyDenied) {
            _showPermissionDialog(
              context,
              'Storage Permission Required',
              'Please enable storage access in Settings.',
            );
            return false;
          }
        }
      } else if (Platform.isIOS) {
        // iOS photo library permission
        final status = await Permission.photos.status;

        if (status.isGranted || status.isLimited) {
          return true;
        }

        if (status.isDenied) {
          final result = await Permission.photos.request();

          if (result.isGranted || result.isLimited) {
            return true;
          } else if (result.isPermanentlyDenied) {
            _showPermissionDialog(
              context,
              'Photos Permission Required',
              'syncly needs access to your photos. Please enable it in Settings.',
            );
            return false;
          }
        }

        if (status.isPermanentlyDenied) {
          _showPermissionDialog(
            context,
            'Photos Permission Required',
            'Please enable photo access in Settings.',
          );
          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Photos permission error: $e');
      return false;
    }
  }

  /// ✅ Show Settings Dialog
  void _showPermissionDialog(
      BuildContext context,
      String title,
      String message,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// ✅ Check if permission is granted
  Future<bool> isPhotosPermissionGranted() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.photos.status;
        return status.isGranted || status.isLimited;
      } else {
        return await Permission.storage.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    }

    return false;
  }

  Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }
}