import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/wallpaper_apply_controller.dart';
import '../data/wallpaper_apply_service.dart';
import '../models/wallpaper.dart';

/// "Set as wallpaper" button with a home/lock/both target picker.
/// Renders nothing on platforms without wallpaper support (iOS).
class SetWallpaperButton extends GetView<WallpaperApplyController> {
  const SetWallpaperButton({super.key, required this.photo});

  final Wallpaper photo;

  Future<void> _pickTarget(BuildContext context) async {
    final target = await showModalBottomSheet<WallpaperTarget>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Set as wallpaper',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home screen'),
              onTap: () => Navigator.pop(context, WallpaperTarget.home),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: const Text('Lock screen'),
              onTap: () => Navigator.pop(context, WallpaperTarget.lock),
            ),
            ListTile(
              leading: const Icon(Icons.smartphone_rounded),
              title: const Text('Home and lock screen'),
              onTap: () => Navigator.pop(context, WallpaperTarget.both),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (target != null) await controller.apply(photo, target);
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.isSupported) return const SizedBox.shrink();
    return Obx(() {
      final state = controller.stateFor(photo);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.tonalIcon(
            onPressed: state.busy ? null : () => _pickTarget(context),
            icon: state.busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wallpaper_rounded, size: 20),
            label: Text(
              state.busy ? 'Setting wallpaper...' : 'Set as wallpaper',
              textAlign: TextAlign.center,
            ),
          ),
          if (state.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: state.failed
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
