import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walltastic/data/download_network_policy.dart';
import 'package:walltastic/data/wallpaper_download_service.dart';

void main() {
  for (final connection in [
    ConnectivityResult.mobile,
    ConnectivityResult.none,
    ConnectivityResult.ethernet,
    ConnectivityResult.vpn,
  ]) {
    test(
      'Wi-Fi-only blocks $connection and releases its subscription',
      () async {
        final changes = StreamController<List<ConnectivityResult>>();
        final policy = DownloadNetworkPolicy(
          wifiOnly: () => true,
          checkConnectivity: () async => [connection],
          changes: changes.stream,
        );
        await expectLater(
          policy.monitor(() {}),
          throwsA(isA<DownloadException>()),
        );
        expect(changes.hasListener, isFalse);
        await changes.close();
      },
    );
  }

  test(
    'Wi-Fi permits downloading, disconnection aborts and remains retryable',
    () async {
      final changes = StreamController<List<ConnectivityResult>>.broadcast(
        sync: true,
      );
      var aborted = false;
      final policy = DownloadNetworkPolicy(
        wifiOnly: () => true,
        checkConnectivity: () async => [ConnectivityResult.wifi],
        changes: changes.stream,
      );
      final session = await policy.monitor(() => aborted = true);
      session.validate();
      changes.add([ConnectivityResult.mobile]);
      expect(aborted, isTrue);
      expect(session.validate, throwsA(isA<DownloadException>()));
      await session.close();
      final retry = await policy.monitor(() {});
      retry.validate();
      await retry.close();
      expect(changes.hasListener, isFalse);
      await changes.close();
    },
  );

  test('Downloads on mobile are permitted while Wi-Fi-only is off', () async {
    final changes = StreamController<List<ConnectivityResult>>(sync: true);
    var enabled = false;
    var aborted = false;
    final session = await DownloadNetworkPolicy(
      wifiOnly: () => enabled,
      checkConnectivity: () async => [ConnectivityResult.mobile],
      changes: changes.stream,
    ).monitor(() => aborted = true);
    session.validate();
    changes.add([ConnectivityResult.mobile]);
    expect(aborted, isFalse);
    enabled = true;
    expect(session.validate, throwsA(isA<DownloadException>()));
    await session.close();
    await changes.close();
  });

  test('Connection query failure cancels monitoring', () async {
    final changes = StreamController<List<ConnectivityResult>>();
    final policy = DownloadNetworkPolicy(
      wifiOnly: () => true,
      checkConnectivity: () async => throw PlatformException(code: 'network'),
      changes: changes.stream,
    );
    await expectLater(policy.monitor(() {}), throwsA(isA<PlatformException>()));
    expect(changes.hasListener, isFalse);
    await changes.close();
  });

  test(
    'Network monitoring failure aborts rather than allowing mobile data',
    () async {
      final changes = StreamController<List<ConnectivityResult>>(sync: true);
      var aborted = false;
      final session = await DownloadNetworkPolicy(
        wifiOnly: () => true,
        checkConnectivity: () async => [ConnectivityResult.wifi],
        changes: changes.stream,
      ).monitor(() => aborted = true);
      changes.addError(PlatformException(code: 'network'));
      expect(aborted, isTrue);
      expect(session.validate, throwsA(isA<DownloadException>()));
      await session.close();
      await changes.close();
    },
  );
}
