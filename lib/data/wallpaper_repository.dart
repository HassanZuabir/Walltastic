import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../models/wallpaper.dart';

class WallpaperPage {
  const WallpaperPage(this.photos, {required this.hasMore});

  final List<Wallpaper> photos;
  final bool hasMore;
}

class GalleryException implements Exception {
  const GalleryException(this.message);
  final String message;
}

abstract class WallpaperRepository {
  Future<WallpaperPage> fetch({
    String query = '',
    String color = '',
    int page = 1,
  });
  void close() {}
}

class PexelsWallpaperRepository extends WallpaperRepository {
  PexelsWallpaperRepository({required this.client, required this.apiKey});

  final http.Client client;
  final String apiKey;

  @override
  Future<WallpaperPage> fetch({
    String query = '',
    String color = '',
    int page = 1,
  }) async {
    if (apiKey.trim().isEmpty) {
      developer.log(
        'PEXELS_API_KEY is missing from the app configuration.',
        name: 'Walltastic.Pexels',
      );
      throw const GalleryException(
        'Wallpapers are temporarily unavailable. Please try again later.',
      );
    }
    var search = query.trim();
    final tint = color.trim();
    // The color filter only works on search, so fall back to a broad query.
    if (search.isEmpty && tint.isNotEmpty) search = 'wallpaper';
    final uri = Uri.https(
      'api.pexels.com',
      search.isEmpty ? '/v1/curated' : '/v1/search',
      {
        'per_page': '24',
        'page': '$page',
        if (search.isNotEmpty) ...{'query': search, 'orientation': 'portrait'},
        if (search.isNotEmpty && tint.isNotEmpty) 'color': tint,
      },
    );
    try {
      final response = await client
          .get(uri, headers: {'Authorization': apiKey.trim()})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const GalleryException(
          'Wallpapers are temporarily unavailable. Please try again later.',
        );
      }
      if (response.statusCode == 429) {
        throw const GalleryException(
          'The Pexels request limit has been reached. Please try again later.',
        );
      }
      if (response.statusCode != 200) {
        throw const GalleryException(
          'Pexels is unavailable right now. Please try again.',
        );
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['photos'] is! List) {
        throw const FormatException('Invalid Pexels response.');
      }
      final photos = <Wallpaper>[];
      for (final photo in data['photos'] as List) {
        if (photo is! Map<String, dynamic>) {
          throw const FormatException('Invalid Pexels photo.');
        }
        photos.add(Wallpaper.fromJson(photo));
      }
      return WallpaperPage(photos, hasMore: data['next_page'] is String);
    } on TimeoutException {
      throw const GalleryException(
        'The connection took too long. Please try again.',
      );
    } on http.ClientException {
      throw const GalleryException(
        'Could not connect to Pexels. Check your internet connection.',
      );
    } on FormatException {
      throw const GalleryException(
        'Pexels returned an unexpected response. Please try again.',
      );
    }
  }

  @override
  void close() => client.close();
}
