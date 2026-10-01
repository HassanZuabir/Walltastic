import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Schedules the native Android WorkManager job that periodically applies a
/// random saved favorite as the device wallpaper.
class AutoWallpaperScheduler {
  static const _channel = MethodChannel('walltastic/auto_wallpaper');

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> schedule({required int hours, required String target}) async {
    if (!isSupported) return;
    await _channel.invokeMethod<bool>('schedule', {
      'hours': hours,
      'target': target,
    });
  }

  Future<void> cancel() async {
    if (!isSupported) return;
    await _channel.invokeMethod<bool>('cancel');
  }
}
