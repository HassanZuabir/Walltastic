import 'dart:io';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:walltastic/data/wallpaper_download_service.dart';
import 'package:walltastic/data/download_network_policy.dart';

import 'fixtures/wallpaper_fixtures.dart';

class FakeGallerySaver implements GallerySaver {
  bool allowed = true;
  GalException? failure;
  final saved = <List<int>>[];

  @override
  Future<bool> requestAccess() async => allowed;

  @override
  Future<void> save(String path) async {
    if (failure case final error?) throw error;
    expect(path, endsWith('.jpg'));
    saved.add(await File(path).readAsBytes());
  }
}

void main() {
  late Directory temporary;
  late FakeGallerySaver saver;
  final photo = testWallpapers.first;
  const imageBytes = [255, 216, 255, 224, 1, 2, 3, 255, 217];

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('walltastic-test-');
    saver = FakeGallerySaver();
  });

  tearDown(() async {
    expect(await temporary.list().toList(), isEmpty);
    await temporary.delete();
  });

  WallpaperDownloadService service(http.Client client) =>
      WallpaperDownloadService(
        gallerySaver: saver,
        clientFactory: () => client,
        temporaryDirectory: () async => temporary,
      );

  Future<void> download(WallpaperDownloadService service) =>
      service.download(photo, onProgress: (_) {}, onSaving: () {});

  test(
    'Streams the original, reports progress and saves before cleaning up',
    () async {
      final progress = <double?>[];
      var saving = false;
      final downloader = service(
        MockClient((request) async {
          expect(request.url.toString(), photo.originalUrl);
          expect(request.headers.containsKey('Authorization'), isFalse);
          return http.Response.bytes(
            imageBytes,
            200,
            headers: {'content-type': 'image/jpeg'},
          );
        }),
      );
      await downloader.download(
        photo,
        onProgress: progress.add,
        onSaving: () => saving = true,
      );
      expect(progress.last, 1);
      expect(saving, isTrue);
      expect(saver.saved.single, imageBytes);
    },
  );

  test(
    'Wi-Fi-only blocks the actual downloader before its HTTP request',
    () async {
      final downloader = WallpaperDownloadService(
        gallerySaver: saver,
        networkPolicy: DownloadNetworkPolicy(
          wifiOnly: () => true,
          checkConnectivity: () async => [ConnectivityResult.mobile],
          changes: const Stream.empty(),
        ),
        clientFactory: () {
          fail('Wi-Fi-only must not create an HTTP client on mobile data.');
        },
        temporaryDirectory: () async => temporary,
      );
      await expectLater(
        download(downloader),
        throwsA(isA<DownloadException>()),
      );
      expect(saver.saved, isEmpty);
    },
  );

  test(
    'Wi-Fi loss mid-download prevents saving and cleans partial data',
    () async {
      final changes = StreamController<List<ConnectivityResult>>(sync: true);
      Stream<List<int>> chunks() async* {
        yield imageBytes;
        changes.add([ConnectivityResult.mobile]);
        yield imageBytes;
      }

      final downloader = WallpaperDownloadService(
        gallerySaver: saver,
        networkPolicy: DownloadNetworkPolicy(
          wifiOnly: () => true,
          checkConnectivity: () async => [ConnectivityResult.wifi],
          changes: changes.stream,
        ),
        clientFactory: () => MockClient.streaming(
          (_, _) async => http.StreamedResponse(
            chunks(),
            200,
            headers: {'content-type': 'image/jpeg'},
          ),
        ),
        temporaryDirectory: () async => temporary,
      );
      await expectLater(
        download(downloader),
        throwsA(isA<DownloadException>()),
      );
      expect(saver.saved, isEmpty);
      expect(changes.hasListener, isFalse);
      await changes.close();
    },
  );

  test('Denied permission prevents network requests and saving', () async {
    saver.allowed = false;
    final downloader = service(
      MockClient((_) async {
        fail('No download should be made without gallery access.');
      }),
    );
    await expectLater(
      download(downloader),
      throwsA(
        isA<DownloadException>().having(
          (error) => error.message,
          'message',
          contains('denied'),
        ),
      ),
    );
    expect(saver.saved, isEmpty);
  });

  test('Non-success response never saves', () async {
    await expectLater(
      download(service(MockClient((_) async => http.Response('', 404)))),
      throwsA(isA<DownloadException>()),
    );
    expect(saver.saved, isEmpty);
  });

  test('Non-image response never saves', () async {
    await expectLater(
      download(
        service(
          MockClient(
            (_) async => http.Response(
              '<html>Error</html>',
              200,
              headers: {'content-type': 'text/html'},
            ),
          ),
        ),
      ),
      throwsA(isA<DownloadException>()),
    );
    expect(saver.saved, isEmpty);
  });

  test(
    'An empty image is rejected and its temporary file is removed',
    () async {
      await expectLater(
        download(
          service(
            MockClient(
              (_) async => http.Response.bytes(
                [],
                200,
                headers: {'content-type': 'image/jpeg'},
              ),
            ),
          ),
        ),
        throwsA(isA<DownloadException>()),
      );
      expect(saver.saved, isEmpty);
    },
  );

  test('Unknown content length uses indeterminate progress', () async {
    final progress = <double?>[];
    await service(
      MockClient.streaming(
        (_, _) async => http.StreamedResponse(
          Stream.value(imageBytes),
          200,
          headers: {'content-type': 'image/jpeg'},
        ),
      ),
    ).download(photo, onProgress: progress.add, onSaving: () {});
    expect(progress, [null]);
    expect(saver.saved.single, imageBytes);
  });

  test('An interrupted stream is not saved and is cleaned up', () async {
    Stream<List<int>> interrupted() async* {
      yield imageBytes;
      throw http.ClientException('Connection lost');
    }

    await expectLater(
      download(
        service(
          MockClient.streaming(
            (_, _) async => http.StreamedResponse(
              interrupted(),
              200,
              headers: {'content-type': 'image/jpeg'},
            ),
          ),
        ),
      ),
      throwsA(isA<DownloadException>()),
    );
    expect(saver.saved, isEmpty);
  });

  test('A truncated download is never saved', () async {
    await expectLater(
      download(
        service(
          MockClient.streaming(
            (_, _) async => http.StreamedResponse(
              Stream.value(imageBytes),
              200,
              contentLength: imageBytes.length + 20,
              headers: {'content-type': 'image/jpeg'},
            ),
          ),
        ),
      ),
      throwsA(isA<DownloadException>()),
    );
    expect(saver.saved, isEmpty);
  });

  for (final type in GalExceptionType.values) {
    test(
      'Gallery ${type.name} failure is reported and temp data is cleaned',
      () async {
        saver.failure = GalException(
          type: type,
          platformException: PlatformException(code: type.code),
          stackTrace: StackTrace.current,
        );
        await expectLater(
          download(
            service(
              MockClient(
                (_) async => http.Response.bytes(
                  imageBytes,
                  200,
                  headers: {'content-type': 'image/jpeg'},
                ),
              ),
            ),
          ),
          throwsA(isA<DownloadException>()),
        );
        expect(saver.saved, isEmpty);
      },
    );
  }
}
