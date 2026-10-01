import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walltastic/controllers/download_controller.dart';
import 'package:walltastic/controllers/gallery_controller.dart';
import 'package:walltastic/data/favorites_store.dart';
import 'package:walltastic/data/wallpaper_download_service.dart';
import 'package:walltastic/screens/wallpaper_detail_screen.dart';
import 'package:walltastic/theme/app_theme.dart';
import 'package:walltastic/widgets/download_button.dart';
import 'package:walltastic/widgets/wallpaper_image.dart';

import 'fixtures/wallpaper_fixtures.dart';

double contrast(Color foreground, Color background) {
  final first = Color.alphaBlend(foreground, background).computeLuminance();
  final second = background.computeLuminance();
  return (math.max(first, second) + 0.05) / (math.min(first, second) + 0.05);
}

void main() {
  final light = buildAppTheme(brightness: Brightness.light);

  test(
    'Light text roles and controls meet readable contrast on their surfaces',
    () {
      final scheme = light.colorScheme;
      for (final style in [
        light.textTheme.headlineLarge,
        light.textTheme.headlineMedium,
        light.textTheme.titleLarge,
        light.textTheme.bodyMedium,
      ]) {
        expect(style?.color, isNotNull);
        expect(
          contrast(style!.color!, light.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
      }
      for (final surface in [scheme.surface, light.scaffoldBackgroundColor]) {
        expect(
          contrast(scheme.onSurfaceVariant, surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(scheme.primary, surface), greaterThanOrEqualTo(4.5));
      }
      expect(
        contrast(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(scheme.onSecondaryContainer, scheme.secondaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      for (final selected in [false, true]) {
        final style = light.navigationBarTheme.labelTextStyle!.resolve(
          selected ? {WidgetState.selected} : {},
        )!;
        expect(
          contrast(style.color!, light.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );

  test('Dark palette and existing typography are preserved', () {
    final dark = buildAppTheme();
    expect(dark.scaffoldBackgroundColor, AppColors.background);
    expect(dark.colorScheme.primary, AppColors.violet);
    expect(dark.colorScheme.surface, AppColors.surface);
    expect(dark.colorScheme.onSurfaceVariant, AppColors.muted);
    expect(dark.textTheme.headlineLarge!.fontSize, 38);
    expect(dark.textTheme.headlineLarge!.color, isNull);
    expect(dark.navigationBarTheme.labelTextStyle, isNull);
  });

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    Get.put(
      GalleryController(
        repository: FakeWallpaperRepository(),
        favoritesStore: FavoritesStore(await SharedPreferences.getInstance()),
      ),
    );
    Get.put(
      DownloadController(
        WallpaperDownloadService(gallerySaver: DeviceGallerySaver()),
      ),
    );
  });

  tearDown(() => Get.reset());

  testWidgets('Download success uses the readable light accent', (
    tester,
  ) async {
    final photo = testWallpapers.first;
    Get.find<DownloadController>().states[photo.id] = const DownloadState(
      phase: DownloadPhase.saved,
      message: 'Saved to your Photos / Gallery.',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: light,
        home: Scaffold(body: DownloadButton(photo: photo)),
      ),
    );
    final text = tester.widget<Text>(
      find.text('Saved to your Photos / Gallery.'),
    );
    expect(text.style!.color, light.colorScheme.primary);
    expect(
      contrast(text.style!.color!, light.scaffoldBackgroundColor),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets(
    'Light wallpaper details use a solid readable information panel',
    (tester) async {
      final photo = testWallpapers.first;
      await tester.pumpWidget(
        GetMaterialApp(
          theme: light,
          home: WallpaperDetailScreen(photo: photo),
        ),
      );
      await tester.pumpAndSettle();
      final title = tester.widget<Text>(find.text(photo.title));
      expect(title.style!.color, light.colorScheme.onSurface);
      final panels = tester.widgetList<Container>(
        find.ancestor(
          of: find.text(photo.title),
          matching: find.byType(Container),
        ),
      );
      expect(
        panels.any(
          (panel) =>
              panel.decoration is BoxDecoration &&
              (panel.decoration! as BoxDecoration).color ==
                  light.colorScheme.surface,
        ),
        isTrue,
      );
      await tester.ensureVisible(find.text('View full image'));
      expect(find.text('View full image').hitTestable(), findsOneWidget);
    },
  );

  testWidgets('Light image error has a readable retry action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: light,
        home: Scaffold(
          body: WallpaperImage(
            url: 'https://example.com/missing.jpg',
            onRetry: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    await tester.pumpWidget(
      MaterialApp(
        theme: light,
        home: Scaffold(
          body: Builder(
            builder: (context) => image.errorBuilder!(
              context,
              Exception('offline'),
              StackTrace.current,
            ),
          ),
        ),
      ),
    );
    final retry = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Retry image'),
    );
    expect(
      contrast(
        retry.style!.foregroundColor!.resolve({})!,
        light.colorScheme.surfaceContainerLow,
      ),
      greaterThanOrEqualTo(4.5),
    );
  });
}
