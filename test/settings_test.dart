import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walltastic/app.dart';
import 'package:walltastic/controllers/gallery_controller.dart';
import 'package:walltastic/controllers/settings_controller.dart';
import 'package:walltastic/data/favorites_store.dart';
import 'package:walltastic/screens/gallery_screen.dart';
import 'package:walltastic/screens/settings_screen.dart';

import 'fixtures/wallpaper_fixtures.dart';

void main() {
  late SettingsController settings;
  late SharedPreferences preferences;

  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    settings = Get.put(SettingsController(preferences), permanent: true);
    final gallery = Get.put(
      GalleryController(
        repository: FakeWallpaperRepository(),
        favoritesStore: FavoritesStore(preferences),
      ),
      permanent: true,
    );
    await gallery.load();
  });

  tearDown(() => Get.reset());

  test('Defaults preserve dark theme and unrestricted downloads', () {
    expect(settings.themeMode.value, ThemeMode.dark);
    expect(settings.wifiOnly.value, isFalse);
  });

  test('Settings survive controller recreation', () async {
    await settings.setTheme(ThemeMode.system);
    await settings.setWifiOnly(true);
    final restored = SettingsController(preferences);
    expect(restored.themeMode.value, ThemeMode.system);
    expect(restored.wifiOnly.value, isTrue);
  });

  testWidgets(
    'Settings gear, appearance, Wi-Fi toggle and back navigation work',
    (tester) async {
      await tester.pumpWidget(const WalltasticApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(settings.themeMode.value, ThemeMode.light);
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.light,
      );
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark,
      );
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.light,
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark,
      );
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(settings.wifiOnly.value, isTrue);
      expect(preferences.getBool(SettingsController.wifiKey), isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(GalleryScreen), findsOneWidget);
    },
  );

  testWidgets('About opens the bundled open-source license page', (
    tester,
  ) async {
    await tester.pumpWidget(const WalltasticApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Open-source licenses').hitTestable(),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Open-source licenses'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('Light gallery and large-text settings fit a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await settings.setTheme(ThemeMode.light);
    await tester.pumpWidget(const WalltasticApp());
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(GalleryScreen))).brightness,
      Brightness.light,
    );
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Open-source licenses').hitTestable(),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  });
}
