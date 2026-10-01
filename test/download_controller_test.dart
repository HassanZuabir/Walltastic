import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walltastic/controllers/download_controller.dart';
import 'package:walltastic/data/wallpaper_download_service.dart';
import 'package:walltastic/models/wallpaper.dart';

import 'fixtures/wallpaper_fixtures.dart';

class ControlledDownloadService extends WallpaperDownloadService {
  ControlledDownloadService() : super(gallerySaver: DeviceGallerySaver());

  int calls = 0;
  Completer<void> result = Completer<void>();
  late void Function(double?) progress;
  late VoidCallback saving;

  @override
  Future<void> download(
    Wallpaper photo, {
    required void Function(double? progress) onProgress,
    required VoidCallback onSaving,
  }) {
    calls++;
    progress = onProgress;
    saving = onSaving;
    return result.future;
  }
}

void main() {
  test(
    'Progress updates and duplicate taps cannot start a second download',
    () async {
      final service = ControlledDownloadService();
      final controller = DownloadController(service);
      final photo = testWallpapers.first;
      final pending = controller.download(photo);
      expect(controller.stateFor(photo).isBusy, isTrue);
      await controller.download(photo);
      expect(service.calls, 1);
      service.progress(0.5);
      expect(controller.stateFor(photo).progress, 0.5);
      service.saving();
      expect(controller.stateFor(photo).phase, DownloadPhase.saving);
      service.result.complete();
      await pending;
      expect(controller.stateFor(photo).phase, DownloadPhase.saved);
      expect(controller.stateFor(photo).isBusy, isFalse);
      controller.onClose();
    },
  );

  test('Failure is not marked saved and can be retried', () async {
    final service = ControlledDownloadService();
    final controller = DownloadController(service);
    final photo = testWallpapers.first;
    final failed = controller.download(photo);
    service.result.completeError(const DownloadException('Permission denied'));
    await failed;
    expect(controller.stateFor(photo).phase, DownloadPhase.failed);
    expect(controller.stateFor(photo).message, 'Permission denied');
    expect(controller.stateFor(testWallpapers[1]).phase, DownloadPhase.idle);

    service.result = Completer<void>();
    final retry = controller.download(photo);
    expect(controller.stateFor(photo).message, isEmpty);
    service.result.complete();
    await retry;
    expect(service.calls, 2);
    expect(controller.stateFor(photo).phase, DownloadPhase.saved);
    controller.onClose();
  });
}
