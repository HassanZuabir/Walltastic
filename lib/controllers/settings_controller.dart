import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  SettingsController(this.preferences) {
    final storedTheme = preferences.getString(themeKey);
    themeMode.value = ThemeMode.values.firstWhere(
      (mode) => mode.name == storedTheme,
      orElse: () => ThemeMode.dark,
    );
    wifiOnly.value = preferences.getBool(wifiKey) ?? false;
  }

  static const themeKey = 'walltastic.settings.theme';
  static const wifiKey = 'walltastic.settings.wifiOnly';
  final SharedPreferences preferences;
  final themeMode = ThemeMode.dark.obs;
  final wifiOnly = false.obs;
  final isSaving = false.obs;
  final error = ''.obs;

  Future<void> setTheme(ThemeMode mode) => _save(
    () => preferences.setString(themeKey, mode.name),
    () => themeMode.value = mode,
  );

  Future<void> setWifiOnly(bool enabled) => _save(
    () => preferences.setBool(wifiKey, enabled),
    () => wifiOnly.value = enabled,
  );

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
