import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/wallpaper.dart';
import 'download_network_policy.dart';

class DownloadException implements Exception {
  const DownloadException(this.message);
  final String message;
}

abstract class GallerySaver {
  Future<bool> requestAccess();
  Future<void> save(String path);
}

class DeviceGallerySaver implements GallerySaver {
  @override
  Future<bool> requestAccess() => Gal.requestAccess();

  @override
  Future<void> save(String path) => Gal.putImage(path);
}

class WallpaperDownloadService {
  WallpaperDownloadService({
    required this.gallerySaver,
    this.networkPolicy,
    http.Client Function()? clientFactory,
    Future<Directory> Function()? temporaryDirectory,
  }) : _clientFactory = clientFactory ?? http.Client.new,
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final GallerySaver gallerySaver;
  final DownloadNetworkPolicy? networkPolicy;
  final http.Client Function() _clientFactory;
  final Future<Directory> Function() _temporaryDirectory;

  Future<void> download(
    Wallpaper photo, {
    required void Function(double? progress) onProgress,
    required VoidCallback onSaving,
  }) async {
    http.Client? client;
    Directory? workingDirectory;
    DownloadNetworkSession? network;
    try {
      network = await networkPolicy?.monitor(() => client?.close());
      if (!await gallerySaver.requestAccess()) {
        throw const DownloadException(
          'Photo access was denied. Allow Walltastic to add photos in your '
          'device settings, then try again.',
        );
      }
      client = _clientFactory();
      network?.validate();
      final response = await client
          .send(http.Request('GET', Uri.parse(photo.originalUrl)))
          .timeout(const Duration(seconds: 30));
      network?.validate();
      if (response.statusCode != 200) {
        throw const DownloadException(
          'The original image could not be downloaded. Please try again.',
        );
      }
      final mime = response.headers['content-type']
          ?.split(';')
          .first
          .trim()
          .toLowerCase();
      final extension = switch (mime) {
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        'image/heic' => 'heic',
        'image/heif' => 'heif',
        _ => throw const DownloadException(
          'The server did not return a supported image.',
        ),
      };
      final temporary = await _temporaryDirectory();
      workingDirectory = await temporary.createTemp('walltastic-');
      final file = File(
        '${workingDirectory.path}/walltastic-${photo.id}.$extension',
      );
      final output = await file.open(mode: FileMode.write);
      var received = 0;
      final total = response.contentLength;
      try {
        // Write each chunk to disk rather than buffering a full original in RAM.
        await for (final chunk in response.stream.timeout(
          const Duration(seconds: 30),
        )) {
          network?.validate();
          await output.writeFrom(chunk);
          received += chunk.length;
          onProgress(
            total != null && total > 0
                ? (received / total).clamp(0.0, 1.0)
                : null,
          );
        }
      } finally {
        await output.close();
      }
      network?.validate();
      if (received == 0 || (total != null && received != total)) {
        throw const DownloadException(
          'The download was incomplete. Please try again.',
        );
      }
      onSaving();
      await gallerySaver.save(file.path);
    } on TimeoutException {
      throw const DownloadException(
        'The download timed out. Check your connection and try again.',
      );
    } on http.ClientException {
      network?.validate();
      throw const DownloadException(
        'Could not download the image. Check your internet connection.',
      );
    } on SocketException {
      network?.validate();
      throw const DownloadException(
        'The connection was interrupted. Please try again.',
      );
    } on FileSystemException {
      throw const DownloadException(
        'Could not store the download. Check your available device storage.',
      );
    } on GalException catch (error) {
      throw DownloadException(switch (error.type) {
        GalExceptionType.accessDenied =>
          'Photo access was denied. Allow Walltastic to add photos in '
              'your device settings, then try again.',
        GalExceptionType.notEnoughSpace =>
          'Your device does not have enough space to save this wallpaper.',
        GalExceptionType.notSupportedFormat =>
          'Your photo library does not support this image format.',
        GalExceptionType.unexpected =>
          'The photo library could not save this wallpaper. Please try again.',
      });
    } on PlatformException {
      throw const DownloadException(
        'Device storage or the photo library is unavailable. Please try again.',
      );
    } finally {
      await network?.close();
      client?.close();
      if (workingDirectory != null) {
        try {
          await workingDirectory.delete(recursive: true);
        } on FileSystemException catch (error) {
          debugPrint('Could not remove temporary wallpaper download: $error');
        }
      }
    }
  }
}
