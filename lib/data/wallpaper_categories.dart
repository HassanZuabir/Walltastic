import 'package:flutter/material.dart';

class WallpaperCategory {
  const WallpaperCategory(
    this.name,
    this.subtitle,
    this.icon,
    this.color, {
    this.searchQuery,
    this.colorFilter = '',
  });

  final String name;
  final String subtitle;
  final IconData icon;
  final int color;

  /// Pexels query used when the category is selected. Defaults to [name].
  final String? searchQuery;

  /// Optional Pexels color filter applied alongside the query.
  final String colorFilter;

  String get query => searchQuery ?? name;
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
  WallpaperCategory(
    'AMOLED',
    'Deep blacks, pure battery',
    Icons.dark_mode_outlined,
    0xFF26243A,
    searchQuery: 'dark black background',
    colorFilter: 'black',
  ),
];

/// Pexels-supported color filters for browsing by color.
class BrowseColor {
  const BrowseColor(this.name, this.value, this.swatch);

  final String name;
  final String value;
  final int swatch;
}

const browseColors = [
  BrowseColor('Red', 'red', 0xFFE5484D),
  BrowseColor('Orange', 'orange', 0xFFF76B15),
  BrowseColor('Yellow', 'yellow', 0xFFF5D90A),
  BrowseColor('Green', 'green', 0xFF46A758),
  BrowseColor('Turquoise', 'turquoise', 0xFF12A594),
  BrowseColor('Blue', 'blue', 0xFF3E63DD),
  BrowseColor('Violet', 'violet', 0xFF8963DB),
  BrowseColor('Pink', 'pink', 0xFFD6409F),
  BrowseColor('Brown', 'brown', 0xFF8D6E52),
  BrowseColor('Black', 'black', 0xFF18181C),
  BrowseColor('Gray', 'gray', 0xFF7E808A),
  BrowseColor('White', 'white', 0xFFF2F2F5),
];
