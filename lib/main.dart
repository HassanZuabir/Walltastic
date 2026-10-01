import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'controllers/ads_controller.dart';
import 'controllers/download_controller.dart';
import 'controllers/gallery_controller.dart';
import 'controllers/settings_controller.dart';
import 'data/download_network_policy.dart';
import 'data/favorites_store.dart';
import 'data/wallpaper_download_service.dart';
import 'data/wallpaper_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final settings = Get.put(SettingsController(preferences), permanent: true);
  Get.put(AdsController(), permanent: true);
  final connectivity = Connectivity();
  Get.put(
    DownloadController(
      WallpaperDownloadService(
        gallerySaver: DeviceGallerySaver(),
        networkPolicy: DownloadNetworkPolicy(
          wifiOnly: () => settings.wifiOnly.value,
          checkConnectivity: connectivity.checkConnectivity,
          changes: connectivity.onConnectivityChanged,
        ),
      ),
    ),
    permanent: true,
  );
  Get.put(
    GalleryController(
      repository: PexelsWallpaperRepository(
        client: http.Client(),
        apiKey: AppConfig.pexelsApiKey,
      ),
      favoritesStore: FavoritesStore(preferences),
    ),
  );
  runApp(const WalltasticApp());
}
