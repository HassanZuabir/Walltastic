import 'package:flutter/material.dart';

import '../models/wallpaper.dart';
import '../widgets/download_button.dart';
import '../widgets/wallpaper_image.dart';

class WallpaperViewerScreen extends StatefulWidget {
  const WallpaperViewerScreen({super.key, required this.photo});

  final Wallpaper photo;

  @override
  State<WallpaperViewerScreen> createState() => _WallpaperViewerScreenState();
}

class _WallpaperViewerScreenState extends State<WallpaperViewerScreen> {
  final transformation = TransformationController();
  int imageRevision = 0;

  @override
  void dispose() {
    transformation.dispose();
    super.dispose();
  }

  Future<void> _retryImage() async {
    await NetworkImage(widget.photo.originalUrl).evict();
    if (mounted) setState(() => imageRevision++);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Original image'),
      actions: [
        IconButton(
          tooltip: 'Reset zoom',
          onPressed: () => transformation.value = Matrix4.identity(),
          icon: const Icon(Icons.fit_screen_rounded),
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            Expanded(
              child: Semantics(
                label: widget.photo.title,
                child: InteractiveViewer(
                  transformationController: transformation,
                  minScale: 1,
                  maxScale: 5,
                  child: SizedBox.expand(
                    child: WallpaperImage(
                      key: ValueKey(imageRevision),
                      url: widget.photo.originalUrl,
                      fit: BoxFit.contain,
                      onRetry: _retryImage,
                    ),
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.5,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Pinch to zoom. Drag to explore.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DownloadButton(photo: widget.photo),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
