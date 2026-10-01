import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walltastic/data/wallpaper_repository.dart';
import 'package:walltastic/models/wallpaper.dart';

import 'fixtures/wallpaper_fixtures.dart';

void main() {
  test('Curated feed authenticates and parses pagination', () async {
    final repository = PexelsWallpaperRepository(
      apiKey: 'test-key',
      client: MockClient((request) async {
        expect(request.url.path, '/v1/curated');
        expect(request.url.queryParameters['page'], '2');
        expect(request.headers['Authorization'], 'test-key');
        return http.Response(
          jsonEncode({
            'photos': [testWallpapers.first.toJson()],
            'next_page': 'https://api.pexels.com/v1/curated?page=3',
          }),
          200,
        );
      }),
    );
    final result = await repository.fetch(page: 2);
    expect(result.photos.single.id, testWallpapers.first.id);
    expect(result.hasMore, isTrue);
    repository.close();
  });

  test('Search safely encodes terms and requests portrait photos', () async {
    final repository = PexelsWallpaperRepository(
      apiKey: 'test-key',
      client: MockClient((request) async {
        expect(request.url.path, '/v1/search');
        expect(request.url.queryParameters['query'], 'sea & sky');
        expect(request.url.queryParameters['orientation'], 'portrait');
        return http.Response('{"photos":[]}', 200);
      }),
    );
    final result = await repository.fetch(query: ' sea & sky ');
    expect(result.photos, isEmpty);
    expect(result.hasMore, isFalse);
    repository.close();
  });

  for (final status in [401, 403, 429, 500]) {
    test('HTTP $status produces an actionable gallery error', () async {
      final repository = PexelsWallpaperRepository(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('', status)),
      );
      await expectLater(repository.fetch(), throwsA(isA<GalleryException>()));
      repository.close();
    });
  }

  for (final body in ['not json', '{}', '{"photos":[{}]}']) {
    test('Malformed response $body becomes a gallery error', () async {
      final repository = PexelsWallpaperRepository(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(repository.fetch(), throwsA(isA<GalleryException>()));
      repository.close();
    });
  }

  test('Connection failure becomes a gallery error', () async {
    final repository = PexelsWallpaperRepository(
      apiKey: 'test-key',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(repository.fetch(), throwsA(isA<GalleryException>()));
    repository.close();
  });

  test('Wallpaper round trip preserves favorites data', () {
    final photo = testWallpapers.first;
    final restored = Wallpaper.fromJson(photo.toJson());
    expect(restored.toJson(), photo.toJson());
  });

  test('Wallpaper rejects non-HTTPS URLs', () {
    final data = testWallpapers.first.toJson()..['url'] = 'javascript:alert(1)';
    expect(() => Wallpaper.fromJson(data), throwsFormatException);
  });

  test(
    'Missing API key reports unavailable without requesting or seeding photos',
    () async {
      final repository = PexelsWallpaperRepository(
        apiKey: '  ',
        client: MockClient((_) async {
          fail('An unconfigured app must not send Pexels requests.');
        }),
      );
      await expectLater(
        repository.fetch(),
        throwsA(
          isA<GalleryException>().having(
            (error) => error.message,
            'message',
            'Wallpapers are temporarily unavailable. Please try again later.',
          ),
        ),
      );
      repository.close();
    },
  );
}
