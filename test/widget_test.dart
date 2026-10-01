import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walltastic/app.dart';
import 'package:walltastic/controllers/download_controller.dart';
import 'package:walltastic/controllers/gallery_controller.dart';
import 'package:walltastic/controllers/settings_controller.dart';
import 'package:walltastic/data/favorites_store.dart';
import 'package:walltastic/data/wallpaper_download_service.dart';
import 'package:walltastic/data/wallpaper_repository.dart';
import 'package:walltastic/models/wallpaper.dart';
import 'package:walltastic/screens/wallpaper_viewer_screen.dart';
import 'package:walltastic/widgets/gallery_widgets.dart';
import 'package:walltastic/widgets/wallpaper_image.dart';

import 'fixtures/wallpaper_fixtures.dart';

class FakeDownloadService extends WallpaperDownloadService {
  FakeDownloadService() : super(gallerySaver: DeviceGallerySaver());
  int downloads = 0;

  @override
  Future<void> download(
    Wallpaper photo, {
    required void Function(double? progress) onProgress,
    required VoidCallback onSaving,
  }) async {
    downloads++;
    onProgress(0.5);
    onSaving();
  }
}

void main() {
  late GalleryController controller;
  late FakeDownloadService downloads;

  setUp(() async {
    Get.testMode = true;
    downloads = FakeDownloadService();
    Get.put(DownloadController(downloads));
    SharedPreferences.setMockInitialValues({});
    Get.put(SettingsController(await SharedPreferences.getInstance()));
    controller = Get.put(
      GalleryController(
        repository: FakeWallpaperRepository(),
        favoritesStore: FavoritesStore(await SharedPreferences.getInstance()),
      ),
    );
    await controller.load();
  });

  tearDown(() => Get.reset());

  testWidgets('Discovery, categories and saved navigation work', (
    tester,
  ) async {
    await tester.pumpWidget(const WalltasticApp());
    await tester.pumpAndSettle();

    expect(find.text('walltastic'), findsOneWidget);
    expect(find.textContaining('Sample gallery'), findsNothing);
    expect(find.text('FEATURED WALLPAPER'), findsOneWidget);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('A world of possibility.'), findsOneWidget);
    await tester.tap(find.text('Nature'));
    await tester.pumpAndSettle();
    expect(controller.query.value, 'Nature');
    expect(controller.photos.length, 1);

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Keep what inspires you.'), findsOneWidget);
    await tester.tap(find.text('Find your first favorite'));
    await tester.pumpAndSettle();
    expect(controller.selectedTab.value, 0);
    expect(controller.photos.length, testWallpapers.length);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search, empty state and reset work', (tester) async {
    await tester.pumpWidget(const WalltasticApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'not-a-photo');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(controller.query.value, 'not-a-photo');
    expect(controller.photos, isEmpty);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.text('No views found.'), findsOneWidget);
    await tester.tap(find.text('Explore all'));
    await tester.pumpAndSettle();
    expect(controller.query.value, isEmpty);
    expect(controller.photos.length, testWallpapers.length);
  });

  testWidgets('Save, preview and unsave a wallpaper', (tester) async {
    await controller.toggleFavorite(testWallpapers.first);
    controller.selectedTab.value = 2;
    await tester.pumpWidget(const WalltasticApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(WallpaperCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Download wallpaper'), findsOneWidget);
    expect(find.text('View full image'), findsOneWidget);
    await tester.tap(find.text('Download wallpaper'));
    await tester.pumpAndSettle();
    expect(downloads.downloads, 1);
    expect(find.text('Saved to your Photos / Gallery.'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove from saved'));
    await tester.pumpAndSettle();
    expect(controller.favorites, isEmpty);
    await tester.tap(find.byTooltip('Back to gallery'));
    await tester.pumpAndSettle();
    expect(find.text('Keep what inspires you.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Original image opens in-app with zoom and download controls', (
    tester,
  ) async {
    await controller.toggleFavorite(testWallpapers.first);
    controller.selectedTab.value = 2;
    await tester.pumpWidget(const WalltasticApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(WallpaperCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View full image'));
    await tester.pumpAndSettle();
    expect(find.byType(WallpaperViewerScreen), findsOneWidget);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.maxScale, greaterThan(1));
    final image = tester.widget<WallpaperImage>(
      find.descendant(
        of: find.byType(WallpaperViewerScreen),
        matching: find.byType(WallpaperImage),
      ),
    );
    expect(image.url, testWallpapers.first.originalUrl);
    expect(image.fit, BoxFit.contain);
    expect(image.onRetry, isNotNull);
    viewer.transformationController!.value = Matrix4.diagonal3Values(2, 2, 1);
    await tester.tap(find.byTooltip('Reset zoom'));
    await tester.pump();
    expect(viewer.transformationController!.value, Matrix4.identity());
    await tester.tap(find.text('Download wallpaper'));
    await tester.pumpAndSettle();
    expect(downloads.downloads, 1);
    expect(find.text('Saved to your Photos / Gallery.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Saved to your Photos / Gallery.'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 700),
    const Size(1100, 800),
    const Size(740, 360),
  ]) {
    testWidgets('Gallery fits ${size.width} x ${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const WalltasticApp());
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
    });

    testWidgets('Original viewer fits ${size.width} x ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        GetMaterialApp(
          home: WallpaperViewerScreen(photo: testWallpapers.first),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Download wallpaper'), findsOneWidget);
    });
  }

  testWidgets('Discovery supports large accessibility text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const WalltasticApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'Unconfigured app displays no wallpapers or developer setup prompts',
    (tester) async {
      await Get.delete<GalleryController>();
      controller = Get.put(
        GalleryController(
          repository: PexelsWallpaperRepository(
            client: MockClient((_) async {
              fail('Missing API key must not cause a network request.');
            }),
            apiKey: '',
          ),
          favoritesStore: FavoritesStore(await SharedPreferences.getInstance()),
        ),
      );
      await controller.load();
      await tester.pumpWidget(const WalltasticApp());
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Wallpapers are temporarily unavailable'),
        findsOneWidget,
      );
      expect(find.byType(WallpaperCard), findsNothing);
      expect(find.byType(WallpaperImage), findsNothing);
      expect(find.text('FEATURED WALLPAPER'), findsNothing);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(controller.photos, isEmpty);

      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();
      expect(find.byType(WallpaperImage), findsNothing);
      await tester.tap(find.text('Nature'));
      await tester.pumpAndSettle();
      expect(controller.photos, isEmpty);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Pexels photo license'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Pexels photo license'), findsOneWidget);
      expect(find.textContaining('API setup'), findsNothing);
      expect(find.textContaining('PEXELS_API_KEY'), findsNothing);
      expect(find.textContaining('sample'), findsNothing);
    },
  );
}
