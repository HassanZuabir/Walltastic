import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/wallpaper.dart';

class FavoritesStore {
  FavoritesStore(this.preferences);

  static const storageKey = 'walltastic.favorites.v1';
  final SharedPreferences preferences;

  List<Wallpaper> read() {
    final raw = preferences.getString(storageKey);
    if (raw == null) return [];
    final data = jsonDecode(raw);
    if (data is! List) {
      throw const FormatException('Invalid saved wallpapers.');
    }
    return data
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Invalid saved wallpaper.');
          }
          return Wallpaper.fromJson(item);
        })
        .where((photo) {
          // Exclude bookmarks created by the retired demo gallery, not real saves.
          return !(photo.width == 0 &&
              photo.height == 0 &&
              photo.photographer == 'View photographer on Pexels');
        })
        .toList();
  }

  Future<bool> write(List<Wallpaper> wallpapers) => preferences.setString(
    storageKey,
    jsonEncode(wallpapers.map((photo) => photo.toJson()).toList()),
  );
}
