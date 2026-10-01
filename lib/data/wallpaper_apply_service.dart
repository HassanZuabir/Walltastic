import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/wallpaper.dart';

enum WallpaperTarget { home, lock, both }

class WallpaperApplyException implements Exception {
  const WallpaperApplyException(this.message);
  final String message;
}

/// Downloads a wallpaper and applies it as the device wallpaper via the
/// native Android WallpaperManager (walltastic/wallpaper method channel).
class WallpaperApplyService {
  static const _channel = MethodChannel('walltastic/wallpaper');

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> apply(Wallpaper photo, WallpaperTarget target) async {
    if (!isSupported) {
      throw const WallpaperApplyException(
        'Setting wallpapers is only supported on Android.',
      );
    }
    File? file;
    try {
      final response = await http
          .get(Uri.parse(photo.originalUrl))
          .timeout(const Duration(seconds: 45));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw const WallpaperApplyException(
          'The image could not be downloaded. Please try again.',
        );
      }
      final temporary = await getTemporaryDirectory();
      file = File('${temporary.path}/walltastic-apply-${photo.id}.img');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      await _channel.invokeMethod<bool>('setWallpaper', {
        'path': file.path,
        'target': target.name,
      });
    } on TimeoutException {
      throw const WallpaperApplyException(
        'The download timed out. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const WallpaperApplyException(
        'Could not download the image. Check your internet connection.',
      );
    } on SocketException {
      throw const WallpaperApplyException(
        'The connection was interrupted. Please try again.',
      );
    } on FileSystemException {
      throw const WallpaperApplyException(
        'Could not store the image. Check your available device storage.',
      );
    } on PlatformException {
      throw const WallpaperApplyException(
        'Your device could not set the wallpaper. Please try again.',
      );
    } finally {
      try {
        await file?.delete();
      } on FileSystemException {
        // Temp file cleanup is best-effort.
      }
    }
  }
}
