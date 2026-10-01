import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/ads_controller.dart';
import '../controllers/gallery_controller.dart';
import '../models/wallpaper.dart';
import '../screens/wallpaper_detail_screen.dart';
import '../theme/app_theme.dart';
import 'wallpaper_image.dart';

Future<void> openExternalLink(BuildContext context, String url) async {
  try {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open this link on your device.'),
        ),
      );
    }
  } on PlatformException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The browser is unavailable. Try again.')),
      );
    }
  }
}

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xAA191820),
      foregroundColor: selected ? AppColors.violet : Colors.white,
      minimumSize: const Size(48, 48),
      side: const BorderSide(color: Colors.white12),
    ),
    icon: Icon(icon, size: 21),
  );
}

class FavoriteButton extends GetView<GalleryController> {
  const FavoriteButton({super.key, required this.photo});
  final Wallpaper photo;

  @override
  Widget build(BuildContext context) => Obx(() {
    final saved = controller.isFavorite(photo);
    return RoundButton(
      icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      tooltip: saved ? 'Remove from saved' : 'Save wallpaper',
      selected: saved,
      onPressed: controller.isSaving.value
          ? null
          : () => controller.toggleFavorite(photo),
    );
  });
}

class WallpaperCard extends StatelessWidget {
  const WallpaperCard({super.key, required this.photo});
  final Wallpaper photo;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(23),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'wallpaper-${photo.id}',
          child: WallpaperImage(
            url: photo.imageUrl,
            color: Color(
              int.parse(photo.averageColor.substring(1), radix: 16) |
                  0xFF000000,
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.45, 1],
              colors: [Colors.transparent, Color(0xCE101016)],
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Get.find<AdsController>().onWallpaperOpened();
              Get.to<void>(() => WallpaperDetailScreen(photo: photo));
            },
            child: Semantics(
              button: true,
              label: 'Preview ${photo.title}',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.title.split(' · ').first,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        photo.photographer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(top: 10, right: 10, child: FavoriteButton(photo: photo)),
      ],
    ),
  );
}

class GalleryMessage extends StatelessWidget {
  const GalleryMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
    child: Column(
      children: [
        Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 18),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 22),
          FilledButton(onPressed: onAction, child: Text(action!)),
        ],
      ],
    ),
  );
}
