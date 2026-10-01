import 'package:get/get.dart';

import '../data/wallpaper_download_service.dart';
import '../models/wallpaper.dart';

enum DownloadPhase { idle, downloading, saving, saved, failed }

class DownloadState {
  const DownloadState({
    this.phase = DownloadPhase.idle,
    this.progress,
    this.message = '',
  });

  final DownloadPhase phase;
  final double? progress;
  final String message;

  bool get isBusy =>
      phase == DownloadPhase.downloading || phase == DownloadPhase.saving;
}

class DownloadController extends GetxController {
  DownloadController(this.service);

  final WallpaperDownloadService service;
  final states = <int, DownloadState>{}.obs;

  DownloadState stateFor(Wallpaper photo) =>
      states[photo.id] ?? const DownloadState();

  Future<void> download(Wallpaper photo) async {
    if (stateFor(photo).isBusy) return;
    states[photo.id] = const DownloadState(phase: DownloadPhase.downloading);
    try {
      await service.download(
        photo,
        onProgress: (progress) {
          if (!isClosed) {
            states[photo.id] = DownloadState(
              phase: DownloadPhase.downloading,
              progress: progress,
            );
          }
        },
        onSaving: () {
          if (!isClosed) {
            states[photo.id] = const DownloadState(phase: DownloadPhase.saving);
          }
        },
      );
      if (!isClosed) {
        states[photo.id] = const DownloadState(
          phase: DownloadPhase.saved,
          message: 'Saved to your Photos / Gallery.',
        );
      }
    } on DownloadException catch (error) {
      if (!isClosed) {
        states[photo.id] = DownloadState(
          phase: DownloadPhase.failed,
          message: error.message,
        );
      }
    }
  }
}
