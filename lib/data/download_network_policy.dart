import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'wallpaper_download_service.dart';

class DownloadNetworkPolicy {
  DownloadNetworkPolicy({
    required this.wifiOnly,
    required this.checkConnectivity,
    required this.changes,
  });

  final bool Function() wifiOnly;
  final Future<List<ConnectivityResult>> Function() checkConnectivity;
  final Stream<List<ConnectivityResult>> changes;

  Future<DownloadNetworkSession> monitor(void Function() abort) async {
    final session = DownloadNetworkSession(wifiOnly, abort);
    var ready = false;
    session.subscription = changes.listen(
      session.update,
      onError: (Object error, StackTrace stack) {
        session.failure = const DownloadException(
          'Could not determine the network connection. Please try again.',
        );
        abort();
      },
    );
    try {
      final connection = await checkConnectivity().timeout(
        const Duration(seconds: 10),
      );
      // A stream event may be newer than the initial connectivity query.
      session.connection ??= connection;
      session.validate();
      ready = true;
      return session;
    } finally {
      if (!ready) {
        await session.close();
      }
    }
  }
}

class DownloadNetworkSession {
  DownloadNetworkSession(this.wifiOnly, this.abort);

  final bool Function() wifiOnly;
  final void Function() abort;
  List<ConnectivityResult>? connection;
  DownloadException? failure;
  StreamSubscription<List<ConnectivityResult>>? subscription;

  void update(List<ConnectivityResult> value) {
    connection = value;
    if (wifiOnly() && !value.contains(ConnectivityResult.wifi)) {
      failure = const DownloadException(
        'Wi-Fi-only downloads are enabled. Connect to Wi-Fi or turn off '
        'this option in Settings, then retry.',
      );
      abort();
    }
  }

  void validate() {
    if (wifiOnly() &&
        !(connection?.contains(ConnectivityResult.wifi) ?? false)) {
      failure ??= const DownloadException(
        'Wi-Fi-only downloads are enabled. Connect to Wi-Fi or turn off '
        'this option in Settings, then retry.',
      );
    }
    if (failure case final error?) throw error;
  }

  Future<void> close() async => subscription?.cancel();
}
