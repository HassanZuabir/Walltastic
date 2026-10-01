import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/gallery_controller.dart';
import '../models/wallpaper.dart';
import '../theme/app_theme.dart';
import '../widgets/download_button.dart';
import '../widgets/gallery_widgets.dart';
import '../widgets/set_wallpaper_button.dart';
import '../widgets/wallpaper_image.dart';
import 'wallpaper_viewer_screen.dart';

class WallpaperDetailScreen extends GetView<GalleryController> {
  const WallpaperDetailScreen({super.key, required this.photo});
  final Wallpaper photo;

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Wallpaper found with Walltastic',
        text:
            '${photo.title.split(' · ').first}\n'
            'Photo by ${photo.photographer} on Pexels\n'
            '${photo.pageUrl}\n\n'
            'Found with Walltastic',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final scheme = theme.colorScheme;
    final accent = light ? scheme.primary : AppColors.violet;
    final secondary = light ? scheme.onSurfaceVariant : Colors.white70;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'wallpaper-${photo.id}',
            child: WallpaperImage(url: photo.imageUrl),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.3, 0.5, 1],
                colors: [
                  Color(0x66101016),
                  Colors.transparent,
                  Color(0x22101016),
                  Color(0xFA101016),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      RoundButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back to gallery',
                        onPressed: () => Get.back<void>(),
                      ),
                      const Spacer(),
                      RoundButton(
                        icon: Icons.share_outlined,
                        tooltip: 'Share wallpaper',
                        onPressed: () => _share(context),
                      ),
                      const SizedBox(width: 10),
                      FavoriteButton(photo: photo),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 650),
                        child: Container(
                          padding: light
                              ? const EdgeInsets.all(20)
                              : EdgeInsets.zero,
                          decoration: light
                              ? BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: scheme.outlineVariant,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x18000000),
                                      blurRadius: 24,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                )
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'A VIEW TO MAKE YOURS',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                photo.title.split(' · ').first,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: light
                                          ? scheme.onSurface
                                          : Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  foregroundColor: secondary,
                                  alignment: Alignment.centerLeft,
                                ),
                                onPressed: () =>
                                    openExternalLink(context, photo.pageUrl),
                                icon: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 16,
                                ),
                                label: Text(photo.photographer),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (photo.width > 0 && photo.height > 0)
                                    _DetailTag(
                                      label: '${photo.width} × ${photo.height}',
                                    ),
                                  const _DetailTag(
                                    label: 'Photography on Pexels',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 26),
                              SetWallpaperButton(photo: photo),
                              const SizedBox(height: 10),
                              DownloadButton(photo: photo),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: accent,
                                  ),
                                  onPressed: () => Get.to<void>(
                                    () => WallpaperViewerScreen(photo: photo),
                                  ),
                                  child: const Text('View full image'),
                                ),
                              ),
                              Obx(
                                () => controller.storageError.value.isEmpty
                                    ? const SizedBox.shrink()
                                    : Text(
                                        controller.storageError.value,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                      ),
                              ),
                              Text(
                                'Support the view. Discover the photographer.',
                                style: TextStyle(
                                  color: light
                                      ? scheme.onSurfaceVariant
                                      : Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTag extends StatelessWidget {
  const _DetailTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.light
          ? Theme.of(context).colorScheme.surfaceContainerLow
          : Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.light
            ? Theme.of(context).colorScheme.outlineVariant
            : Colors.white12,
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).brightness == Brightness.light
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Colors.white70,
      ),
    ),
  );
}
