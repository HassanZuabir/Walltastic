import 'package:get/get.dart';

import '../data/wallpaper_apply_service.dart';
import '../models/wallpaper.dart';

class ApplyState {
  const ApplyState({this.busy = false, this.message = '', this.failed = false});

  final bool busy;
  final String message;
  final bool failed;
}

class WallpaperApplyController extends GetxController {
  WallpaperApplyController(this.service);

  final WallpaperApplyService service;
  final states = <int, ApplyState>{}.obs;

  bool get isSupported => service.isSupported;

  ApplyState stateFor(Wallpaper photo) =>
      states[photo.id] ?? const ApplyState();

  Future<void> apply(Wallpaper photo, WallpaperTarget target) async {
    if (stateFor(photo).busy) return;
    states[photo.id] = const ApplyState(busy: true);
    try {
      await service.apply(photo, target);
      if (!isClosed) {
        states[photo.id] = ApplyState(
          message: switch (target) {
            WallpaperTarget.home => 'Home screen wallpaper updated.',
            WallpaperTarget.lock => 'Lock screen wallpaper updated.',
            WallpaperTarget.both => 'Wallpaper updated.',
          },
        );
      }
    } on WallpaperApplyException catch (error) {
      if (!isClosed) {
        states[photo.id] = ApplyState(message: error.message, failed: true);
      }
    }
  }
}
