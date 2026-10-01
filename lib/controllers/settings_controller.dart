import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auto_wallpaper_scheduler.dart';

class SettingsController extends GetxController {
  SettingsController(this.preferences, {AutoWallpaperScheduler? scheduler})
    : scheduler = scheduler ?? AutoWallpaperScheduler() {
    final storedTheme = preferences.getString(themeKey);
    themeMode.value = ThemeMode.values.firstWhere(
      (mode) => mode.name == storedTheme,
      orElse: () => ThemeMode.dark,
    );
    wifiOnly.value = preferences.getBool(wifiKey) ?? false;
    autoChangeEnabled.value = preferences.getBool(autoChangeKey) ?? false;
    autoChangeHours.value = preferences.getInt(autoChangeHoursKey) ?? 24;
    autoChangeTarget.value =
        preferences.getString(autoChangeTargetKey) ?? 'both';
  }

  static const themeKey = 'walltastic.settings.theme';
  static const wifiKey = 'walltastic.settings.wifiOnly';
  static const autoChangeKey = 'walltastic.settings.autoChange';
  static const autoChangeHoursKey = 'walltastic.settings.autoChangeHours';
  static const autoChangeTargetKey = 'walltastic.settings.autoChangeTarget';
  final SharedPreferences preferences;
  final AutoWallpaperScheduler scheduler;
  final themeMode = ThemeMode.dark.obs;
  final wifiOnly = false.obs;
  final autoChangeEnabled = false.obs;
  final autoChangeHours = 24.obs;
  final autoChangeTarget = 'both'.obs;
  final isSaving = false.obs;
  final error = ''.obs;

  bool get autoChangeSupported => scheduler.isSupported;

  Future<void> setTheme(ThemeMode mode) => _save(
    () => preferences.setString(themeKey, mode.name),
    () => themeMode.value = mode,
  );

  Future<void> setWifiOnly(bool enabled) => _save(
    () => preferences.setBool(wifiKey, enabled),
    () => wifiOnly.value = enabled,
  );

  Future<void> setAutoChangeEnabled(bool enabled) =>
      _save(() => preferences.setBool(autoChangeKey, enabled), () {
        autoChangeEnabled.value = enabled;
        _syncSchedule();
      });

  Future<void> setAutoChangeHours(int hours) =>
      _save(() => preferences.setInt(autoChangeHoursKey, hours), () {
        autoChangeHours.value = hours;
        _syncSchedule();
      });

  Future<void> setAutoChangeTarget(String target) =>
      _save(() => preferences.setString(autoChangeTargetKey, target), () {
        autoChangeTarget.value = target;
        _syncSchedule();
      });

  Future<void> _syncSchedule() async {
    try {
      if (autoChangeEnabled.value) {
        await scheduler.schedule(
          hours: autoChangeHours.value,
          target: autoChangeTarget.value,
        );
      } else {
        await scheduler.cancel();
      }
    } on PlatformException {
      error.value =
          'Could not update the wallpaper schedule. Please try again.';
    }
  }

  Future<void> _save(
    Future<bool> Function() persist,
    VoidCallback apply,
  ) async {
    if (isSaving.value) return;
    isSaving.value = true;
    error.value = '';
    try {
      if (await persist()) {
        apply();
      } else {
        error.value = 'Could not save your settings. Please try again.';
      }
    } on PlatformException {
      error.value = 'Device storage is unavailable. Please try again.';
    } finally {
      isSaving.value = false;
    }
  }
}
