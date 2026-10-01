import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walltastic/config/app_config.dart';
import 'package:walltastic/config/local_config.dart';

void main() {
  test('Global key uses a build-time override or the local debug key', () {
    const hasOverride = bool.hasEnvironment('PEXELS_API_KEY');
    const override = String.fromEnvironment('PEXELS_API_KEY');
    const expected = hasOverride
        ? override
        : kDebugMode
        ? LocalConfig.pexelsApiKey
        : '';

    // Compare without including credentials in failure output.
    expect(AppConfig.pexelsApiKey == expected, isTrue);
  });
}
