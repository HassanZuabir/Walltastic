import 'dart:developer' as developer;

import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

class AdsController extends GetxController {
  InterstitialAd? _interstitial;
  int _detailOpens = 0;
  DateTime? _lastInterstitialShown;
  final adsInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (!AdConfig.adsEnabled) return;
    MobileAds.instance.initialize().then((_) {
      adsInitialized.value = true;
      _loadInterstitial();
    });
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          _interstitial = null;
          developer.log(
            'Interstitial failed to load: ${error.message}',
            name: 'Walltastic.Ads',
          );
        },
      ),
    );
  }

  /// Call when a wallpaper detail screen is opened. Shows an interstitial
  /// every [AdConfig.interstitialFrequency] opens, respecting the cooldown.
  void onWallpaperOpened() {
    if (!AdConfig.adsEnabled) return;
    _detailOpens++;
    if (_detailOpens % AdConfig.interstitialFrequency != 0) return;
    final last = _lastInterstitialShown;
    if (last != null &&
        DateTime.now().difference(last) < AdConfig.interstitialCooldown) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    _lastInterstitialShown = DateTime.now();
    ad.show();
  }

  @override
  void onClose() {
    _interstitial?.dispose();
    super.onClose();
  }
}
