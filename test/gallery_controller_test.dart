import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walltastic/controllers/gallery_controller.dart';
import 'package:walltastic/data/favorites_store.dart';
import 'package:walltastic/data/wallpaper_repository.dart';

import 'fixtures/wallpaper_fixtures.dart';

class ControlledRepository extends WallpaperRepository {
  final requests =
      <({String query, int page, Completer<WallpaperPage> result})>[];

  @override
  Future<WallpaperPage> fetch({String query = '', int page = 1}) {
    final result = Completer<WallpaperPage>();
    requests.add((query: query, page: page, result: result));
    return result.future;
  }
}

void main() {
  late FavoritesStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = FavoritesStore(await SharedPreferences.getInstance());
  });

  test('Late responses do not replace the most recent search', () async {
    final repository = ControlledRepository();
    final controller = GalleryController(
      repository: repository,
      favoritesStore: store,
    );
    final first = controller.search('mountains');
    final second = controller.search('ocean');
    repository.requests[1].result.complete(
      WallpaperPage([testWallpapers[2]], hasMore: false),
    );
    await second;
    repository.requests[0].result.complete(
      WallpaperPage([testWallpapers[0]], hasMore: true),
    );
    await first;
    expect(controller.query.value, 'ocean');
    expect(controller.photos.single.id, testWallpapers[2].id);
    expect(controller.hasMore.value, isFalse);
    expect(controller.isLoading.value, isFalse);
    controller.onClose();
  });

  test('Pagination deduplicates and retries the same failed page', () async {
    final repository = ControlledRepository();
    final controller = GalleryController(
      repository: repository,
      favoritesStore: store,
    );
    final initial = controller.load();
    repository.requests.last.result.complete(
      WallpaperPage([testWallpapers[0]], hasMore: true),
    );
    await initial;
    final failed = controller.loadMore();
    repository.requests.last.result.completeError(
      const GalleryException('Connection unavailable'),
    );
    await failed;
    expect(controller.photos, hasLength(1));
    expect(controller.error.value, 'Connection unavailable');
    final retry = controller.loadMore();
    expect(repository.requests.last.page, 2);
    repository.requests.last.result.complete(
      WallpaperPage(testWallpapers.take(2).toList(), hasMore: false),
    );
    await retry;
    expect(controller.photos, hasLength(2));
    expect(controller.error.value, isEmpty);
    expect(controller.isLoadingMore.value, isFalse);
    controller.onClose();
  });

  test('Old pagination cannot append to a new search', () async {
    final repository = ControlledRepository();
    final controller = GalleryController(
      repository: repository,
      favoritesStore: store,
    );
    final initial = controller.load();
    repository.requests.last.result.complete(
      WallpaperPage([testWallpapers[0]], hasMore: true),
    );
    await initial;
    final pagination = controller.loadMore();
    final search = controller.search('ocean');
    repository.requests[2].result.complete(
      WallpaperPage([testWallpapers[2]], hasMore: false),
    );
    await search;
    repository.requests[1].result.complete(
      WallpaperPage([testWallpapers[1]], hasMore: true),
    );
    await pagination;
    expect(controller.photos.single.id, testWallpapers[2].id);
    expect(controller.hasMore.value, isFalse);
    controller.onClose();
  });

  test('Favorites persist and can be removed', () async {
    final controller = GalleryController(
      repository: FakeWallpaperRepository(),
      favoritesStore: store,
    );
    final photo = testWallpapers.first;
    await controller.toggleFavorite(photo);
    expect(controller.isFavorite(photo), isTrue);
    expect(store.read().single.id, photo.id);
    await controller.toggleFavorite(photo);
    expect(controller.favorites, isEmpty);
    expect(store.read(), isEmpty);
    controller.onClose();
  });

  test(
    'Corrupt favorite data is reported rather than overwritten on startup',
    () async {
      await store.preferences.setString(
        FavoritesStore.storageKey,
        'invalid data',
      );
      final controller = GalleryController(
        repository: FakeWallpaperRepository(),
        favoritesStore: store,
      );
      controller.onInit();
      await controller.load();
      expect(controller.storageError.value, isNotEmpty);
      expect(
        store.preferences.getString(FavoritesStore.storageKey),
        'invalid data',
      );
      controller.onClose();
    },
  );

  test(
    'Legacy demo bookmarks are hidden without removing real favorites',
    () async {
      final legacy = testWallpapers.first.toJson()
        ..['width'] = 0
        ..['height'] = 0
        ..['photographer'] = 'View photographer on Pexels';
      await store.preferences.setString(
        FavoritesStore.storageKey,
        jsonEncode([legacy, testWallpapers[1].toJson()]),
      );
      final controller = GalleryController(
        repository: FakeWallpaperRepository(),
        favoritesStore: store,
      );
      controller.onInit();
      await controller.load();
      expect(controller.favorites.single.id, testWallpapers[1].id);
      expect(controller.storageError.value, isEmpty);
      controller.onClose();
    },
  );
}
