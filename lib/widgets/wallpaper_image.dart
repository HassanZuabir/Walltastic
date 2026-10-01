import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WallpaperImage extends StatelessWidget {
  const WallpaperImage({
    super.key,
    required this.url,
    this.color,
    this.fit = BoxFit.cover,
    this.onRetry,
  });

  final String url;
  final Color? color;
  final BoxFit fit;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final background =
        color ??
        (light ? theme.colorScheme.surfaceContainerLow : AppColors.surface);
    final foreground = background.computeLuminance() > 0.179
        ? const Color(0xFF231E30)
        : Colors.white;
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      excludeFromSemantics: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: background,
          child: Center(
            child: SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: light ? foreground : Colors.white38,
                value: progress.expectedTotalBytes == null
                    ? null
                    : progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: background,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.landscape_outlined,
                  color: light ? foreground : Colors.white38,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  'Image unavailable',
                  style: TextStyle(color: light ? foreground : Colors.white54),
                ),
                if (onRetry != null)
                  TextButton(
                    style: light
                        ? TextButton.styleFrom(foregroundColor: foreground)
                        : null,
                    onPressed: onRetry,
                    child: const Text('Retry image'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
