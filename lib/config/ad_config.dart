import 'dart:io';

import 'package:flutter/foundation.dart';

/// AdMob unit IDs.
///
/// Google's official test IDs are used in debug builds. Before release,
/// create your ad units in the AdMob console and pass the real IDs with
/// --dart-define (or replace the release values below).
abstract final class AdConfig {
  /// Master switch — set to false to hide all ads (e.g. for screenshots).
  static const bool adsEnabled = true;

  static const _androidBannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';
  static const _androidInterstitialTest =
      'ca-app-pub-3940256099942544/1033173712';
  static const _iosInterstitialTest = 'ca-app-pub-3940256099942544/4411468910';

  static const _androidBannerRelease = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: 'ca-app-pub-7328244770178820/5064995468',
  );
  static const _iosBannerRelease = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
  );
  static const _androidInterstitialRelease = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-7328244770178820/7499587112',
  );
  static const _iosInterstitialRelease = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
  );

  static bool get _useTestIds =>
      kDebugMode ||
      (Platform.isAndroid
          ? _androidBannerRelease.isEmpty
          : _iosBannerRelease.isEmpty);

  static String get bannerUnitId => Platform.isAndroid
      ? (_useTestIds ? _androidBannerTest : _androidBannerRelease)
      : (_useTestIds ? _iosBannerTest : _iosBannerRelease);

  static String get interstitialUnitId => Platform.isAndroid
      ? (_useTestIds ? _androidInterstitialTest : _androidInterstitialRelease)
      : (_useTestIds ? _iosInterstitialTest : _iosInterstitialRelease);

  /// Show an interstitial once per this many wallpaper detail opens.
  static const int interstitialFrequency = 4;

  /// Minimum gap between two interstitials.
  static const Duration interstitialCooldown = Duration(minutes: 2);
}
