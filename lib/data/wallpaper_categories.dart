import 'package:flutter/material.dart';

class WallpaperCategory {
  const WallpaperCategory(this.name, this.subtitle, this.icon, this.color);

  final String name;
  final String subtitle;
  final IconData icon;
  final int color;
}

const wallpaperCategories = [
  WallpaperCategory(
    'Nature',
    'A little closer to earth',
    Icons.forest_outlined,
    0xFF3E695B,
  ),
  WallpaperCategory(
    'Mountains',
    'Find your higher ground',
    Icons.landscape_outlined,
    0xFF666E8D,
  ),
  WallpaperCategory(
    'Ocean',
    'A moment of stillness',
    Icons.waves_rounded,
    0xFF346F89,
  ),
  WallpaperCategory(
    'Architecture',
    'Beauty in every line',
    Icons.apartment_rounded,
    0xFF9D775F,
  ),
  WallpaperCategory(
    'Space',
    'Beyond the everyday',
    Icons.auto_awesome_outlined,
    0xFF61517B,
  ),
  WallpaperCategory(
    'Minimal',
    'Less, but better',
    Icons.circle_outlined,
    0xFF938373,
  ),
];
