import 'local_config.dart';

abstract final class AppConfig {
  /// Prefers a key passed via --dart-define=PEXELS_API_KEY=...; otherwise
  /// falls back to the gitignored LocalConfig key (debug and release).
  static const String _defined = String.fromEnvironment('PEXELS_API_KEY');
  static const String pexelsApiKey = _defined != ''
      ? _defined
      : LocalConfig.pexelsApiKey;
}
