import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../data/favorites_store.dart';
import '../data/wallpaper_repository.dart';
import '../models/wallpaper.dart';

class GalleryController extends GetxController {
  GalleryController({required this.repository, required this.favoritesStore});

  final WallpaperRepository repository;
  final FavoritesStore favoritesStore;
  final photos = <Wallpaper>[].obs;
  final favorites = <Wallpaper>[].obs;
  final selectedTab = 0.obs;
  final query = ''.obs;
  final selectedCategory = 'All'.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = false.obs;
  final error = ''.obs;
  final storageError = ''.obs;
  final isSaving = false.obs;
  int _generation = 0;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    try {
      favorites.assignAll(favoritesStore.read());
    } on FormatException {
      storageError.value = 'Saved wallpapers could not be read on this device.';
    }
    load();
  }

  Future<void> search(String value) {
    query.value = value.trim();
    selectedCategory.value = 'All';
    selectedTab.value = 0;
    return load();
  }

  Future<void> selectCategory(String category) {
    selectedCategory.value = category;
    query.value = category == 'All' ? '' : category;
    selectedTab.value = 0;
    return load();
  }

  Future<void> load() async {
    final generation = ++_generation;
    isLoading.value = true;
    isLoadingMore.value = false;
    error.value = '';
    hasMore.value = false;
    photos.clear();
    _page = 1;
    try {
      final result = await repository.fetch(query: query.value);
      if (generation != _generation || isClosed) return;
      photos.assignAll(result.photos);
      hasMore.value = result.hasMore;
    } on GalleryException catch (exception) {
      if (generation == _generation && !isClosed) {
        error.value = exception.message;
      }
    } finally {
      if (generation == _generation && !isClosed) isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;
    final generation = _generation;
    isLoadingMore.value = true;
    error.value = '';
    try {
      final result = await repository.fetch(
        query: query.value,
        page: _page + 1,
      );
      if (generation != _generation || isClosed) return;
      final ids = photos.map((photo) => photo.id).toSet();
      photos.addAll(result.photos.where((photo) => ids.add(photo.id)));
      _page++;
      hasMore.value = result.hasMore;
    } on GalleryException catch (exception) {
      if (generation == _generation && !isClosed) {
        error.value = exception.message;
      }
    } finally {
      if (generation == _generation && !isClosed) isLoadingMore.value = false;
    }
  }

  bool isFavorite(Wallpaper photo) =>
      favorites.any((favorite) => favorite.id == photo.id);

  Future<void> toggleFavorite(Wallpaper photo) async {
    if (isSaving.value) return;
    isSaving.value = true;
    storageError.value = '';
    final updated = favorites.toList();
    if (isFavorite(photo)) {
      updated.removeWhere((favorite) => favorite.id == photo.id);
    } else {
      updated.insert(0, photo);
    }
    try {
      if (await favoritesStore.write(updated)) {
        favorites.assignAll(updated);
      } else {
        storageError.value = 'Could not save your changes. Please try again.';
      }
    } on PlatformException {
      storageError.value = 'Device storage is unavailable. Please try again.';
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    _generation++;
    repository.close();
    super.onClose();
  }
}
