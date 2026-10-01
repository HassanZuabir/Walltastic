import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/download_controller.dart';
import '../models/wallpaper.dart';

class DownloadButton extends GetView<DownloadController> {
  const DownloadButton({super.key, required this.photo});

  final Wallpaper photo;

  @override
  Widget build(BuildContext context) => Obx(() {
    final state = controller.stateFor(photo);
    final label = switch (state.phase) {
      DownloadPhase.idle => 'Download wallpaper',
      DownloadPhase.downloading =>
        state.progress == null
            ? 'Downloading...'
            : 'Downloading ${(state.progress! * 100).round()}%',
      DownloadPhase.saving => 'Saving to gallery...',
      DownloadPhase.saved => 'Download again',
      DownloadPhase.failed => 'Retry download',
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: state.isBusy ? null : () => controller.download(photo),
          icon: state.isBusy
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: state.phase == DownloadPhase.downloading
                        ? state.progress
                        : null,
                  ),
                )
              : Icon(
                  state.phase == DownloadPhase.saved
                      ? Icons.download_done_rounded
                      : Icons.download_rounded,
                  size: 20,
                ),
          label: Text(label, textAlign: TextAlign.center),
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
                  color: state.phase == DownloadPhase.failed
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
